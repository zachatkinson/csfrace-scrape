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
