# Create HTTPS certificates for local development on Windows
# Required for Google OAuth and secure local development

Write-Host "🔒 Creating HTTPS certificates for local development..." -ForegroundColor Cyan

# Create nginx ssl directory
$sslDir = "nginx\ssl"
if (-not (Test-Path $sslDir)) {
    New-Item -ItemType Directory -Path $sslDir -Force | Out-Null
}

# Check if certificates already exist
if ((Test-Path "$sslDir\localhost.crt") -and (Test-Path "$sslDir\localhost.key")) {
    Write-Host ""
    Write-Host "ℹ️  SSL certificates already exist in nginx\ssl\" -ForegroundColor Yellow

    # Check certificate expiration
    try {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("$sslDir\localhost.crt")
        $daysUntilExpiry = ($cert.NotAfter - (Get-Date)).Days

        if ($daysUntilExpiry -lt 30) {
            Write-Host "⚠️  Certificate expires in $daysUntilExpiry days - regeneration recommended" -ForegroundColor Yellow
            Write-Host ""
            $regenerate = Read-Host "Do you want to regenerate the certificate? (yes/no)"
        } else {
            Write-Host "✅ Certificate is valid for $daysUntilExpiry more days" -ForegroundColor Green
            Write-Host ""
            $regenerate = Read-Host "Do you want to regenerate anyway? (yes/no)"
        }
    } catch {
        Write-Host "⚠️  Could not read certificate expiration" -ForegroundColor Yellow
        Write-Host ""
        $regenerate = Read-Host "Do you want to regenerate the certificate? (yes/no)"
    }

    Write-Host ""

    if ($regenerate -ne "yes") {
        Write-Host "✅ Using existing certificates" -ForegroundColor Green
        Write-Host ""
        Write-Host "To use the existing certificates:"
        Write-Host "1. Restart nginx container: docker compose restart nginx"
        Write-Host "2. Access https://localhost in your browser"
        exit 0
    }

    Write-Host "🗑️  Removing old certificates..." -ForegroundColor Yellow
    Remove-Item "$sslDir\localhost.crt" -Force -ErrorAction SilentlyContinue
    Remove-Item "$sslDir\localhost.key" -Force -ErrorAction SilentlyContinue
    Remove-Item "$sslDir\localhost.csr" -Force -ErrorAction SilentlyContinue
}

# Check if OpenSSL is available
$opensslPath = Get-Command openssl -ErrorAction SilentlyContinue

if (-not $opensslPath) {
    Write-Host "❌ OpenSSL not found. Installing OpenSSL..." -ForegroundColor Red
    Write-Host ""
    Write-Host "Options to install OpenSSL on Windows:" -ForegroundColor Yellow
    Write-Host "1. Using Chocolatey (recommended):" -ForegroundColor Yellow
    Write-Host "   choco install openssl" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Using Winget:" -ForegroundColor Yellow
    Write-Host "   winget install --id=ShiningLight.OpenSSL" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Download from: https://slproweb.com/products/Win32OpenSSL.html" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "After installing, restart PowerShell and run this script again." -ForegroundColor Cyan
    exit 1
}

Write-Host "✅ OpenSSL found at: $($opensslPath.Source)" -ForegroundColor Green
Write-Host ""

# Generate private key
Write-Host "📝 Generating private key..." -ForegroundColor Cyan
& openssl genrsa -out "$sslDir\localhost.key" 2048

# Create certificate signing request config file
$configContent = @"
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=US
ST=CA
L=SF
O=Dev
CN=localhost

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
IP.1 = 127.0.0.1
"@

$configPath = "$sslDir\localhost.cnf"
$configContent | Out-File -FilePath $configPath -Encoding ASCII

# Create certificate signing request
Write-Host "📝 Creating certificate signing request..." -ForegroundColor Cyan
& openssl req -new -key "$sslDir\localhost.key" `
    -out "$sslDir\localhost.csr" `
    -config $configPath

# Generate self-signed certificate with SAN
Write-Host "📝 Generating self-signed certificate..." -ForegroundColor Cyan
& openssl x509 -req `
    -in "$sslDir\localhost.csr" `
    -signkey "$sslDir\localhost.key" `
    -out "$sslDir\localhost.crt" `
    -days 365 `
    -extensions v3_req `
    -extfile $configPath

# Clean up config file
Remove-Item $configPath -Force

Write-Host ""
Write-Host "✅ HTTPS certificates created in nginx\ssl\ directory" -ForegroundColor Green

# Add to Windows certificate store
Write-Host ""
Write-Host "🔐 Adding certificate to Windows Trusted Root Certification Authorities..." -ForegroundColor Cyan

try {
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("$sslDir\localhost.crt")
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
    $store.Open("ReadWrite")

    # Check if certificate already exists
    $existingCerts = $store.Certificates | Where-Object { $_.Subject -eq $cert.Subject -and $_.Thumbprint -eq $cert.Thumbprint }

    if ($existingCerts) {
        Write-Host "ℹ️  Certificate already exists in Windows certificate store" -ForegroundColor Yellow
    } else {
        $store.Add($cert)
        Write-Host "✅ Certificate added to Windows Trusted Root Certification Authorities" -ForegroundColor Green
        Write-Host "   This allows your browser to trust https://localhost" -ForegroundColor Gray
    }

    $store.Close()
} catch {
    Write-Host "⚠️  Could not add to certificate store automatically (may require Administrator privileges)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To add manually:" -ForegroundColor Yellow
    Write-Host "1. Open PowerShell as Administrator" -ForegroundColor White
    Write-Host "2. Run: Import-Certificate -FilePath '$sslDir\localhost.crt' -CertStoreLocation Cert:\LocalMachine\Root" -ForegroundColor White
    Write-Host ""
    Write-Host "Or use Certificate Manager:" -ForegroundColor Yellow
    Write-Host "1. Press Win+R, type 'certmgr.msc', press Enter" -ForegroundColor White
    Write-Host "2. Right-click 'Trusted Root Certification Authorities' → Certificates" -ForegroundColor White
    Write-Host "3. Action → All Tasks → Import" -ForegroundColor White
    Write-Host "4. Browse to nginx\ssl\localhost.crt and import" -ForegroundColor White
}

Write-Host ""
Write-Host "🚀 Next steps:" -ForegroundColor Cyan
Write-Host "1. Restart nginx container: docker compose restart nginx" -ForegroundColor White
Write-Host "2. Access https://localhost in your browser" -ForegroundColor White
Write-Host "3. Add https://localhost to OAuth redirect URIs if using OAuth" -ForegroundColor White
