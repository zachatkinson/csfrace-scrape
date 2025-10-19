# Simple one-command installation script for Windows
# Usage: .\scripts\install.ps1
# Non-interactive mode: $env:SKIP_PROMPTS="1"; .\scripts\install.ps1

$ErrorActionPreference = "Stop"

Write-Host " CSFrace Scrape - Installation" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Check PowerShell version - require 7+
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "Error: PowerShell 7 or higher is required" -ForegroundColor Red
    Write-Host ""
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "Required version: 7.0 or higher" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please install PowerShell 7:" -ForegroundColor Cyan
    Write-Host "  https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5" -ForegroundColor White
    Write-Host ""
    Write-Host "Quick install options:" -ForegroundColor Cyan
    Write-Host "  - Winget: winget install Microsoft.PowerShell" -ForegroundColor Gray
    Write-Host "  - MSI Installer: Download from the link above" -ForegroundColor Gray
    Write-Host ""
    Write-Host "After installing, run this script again from PowerShell 7" -ForegroundColor Cyan
    exit 1
}

Write-Host "OK: PowerShell $($PSVersionTable.PSVersion) detected" -ForegroundColor Green
Write-Host ""

# Check for existing data volumes
$existingVolumes = (docker volume ls --filter "name=csfrace-scrape" --format "{{.Name}}" | Measure-Object -Line).Lines

if ($existingVolumes -gt 0) {
    if ($env:SKIP_PROMPTS -eq "1") {
        Write-Host "Info:  Existing data found - preserving (non-interactive mode)" -ForegroundColor Cyan
        Write-Host ""
    } else {
        Write-Host "Info:  Existing data found from previous installation" -ForegroundColor Cyan
        Write-Host ""
        $startFresh = Read-Host "Start FRESH (delete existing data)? [y/N]"
        Write-Host ""

        if ($startFresh -match "^[Yy]$") {
            Write-Host "  Removing existing data volumes..." -ForegroundColor Yellow
            try {
                docker compose down -v 2>$null
            } catch {
                # Ignore errors if services aren't running
            }
            Write-Host "OK: Starting with fresh database" -ForegroundColor Green
        } else {
            Write-Host "OK: Preserving existing data" -ForegroundColor Green
        }
        Write-Host ""
    }
}

# Check if .env exists
if (!(Test-Path .env)) {
    Write-Host " Creating .env file from template..." -ForegroundColor Yellow
    Copy-Item .env.example .env
    Write-Host "OK: .env created" -ForegroundColor Green
} else {
    Write-Host "OK: .env already exists" -ForegroundColor Green
}

Write-Host ""

# Create SSL certificates for nginx (required before starting containers)
Write-Host " Setting up HTTPS certificates..." -ForegroundColor Yellow
$sslDir = "nginx\ssl"
if (!(Test-Path $sslDir)) {
    New-Item -ItemType Directory -Path $sslDir -Force | Out-Null
}

# Check if certificates already exist and are valid
$certsExist = (Test-Path "$sslDir\localhost.crt") -and (Test-Path "$sslDir\localhost.key")
$certsValid = $false

