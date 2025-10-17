# Uninstall script for Windows - Complete removal of CSFrace Scrape
# Usage: .\scripts\uninstall.ps1

$ErrorActionPreference = "Stop"

Write-Host "🗑️  CSFrace Scrape - Uninstallation" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  WARNING: This will remove:" -ForegroundColor Yellow
Write-Host "   - All containers"
Write-Host "   - All volumes (including database data)"
Write-Host "   - All Docker images"
Write-Host "   - Build cache"
Write-Host ""

$confirmation = Read-Host "Are you sure you want to continue? (yes/no)"
Write-Host ""

if ($confirmation -ne "yes") {
    Write-Host "❌ Uninstallation cancelled" -ForegroundColor Red
    exit 0
}

Write-Host "🛑 Stopping all services..." -ForegroundColor Yellow
docker compose down

Write-Host "🗑️  Removing volumes..." -ForegroundColor Yellow
docker compose down -v

Write-Host "🗑️  Removing Docker images..." -ForegroundColor Yellow
try {
    docker rmi csfrace-scrape-backend csfrace-scrape-frontend 2>$null
} catch {
    Write-Host "   (Images already removed)" -ForegroundColor Gray
}

Write-Host "🗑️  Removing build cache..." -ForegroundColor Yellow
docker builder prune -f

Write-Host "🗑️  Removing SSL certificates..." -ForegroundColor Yellow
if (Test-Path "nginx\ssl") {
    # Remove certificate from Windows certificate store if it exists
    if (Test-Path "nginx\ssl\localhost.crt") {
        Write-Host "   Removing certificate from Windows certificate store..." -ForegroundColor Gray
        try {
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("nginx\ssl\localhost.crt")
            $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
            $store.Open("ReadWrite")
            $existingCerts = $store.Certificates | Where-Object { $_.Subject -eq $cert.Subject -and $_.Thumbprint -eq $cert.Thumbprint }
            if ($existingCerts) {
                $store.Remove($existingCerts[0])
                Write-Host "   ✓ Certificate removed from Windows certificate store" -ForegroundColor Green
            } else {
                Write-Host "   (Certificate not in store or already removed)" -ForegroundColor Gray
            }
            $store.Close()
        } catch {
            Write-Host "   (Could not remove from certificate store - may require Administrator privileges)" -ForegroundColor Gray
        }
    }

    # Remove SSL directory
    Remove-Item -Recurse -Force "nginx\ssl"
    Write-Host "   ✓ SSL certificates removed" -ForegroundColor Green
} else {
    Write-Host "   (No SSL certificates found)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✅ Uninstallation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: The following were NOT removed:" -ForegroundColor Yellow
Write-Host "   - Source code in this directory"
Write-Host "   - .env configuration file"
Write-Host "   - Base Docker images (postgres, redis, etc.)"
Write-Host ""
Write-Host "To remove source code: cd .. && Remove-Item -Recurse -Force csfrace-scrape"
Write-Host "To remove .env: Remove-Item .env"
