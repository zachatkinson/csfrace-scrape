# Remove localhost SSL certificate from Windows certificate store
# This is an OPTIONAL cleanup script - certificates are intentionally shared across projects
# Usage: .\scripts\remove-localhost-cert.ps1
# Note: Must be run as Administrator

$ErrorActionPreference = "Stop"

Write-Host "🔒 Remove localhost SSL Certificate from Windows Certificate Store" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  WARNING: This will remove the localhost certificate from your" -ForegroundColor Yellow
Write-Host "   Windows Trusted Root Certification Authorities. This certificate" -ForegroundColor Yellow
Write-Host "   may be used by other local development projects on your machine." -ForegroundColor Yellow
Write-Host ""

$confirmation = Read-Host "Are you sure you want to continue? (yes/no)"
Write-Host ""

if ($confirmation -ne "yes") {
    Write-Host "❌ Certificate removal cancelled" -ForegroundColor Red
    exit 0
}

Write-Host "🗑️  Removing localhost certificate from Windows certificate store..." -ForegroundColor Yellow

try {
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
    $store.Open("ReadWrite")

    # Find all localhost certificates
    $localhostCerts = $store.Certificates | Where-Object { $_.Subject -like "*CN=localhost*" }

    if ($localhostCerts.Count -eq 0) {
        Write-Host "ℹ️  No localhost certificates found in certificate store" -ForegroundColor Gray
    } else {
        foreach ($cert in $localhostCerts) {
            Write-Host "   Removing certificate: $($cert.Subject)" -ForegroundColor Gray
            $store.Remove($cert)
        }
        Write-Host "✅ Removed $($localhostCerts.Count) localhost certificate(s) from Windows certificate store" -ForegroundColor Green
    }

    $store.Close()
} catch {
    Write-Host "❌ Error removing certificate: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "This script requires Administrator privileges." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To remove manually:" -ForegroundColor Yellow
    Write-Host "1. Press Win+R, type 'certmgr.msc', press Enter" -ForegroundColor White
    Write-Host "2. Navigate to 'Trusted Root Certification Authorities' -> Certificates" -ForegroundColor White
    Write-Host "3. Find and delete the 'localhost' certificate" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "✅ Done!" -ForegroundColor Green