if ($certsExist) {
    try {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("$sslDir\localhost.crt")
        $daysUntilExpiry = ($cert.NotAfter - (Get-Date)).Days
        if ($daysUntilExpiry -gt 30) {
            $certsValid = $true
            Write-Host "OK: Valid SSL certificates found (expires in $daysUntilExpiry days)" -ForegroundColor Green
        } else {
            Write-Host "Warning:  SSL certificates expire soon ($daysUntilExpiry days) - regenerating..." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Warning:  Existing certificates are invalid - regenerating..." -ForegroundColor Yellow
    }
}

if (!$certsValid) {
    Write-Host " Generating SSL certificates using PowerShell..." -ForegroundColor Cyan

    try {
        # Generate self-signed certificate using PowerShell 7+ (.NET Core)
        $cert = New-SelfSignedCertificate `
            -Subject "CN=localhost" `
            -DnsName @("localhost", "*.localhost") `
            -CertStoreLocation "Cert:\CurrentUser\My" `
            -KeyExportPolicy Exportable `
            -KeySpec Signature `
            -KeyLength 2048 `
            -KeyAlgorithm RSA `
            -HashAlgorithm SHA256 `
            -NotAfter (Get-Date).AddDays(365)

        # Export certificate to PEM format
        $certPath = "$sslDir\localhost.crt"
        $certPem = "-----BEGIN CERTIFICATE-----`n"
        $certPem += [Convert]::ToBase64String($cert.RawData, "InsertLineBreaks")
        $certPem += "`n-----END CERTIFICATE-----"
        $certPem | Out-File -FilePath $certPath -Encoding ASCII

        # Export private key to PEM format using PowerShell 7 method
        $keyPath = "$sslDir\localhost.key"
        $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
        $keyBytes = $rsa.ExportRSAPrivateKey()
        $keyPem = "-----BEGIN RSA PRIVATE KEY-----`n"
        $keyPem += [Convert]::ToBase64String($keyBytes, "InsertLineBreaks")
        $keyPem += "`n-----END RSA PRIVATE KEY-----"
        $keyPem | Out-File -FilePath $keyPath -Encoding ASCII

        # Clean up certificate from personal store
        Remove-Item "Cert:\CurrentUser\My\$($cert.Thumbprint)" -Force -ErrorAction SilentlyContinue

        Write-Host "OK: SSL certificates generated" -ForegroundColor Green

        # Try to add to Windows certificate store for trusted HTTPS
        try {
            $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
            $store.Open("ReadWrite")

            $existingCerts = $store.Certificates | Where-Object { $_.Subject -eq $cert.Subject -and $_.Thumbprint -eq $cert.Thumbprint }

            if (!$existingCerts) {
                $store.Add($cert)
                Write-Host "OK: Certificate added to Windows Trusted Root store" -ForegroundColor Green
            }

            $store.Close()
        } catch {
            Write-Host "Info: Certificate not added to Windows store (requires admin privileges)" -ForegroundColor Cyan
            Write-Host "   You can add it manually later for trusted HTTPS access" -ForegroundColor Gray
        }

    } catch {
        Write-Host "Error: Failed to generate certificates: $_" -ForegroundColor Red
        Write-Host "Continuing without HTTPS - nginx may not start properly..." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host " Building Docker images..." -ForegroundColor Yellow
Write-Host "   (First time: 5-10 minutes, subsequent starts are instant)" -ForegroundColor Gray
Write-Host ""

# Build with progress output
docker compose build

Write-Host ""
Write-Host " Starting services..." -ForegroundColor Yellow
docker compose up -d

Write-Host ""
Write-Host " Waiting for services to be healthy..." -ForegroundColor Yellow

# Wait for backend health
$maxAttempts = 30
for ($i = 1; $i -le $maxAttempts; $i++) {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8000/health/" -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.status -eq "healthy") {
            Write-Host "OK: Backend is healthy" -ForegroundColor Green
            break
        }
    } catch {
        # Continue waiting
    }

    if ($i -eq $maxAttempts) {
        Write-Host "Error: Backend did not become healthy" -ForegroundColor Red
        Write-Host "Check logs with: docker compose logs backend" -ForegroundColor Yellow
        exit 1
    }
    Start-Sleep -Seconds 2
}

# Wait for frontend health
for ($i = 1; $i -le $maxAttempts; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "OK: Frontend is healthy" -ForegroundColor Green
            break
        }
    } catch {
        # Continue waiting
    }

    if ($i -eq $maxAttempts) {
        Write-Host "Error: Frontend did not become healthy" -ForegroundColor Red
        Write-Host "Check logs with: docker compose logs frontend" -ForegroundColor Yellow
        exit 1
    }
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "OK: Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host " Service URLs:" -ForegroundColor Cyan
Write-Host "   Frontend:    https://localhost (recommended)"
Write-Host "   Backend API: https://localhost/api"
Write-Host "   API Docs:    https://localhost/docs"
Write-Host "   Grafana:     http://localhost:3001 (admin/admin)"
Write-Host "   Prometheus:  http://localhost:9090"
Write-Host ""

if ($certsValid -eq $true) {
    Write-Host " HTTPS is configured and ready to use!" -ForegroundColor Green
} else {
    Write-Host " HTTPS certificates generated" -ForegroundColor Green
    Write-Host "   Note: Your browser may show a security warning for self-signed certificates" -ForegroundColor Gray
}

Write-Host ""
Write-Host " Ready to use!" -ForegroundColor Green
