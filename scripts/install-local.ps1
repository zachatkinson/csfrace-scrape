# Simple one-command LOCAL installation for Windows
# For single-user deployments WITHOUT OAuth setup
# Usage: .\scripts\install-local.ps1

$ErrorActionPreference = "Stop"

# Helper function for single-keypress Y/N prompts
function Read-YesNo {
    param([string]$Prompt)

    Write-Host $Prompt -NoNewline -ForegroundColor Yellow
    Write-Host " [Y/N]: " -NoNewline -ForegroundColor White

    while ($true) {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        $char = $key.Character.ToString().ToUpper()

        if ($char -eq "Y" -or $char -eq "N") {
            Write-Host $char -ForegroundColor Cyan
            return $char -eq "Y"
        }
        # Ignore invalid keys, wait for Y or N
    }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  CSFrace Scrape - Local Single-User Installation (Windows)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This installer sets up CSFrace for LOCAL use without OAuth." -ForegroundColor White
Write-Host "Perfect for personal scraping on your Windows machine!" -ForegroundColor White
Write-Host ""

# Check PowerShell version - require 7+
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "❌ Error: PowerShell 7 or higher is required" -ForegroundColor Red
    Write-Host ""
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "Required version: 7.0 or higher" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please install PowerShell 7:" -ForegroundColor Cyan
    Write-Host "  https://aka.ms/powershell-release?tag=stable" -ForegroundColor White
    Write-Host ""
    Write-Host "Quick install:" -ForegroundColor Cyan
    Write-Host "  winget install Microsoft.PowerShell" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host "✅ PowerShell $($PSVersionTable.PSVersion) detected" -ForegroundColor Green
Write-Host ""

# Check if running as Administrator
Write-Host "⏳ Checking privileges..." -ForegroundColor Yellow
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ Error: Administrator privileges required" -ForegroundColor Red
    Write-Host ""
    Write-Host "This installer needs Administrator privileges to:" -ForegroundColor Yellow
    Write-Host "  - Add SSL certificates to Windows Trusted Root store" -ForegroundColor Gray
    Write-Host "  - Ensure proper HTTPS configuration" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Please run PowerShell as Administrator:" -ForegroundColor Cyan
    Write-Host "  1. Right-click PowerShell icon" -ForegroundColor White
    Write-Host "  2. Select 'Run as Administrator'" -ForegroundColor White
    Write-Host "  3. Navigate to this directory and run the script again" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green
Write-Host ""

# Check Docker is running
Write-Host "⏳ Checking Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker not found"
    }
    Write-Host "✅ Docker detected: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: Docker is not running" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Docker Desktop:" -ForegroundColor Cyan
    Write-Host "  https://www.docker.com/products/docker-desktop" -ForegroundColor White
    Write-Host ""
    Write-Host "Or start Docker Desktop if already installed." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
Write-Host ""

# Check for existing data volumes
Write-Host "⏳ Checking for existing data..." -ForegroundColor Yellow
$existingVolumes = docker volume ls --filter "name=csfrace" --format "{{.Name}}" 2>$null
if ($existingVolumes) {
    Write-Host "⚠️  Existing data found from previous installation" -ForegroundColor Cyan
    Write-Host ""
    $startFresh = Read-YesNo "Delete existing data and start fresh?"
    Write-Host ""

    if ($startFresh) {
        Write-Host "⏳ Removing existing data volumes..." -ForegroundColor Yellow
        docker compose -f docker-compose.dev.yml down -v 2>$null
        Write-Host "✅ Starting with fresh database" -ForegroundColor Green
    } else {
        Write-Host "✅ Preserving existing data" -ForegroundColor Green
    }
} else {
    Write-Host "✅ No existing data found - fresh installation" -ForegroundColor Green
}
Write-Host ""

# Create environment files
Write-Host "⏳ Setting up environment configuration..." -ForegroundColor Yellow

# Backend .env
if (Test-Path .env) {
    Write-Host "⚠️  .env already exists - keeping current file" -ForegroundColor Yellow
} else {
    if (Test-Path .env.windows.example) {
        Copy-Item .env.windows.example .env
        Write-Host "✅ Created .env from .env.windows.example" -ForegroundColor Green
    } else {
        Write-Host "❌ Error: .env.windows.example not found!" -ForegroundColor Red
        Write-Host "Please ensure you're in the project root directory." -ForegroundColor Yellow
        exit 1
    }
}

# Frontend .env
if (Test-Path frontend\.env) {
    Write-Host "⚠️  frontend\.env already exists - keeping current file" -ForegroundColor Yellow
} else {
    if (Test-Path frontend\.env.local.example) {
        Copy-Item frontend\.env.local.example frontend\.env
        Write-Host "✅ Created frontend\.env from frontend\.env.local.example" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Warning: frontend\.env.local.example not found" -ForegroundColor Yellow
        Write-Host "   Frontend will use default configuration" -ForegroundColor Gray
    }
}
Write-Host ""

