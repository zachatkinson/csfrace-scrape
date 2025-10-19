# Uninstall script for Windows - Complete removal of CSFrace Scrape
# Usage: .\scripts\uninstall.ps1
# Non-interactive mode: $env:SKIP_PROMPTS="1"; .\scripts\uninstall.ps1

$ErrorActionPreference = "Stop"

Write-Host " CSFrace Scrape - Uninstallation" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "WARNING: This will remove:" -ForegroundColor Yellow
Write-Host "   - All containers"
Write-Host "   - All Docker images"
Write-Host "   - Build cache"
Write-Host ""

if ($env:SKIP_PROMPTS -eq "1") {
    $deleteData = "no"
    Write-Host "Info: Data will be preserved (non-interactive mode)" -ForegroundColor Cyan
    Write-Host ""
} else {
    $deleteData = Read-Host "DELETE all data (database, metrics, etc.)? [y/N]"
    Write-Host ""

    if ($deleteData -match "^[Yy]$") {
        Write-Host "WARNING: This will permanently delete:" -ForegroundColor Red
        Write-Host "   - All database data"
        Write-Host "   - Redis cache"
        Write-Host "   - Grafana dashboards and settings"
        Write-Host "   - Prometheus metrics history"
        Write-Host ""

        $confirmDelete = Read-Host "Are you ABSOLUTELY SURE? [y/N]"
        Write-Host ""

        if ($confirmDelete -match "^[Yy]$") {
            $deleteData = "yes"
            Write-Host "OK: Will delete all data volumes" -ForegroundColor Yellow
        } else {
            $deleteData = "no"
            Write-Host "OK: Data will be preserved" -ForegroundColor Green
        }
    } else {
        $deleteData = "no"
        Write-Host "OK: Data will be preserved for next installation" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host " Stopping all services..." -ForegroundColor Yellow
docker compose down

if ($deleteData -eq "yes") {
    Write-Host " Removing volumes and all data..." -ForegroundColor Yellow
    docker compose down -v
} else {
    Write-Host "OK: Keeping volumes (data preserved)" -ForegroundColor Green
}

Write-Host " Removing Docker images..." -ForegroundColor Yellow
try {
    docker rmi csfrace-scrape-backend csfrace-scrape-frontend 2>$null
} catch {
    Write-Host "   (Images already removed)" -ForegroundColor Gray
}

Write-Host " Removing build cache..." -ForegroundColor Yellow
docker builder prune -f

Write-Host " Removing SSL certificate files..." -ForegroundColor Yellow
if (Test-Path "nginx\ssl") {
    Remove-Item -Recurse -Force "nginx\ssl"
    Write-Host "OK: SSL certificate files removed" -ForegroundColor Green
} else {
    Write-Host "   (No SSL certificate files found)" -ForegroundColor Gray
}

# Check for output directory
if (Test-Path "output") {
    if ($env:SKIP_PROMPTS -eq "1") {
        Write-Host "Info: Output files preserved (non-interactive mode)" -ForegroundColor Cyan
    } else {
        Write-Host ""
        $deleteOutput = Read-Host "DELETE output files (scraped content)? [y/N]"
        Write-Host ""

        if ($deleteOutput -match "^[Yy]$") {
            Write-Host " Removing output files..." -ForegroundColor Yellow
            Remove-Item -Recurse -Force "output"
            Write-Host "OK: Output files removed" -ForegroundColor Green
        } else {
            Write-Host "OK: Output files preserved" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "OK: Uninstallation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: The following were NOT removed:" -ForegroundColor Yellow
Write-Host "   - Source code in this directory"
Write-Host "   - .env configuration file"
Write-Host "   - SSL certificates in Windows certificate store (shared across projects)"
Write-Host "   - Base Docker images (postgres, redis, etc.)"
Write-Host ""
Write-Host "To remove SSL certificate from certificate store:"
Write-Host "   .\scripts\remove-localhost-cert.ps1"
Write-Host ""
Write-Host "To remove source code: cd .. && Remove-Item -Recurse -Force csfrace-scrape"
Write-Host "To remove .env: Remove-Item .env"
