# Simple one-command installation script for Windows
# Usage: .\scripts\install.ps1
# Non-interactive mode: $env:SKIP_PROMPTS="1"; .\scripts\install.ps1

$ErrorActionPreference = "Stop"

Write-Host "🚀 CSFrace Scrape - Installation" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Check for existing data volumes
$existingVolumes = (docker volume ls --filter "name=csfrace-scrape" --format "{{.Name}}" | Measure-Object -Line).Lines

if ($existingVolumes -gt 0) {
    if ($env:SKIP_PROMPTS -eq "1") {
        Write-Host "ℹ️  Existing data found - preserving (non-interactive mode)" -ForegroundColor Cyan
        Write-Host ""
    } else {
        Write-Host "ℹ️  Existing data found from previous installation" -ForegroundColor Cyan
        Write-Host ""
        $startFresh = Read-Host "Start FRESH (delete existing data)? [y/N]"
        Write-Host ""

        if ($startFresh -match "^[Yy]$") {
            Write-Host "🗑️  Removing existing data volumes..." -ForegroundColor Yellow
            try {
                docker compose down -v 2>$null
            } catch {
                # Ignore errors if services aren't running
            }
            Write-Host "✓ Starting with fresh database" -ForegroundColor Green
        } else {
            Write-Host "✓ Preserving existing data" -ForegroundColor Green
        }
        Write-Host ""
    }
}

# Check if .env exists
if (!(Test-Path .env)) {
    Write-Host "📝 Creating .env file from template..." -ForegroundColor Yellow
    Copy-Item .env.example .env
    Write-Host "✅ .env created" -ForegroundColor Green
} else {
    Write-Host "✅ .env already exists" -ForegroundColor Green
}

Write-Host ""

# Create SSL certificates for nginx (required before starting containers)
Write-Host "🔒 Setting up HTTPS certificates..." -ForegroundColor Yellow
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
            Write-Host "✅ Valid SSL certificates found (expires in $daysUntilExpiry days)" -ForegroundColor Green
        } else {
            Write-Host "⚠️  SSL certificates expire soon ($daysUntilExpiry days) - regenerating..." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Existing certificates are invalid - regenerating..." -ForegroundColor Yellow
    }
}

if (!$certsValid) {
    # Check if OpenSSL is available
    $opensslPath = Get-Command openssl -ErrorAction SilentlyContinue

    if (!$opensslPath) {
        Write-Host "❌ OpenSSL not found - required for HTTPS certificates" -ForegroundColor Red
        Write-Host ""
        Write-Host "Options to install OpenSSL on Windows:" -ForegroundColor Yellow
        Write-Host "1. Using Chocolatey: choco install openssl" -ForegroundColor White
        Write-Host "2. Using Winget: winget install --id=ShiningLight.OpenSSL" -ForegroundColor White
        Write-Host "3. Download from: https://slproweb.com/products/Win32OpenSSL.html" -ForegroundColor White
        Write-Host ""
        Write-Host "After installing OpenSSL, restart PowerShell and run this script again." -ForegroundColor Cyan
        exit 1
    }

    Write-Host "📝 Generating SSL certificates..." -ForegroundColor Cyan

    # Generate private key
    & openssl genrsa -out "$sslDir\localhost.key" 2048 2>$null

    # Create certificate config file
    $configPath = "$sslDir\localhost.cnf"

    # Write config file line by line to avoid here-string issues
    "[req]" | Out-File -FilePath $configPath -Encoding ASCII
    "default_bits = 2048" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "prompt = no" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "default_md = sha256" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "distinguished_name = dn" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "req_extensions = v3_req" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "[dn]" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "C=US" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "ST=CA" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "L=SF" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "O=Dev" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "CN=localhost" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "[v3_req]" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "subjectAltName = @alt_names" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "[alt_names]" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "DNS.1 = localhost" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "DNS.2 = *.localhost" | Out-File -FilePath $configPath -Append -Encoding ASCII
    "IP.1 = 127.0.0.1" | Out-File -FilePath $configPath -Append -Encoding ASCII

    # Create certificate signing request
    & openssl req -new -key "$sslDir\localhost.key" `
        -out "$sslDir\localhost.csr" `
        -config $configPath 2>$null

    # Generate self-signed certificate
    & openssl x509 -req `
        -in "$sslDir\localhost.csr" `
        -signkey "$sslDir\localhost.key" `
        -out "$sslDir\localhost.crt" `
        -days 365 `
        -extensions v3_req `
        -extfile $configPath 2>$null

    # Clean up temporary files
    Remove-Item $configPath -Force -ErrorAction SilentlyContinue
    Remove-Item "$sslDir\localhost.csr" -Force -ErrorAction SilentlyContinue

    Write-Host "✅ SSL certificates generated" -ForegroundColor Green

    # Try to add to Windows certificate store
    try {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("$sslDir\localhost.crt")
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
        $store.Open("ReadWrite")

        $existingCerts = $store.Certificates | Where-Object { $_.Subject -eq $cert.Subject -and $_.Thumbprint -eq $cert.Thumbprint }

        if (!$existingCerts) {
            $store.Add($cert)
            Write-Host "✅ Certificate added to Windows Trusted Root store" -ForegroundColor Green
        }

        $store.Close()
    } catch {
        Write-Host "ℹ️  Note: Certificate not added to Windows store (requires admin privileges)" -ForegroundColor Cyan
        Write-Host "   You can add it manually later for trusted HTTPS access" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "🔨 Building Docker images..." -ForegroundColor Yellow
Write-Host "   (First time: 5-10 minutes, subsequent starts are instant)" -ForegroundColor Gray
Write-Host ""

# Build with progress output
docker compose build

Write-Host ""
Write-Host "🚢 Starting services..." -ForegroundColor Yellow
docker compose up -d

Write-Host ""
Write-Host "⏳ Waiting for services to be healthy..." -ForegroundColor Yellow

# Wait for backend health
$maxAttempts = 30
for ($i = 1; $i -le $maxAttempts; $i++) {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8000/health/" -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.status -eq "healthy") {
            Write-Host "✅ Backend is healthy" -ForegroundColor Green
            break
        }
    } catch {
        # Continue waiting
    }

    if ($i -eq $maxAttempts) {
        Write-Host "❌ Backend did not become healthy" -ForegroundColor Red
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
            Write-Host "✅ Frontend is healthy" -ForegroundColor Green
            break
        }
    } catch {
        # Continue waiting
    }

    if ($i -eq $maxAttempts) {
        Write-Host "❌ Frontend did not become healthy" -ForegroundColor Red
        Write-Host "Check logs with: docker compose logs frontend" -ForegroundColor Yellow
        exit 1
    }
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "✅ Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📍 Service URLs:" -ForegroundColor Cyan
Write-Host "   Frontend:    https://localhost (recommended)"
Write-Host "   Backend API: https://localhost/api"
Write-Host "   API Docs:    https://localhost/docs"
Write-Host "   Grafana:     http://localhost:3001 (admin/admin)"
Write-Host "   Prometheus:  http://localhost:9090"
Write-Host ""

if ($certsValid -eq $true) {
    Write-Host "🔒 HTTPS is configured and ready to use!" -ForegroundColor Green
} else {
    Write-Host "🔒 HTTPS certificates generated" -ForegroundColor Green
    Write-Host "   Note: Your browser may show a security warning for self-signed certificates" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🎉 Ready to use!" -ForegroundColor Green