# Create SSL certificates for nginx (required before starting containers)
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Setting up HTTPS certificates" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "⏳ Checking for SSL certificates..." -ForegroundColor Yellow
$sslDir = "nginx\ssl"
if (-not (Test-Path $sslDir)) {
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
            Write-Host "✅ Valid SSL certificates found (expires in $daysUntilExpiry days)" -ForegroundColor Green
        } else {
            Write-Host "⚠️  SSL certificates expire soon ($daysUntilExpiry days) - regenerating..." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Existing certificates are invalid - regenerating..." -ForegroundColor Yellow
    }
}

if (-not $certsValid) {
    Write-Host "⏳ Generating SSL certificates using PowerShell..." -ForegroundColor Yellow

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

        Write-Host "✅ SSL certificates generated" -ForegroundColor Green

        # Try to add to Windows certificate store for trusted HTTPS
        try {
            $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
            $store.Open("ReadWrite")

            $existingCerts = $store.Certificates | Where-Object { $_.Subject -eq $cert.Subject -and $_.Thumbprint -eq $cert.Thumbprint }

            if (-not $existingCerts) {
                $store.Add($cert)
                Write-Host "✅ Certificate added to Windows Trusted Root store" -ForegroundColor Green
                Write-Host "   Your browser will trust https://localhost" -ForegroundColor Gray
            } else {
                Write-Host "✅ Certificate already in Windows Trusted Root store" -ForegroundColor Green
            }

            $store.Close()
        } catch {
            Write-Host "⚠️  Certificate not added to Windows store (requires admin privileges)" -ForegroundColor Yellow
            Write-Host "   You can add it manually later for trusted HTTPS access" -ForegroundColor Gray
        }

    } catch {
        Write-Host "❌ Error: Failed to generate certificates: $_" -ForegroundColor Red
        Write-Host "⚠️  Continuing without HTTPS - nginx may not start properly..." -ForegroundColor Yellow
    }
}

Write-Host ""

# Build and start services
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Building Docker containers (this may take 5-10 minutes)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "⏳ Building backend..." -ForegroundColor Yellow
docker compose -f docker-compose.dev.yml build backend-dev
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Backend build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Backend built successfully" -ForegroundColor Green
Write-Host ""

Write-Host "⏳ Building frontend..." -ForegroundColor Yellow
docker compose -f docker-compose.dev.yml build frontend-dev
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Frontend build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Frontend built successfully" -ForegroundColor Green
Write-Host ""

Write-Host "⏳ Starting all services..." -ForegroundColor Yellow
docker compose -f docker-compose.dev.yml up -d
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Service startup failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check logs with:" -ForegroundColor Yellow
    Write-Host "  docker compose -f docker-compose.dev.yml logs" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
Write-Host "✅ All services started" -ForegroundColor Green
Write-Host ""

# Wait for services to be healthy
Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Yellow
$maxWait = 60
$waited = 0
$allHealthy = $false

while ($waited -lt $maxWait -and -not $allHealthy) {
    Start-Sleep -Seconds 2
    $waited += 2

    # Check if backend is healthy
    $backendStatus = docker compose -f docker-compose.dev.yml ps backend-dev --format json 2>$null | ConvertFrom-Json
    if ($backendStatus.Health -eq "healthy") {
        $allHealthy = $true
    }

    if ($waited % 10 -eq 0) {
        Write-Host "  Still waiting... ($waited seconds)" -ForegroundColor Gray
    }
}

if ($allHealthy) {
    Write-Host "✅ Services are healthy and ready!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Services started but may still be initializing" -ForegroundColor Yellow
    Write-Host "   If you have issues, wait a minute and refresh" -ForegroundColor Gray
}
Write-Host ""

# Show access URLs
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  🎉 Installation Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access your application at:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  🌐 Main App:    https://localhost" -ForegroundColor White
Write-Host "  📚 API Docs:    https://localhost/docs" -ForegroundColor White
Write-Host "  📊 Monitoring:  http://localhost:3001 (admin/admin)" -ForegroundColor White
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✨ NO LOGIN REQUIRED! ✨" -ForegroundColor Yellow
Write-Host ""
Write-Host "This is a single-user local installation." -ForegroundColor Gray
Write-Host "All scraping jobs will be saved to your local database." -ForegroundColor Gray
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 Useful Commands:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  View logs:" -ForegroundColor White
Write-Host "    docker compose -f docker-compose.dev.yml logs -f" -ForegroundColor Gray
Write-Host ""
Write-Host "  Stop services:" -ForegroundColor White
Write-Host "    docker compose -f docker-compose.dev.yml down" -ForegroundColor Gray
Write-Host ""
Write-Host "  Restart services:" -ForegroundColor White
Write-Host "    docker compose -f docker-compose.dev.yml restart" -ForegroundColor Gray
Write-Host ""
Write-Host "  Check status:" -ForegroundColor White
Write-Host "    docker compose -f docker-compose.dev.yml ps" -ForegroundColor Gray
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🚀 Ready to start scraping!" -ForegroundColor Green
Write-Host ""
Write-Host "Opening your browser in 5 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Try to open browser
try {
    Start-Process "https://localhost"
} catch {
    Write-Host "Could not auto-open browser. Please visit https://localhost manually." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Installation complete! Happy scraping! 🎉" -ForegroundColor Green
Write-Host ""
