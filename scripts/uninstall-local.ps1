# Simple one-command LOCAL uninstallation for Windows
# For single-user deployments WITHOUT OAuth/SSL setup
# Usage: .\scripts\uninstall-local.ps1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Red
Write-Host "  CSFrace Scrape - Local Uninstallation (Windows)" -ForegroundColor Red
Write-Host "================================================================" -ForegroundColor Red
Write-Host ""
Write-Host "This will remove CSFrace local installation and optionally delete data." -ForegroundColor Yellow
Write-Host ""

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "❌ Error: PowerShell 7 or higher is required" -ForegroundColor Red
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    exit 1
}

# Check if services are running
Write-Host "⏳ Checking for running services..." -ForegroundColor Yellow
$runningServices = docker compose -f docker-compose.dev.yml ps --format json 2>$null
if ($runningServices) {
    Write-Host "✅ Found running services" -ForegroundColor Green
} else {
    Write-Host "⚠️  No running services found" -ForegroundColor Yellow
}
Write-Host ""

# Confirm uninstallation
Write-Host "⚠️  WARNING: This will stop all CSFrace services" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Continue with uninstallation? [y/N]"
if ($confirm -notmatch "^[Yy]$") {
    Write-Host ""
    Write-Host "❌ Uninstallation cancelled" -ForegroundColor Yellow
    Write-Host ""
    exit 0
}
Write-Host ""

# Stop services
Write-Host "⏳ Stopping services..." -ForegroundColor Yellow
docker compose -f docker-compose.dev.yml down 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Services stopped" -ForegroundColor Green
} else {
    Write-Host "⚠️  Services were not running or already stopped" -ForegroundColor Yellow
}
Write-Host ""

# Ask about data removal
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Data Removal Options" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Do you want to DELETE all data? (database, jobs, etc.)" -ForegroundColor Yellow
Write-Host ""
Write-Host "  This includes:" -ForegroundColor Gray
Write-Host "    - PostgreSQL database" -ForegroundColor Gray
Write-Host "    - Redis cache" -ForegroundColor Gray
Write-Host "    - Scraped job data" -ForegroundColor Gray
Write-Host ""
$deleteData = Read-Host "Delete all data? [y/N]"
Write-Host ""

if ($deleteData -match "^[Yy]$") {
    Write-Host "⏳ Removing data volumes..." -ForegroundColor Yellow
    docker compose -f docker-compose.dev.yml down -v 2>$null

    # Remove any remaining volumes
    $volumes = docker volume ls --filter "name=csfrace" --format "{{.Name}}" 2>$null
    if ($volumes) {
        foreach ($volume in $volumes) {
            Write-Host "  Removing volume: $volume" -ForegroundColor Gray
            docker volume rm $volume 2>$null
        }
    }

    Write-Host "✅ All data removed" -ForegroundColor Green
} else {
    Write-Host "✅ Data preserved (volumes kept)" -ForegroundColor Green
}
Write-Host ""

# Ask about Docker images
Write-Host "Do you want to DELETE Docker images?" -ForegroundColor Yellow
Write-Host ""
Write-Host "  This frees disk space but means next install will rebuild" -ForegroundColor Gray
Write-Host "  (5-10 minutes rebuild time)" -ForegroundColor Gray
Write-Host ""
$deleteImages = Read-Host "Delete Docker images? [y/N]"
Write-Host ""

if ($deleteImages -match "^[Yy]$") {
    Write-Host "⏳ Removing Docker images..." -ForegroundColor Yellow

    # Remove project images
    $images = docker images --filter "reference=csfrace-scrape*" --format "{{.Repository}}:{{.Tag}}" 2>$null
    if ($images) {
        foreach ($image in $images) {
            Write-Host "  Removing image: $image" -ForegroundColor Gray
            docker rmi $image 2>$null
        }
        Write-Host "✅ Images removed" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No images found" -ForegroundColor Yellow
    }
} else {
    Write-Host "✅ Images preserved (faster next install)" -ForegroundColor Green
}
Write-Host ""

# Ask about .env files
Write-Host "Do you want to DELETE configuration files (.env)?" -ForegroundColor Yellow
Write-Host ""
Write-Host "  This includes:" -ForegroundColor Gray
Write-Host "    - .env (backend config)" -ForegroundColor Gray
Write-Host "    - frontend\.env (frontend config)" -ForegroundColor Gray
Write-Host ""
$deleteEnv = Read-Host "Delete .env files? [y/N]"
Write-Host ""

if ($deleteEnv -match "^[Yy]$") {
    Write-Host "⏳ Removing .env files..." -ForegroundColor Yellow

    if (Test-Path .env) {
        Remove-Item .env
        Write-Host "  Removed .env" -ForegroundColor Gray
    }

    if (Test-Path frontend\.env) {
        Remove-Item frontend\.env
        Write-Host "  Removed frontend\.env" -ForegroundColor Gray
    }

    Write-Host "✅ Configuration files removed" -ForegroundColor Green
} else {
    Write-Host "✅ Configuration files preserved" -ForegroundColor Green
}
Write-Host ""

# Ask about output files
Write-Host "Do you want to DELETE scraped output files?" -ForegroundColor Yellow
Write-Host ""
Write-Host "  This includes:" -ForegroundColor Gray
Write-Host "    - converted_content/ (scraped data)" -ForegroundColor Gray
Write-Host "    - dev-output/ (development output)" -ForegroundColor Gray
Write-Host "    - dev-logs/ (development logs)" -ForegroundColor Gray
Write-Host ""
$deleteOutput = Read-Host "Delete output files? [y/N]"
Write-Host ""

if ($deleteOutput -match "^[Yy]$") {
    Write-Host "⏳ Removing output files..." -ForegroundColor Yellow

    if (Test-Path converted_content) {
        Remove-Item -Recurse -Force converted_content
        Write-Host "  Removed converted_content/" -ForegroundColor Gray
    }

    if (Test-Path dev-output) {
        Remove-Item -Recurse -Force dev-output
        Write-Host "  Removed dev-output/" -ForegroundColor Gray
    }

    if (Test-Path dev-logs) {
        Remove-Item -Recurse -Force dev-logs
        Write-Host "  Removed dev-logs/" -ForegroundColor Gray
    }

    Write-Host "✅ Output files removed" -ForegroundColor Green
} else {
    Write-Host "✅ Output files preserved" -ForegroundColor Green
}
Write-Host ""

# Final cleanup - prune unused Docker resources
Write-Host "Do you want to PRUNE unused Docker resources?" -ForegroundColor Yellow
Write-Host ""
Write-Host "  This removes:" -ForegroundColor Gray
Write-Host "    - Unused networks" -ForegroundColor Gray
Write-Host "    - Dangling images" -ForegroundColor Gray
Write-Host "    - Build cache" -ForegroundColor Gray
Write-Host ""
Write-Host "  (Safe - only removes unused Docker resources)" -ForegroundColor Green
Write-Host ""
$pruneDocker = Read-Host "Prune Docker resources? [y/N]"
Write-Host ""

if ($pruneDocker -match "^[Yy]$") {
    Write-Host "⏳ Pruning Docker resources..." -ForegroundColor Yellow
    docker system prune -f 2>$null
    Write-Host "✅ Docker resources pruned" -ForegroundColor Green
} else {
    Write-Host "✅ Skipped Docker pruning" -ForegroundColor Green
}
Write-Host ""

# Summary
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  ✅ Uninstallation Complete" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "CSFrace local installation has been removed." -ForegroundColor White
Write-Host ""
Write-Host "To reinstall, run:" -ForegroundColor Cyan
Write-Host "  .\scripts\install-local.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
