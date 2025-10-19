# Uninstall script for Windows - Complete removal of CSFrace Scrape
# Usage: .\scripts\uninstall.ps1
# Non-interactive mode: $env:SKIP_PROMPTS="1"; .\scripts\uninstall.ps1

$ErrorActionPreference = "Stop"

Write-Host " CSFrace Scrape - Complete Uninstallation" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "WARNING: This will PERMANENTLY DELETE:" -ForegroundColor Red
Write-Host "   - All Docker containers and images" -ForegroundColor Yellow
Write-Host "   - All database data (PostgreSQL)" -ForegroundColor Yellow
Write-Host "   - All cache data (Redis)" -ForegroundColor Yellow
Write-Host "   - All metrics and dashboards (Grafana, Prometheus)" -ForegroundColor Yellow
Write-Host "   - All scraped output files" -ForegroundColor Yellow
Write-Host "   - All SSL certificate files" -ForegroundColor Yellow
Write-Host "   - SSL certificate from Windows Trusted Root store" -ForegroundColor Yellow
Write-Host "   - Environment configuration (.env file)" -ForegroundColor Yellow
Write-Host "   - Docker build cache" -ForegroundColor Yellow
Write-Host ""
Write-Host "The ONLY thing preserved:" -ForegroundColor Green
Write-Host "   - Source code (Git repository files)" -ForegroundColor Green
Write-Host ""

if ($env:SKIP_PROMPTS -eq "1") {
    Write-Host "Info: Running in non-interactive mode - proceeding with full uninstall" -ForegroundColor Cyan
    Write-Host ""
} else {
    $confirm = Read-Host "Are you ABSOLUTELY SURE you want to uninstall everything? [y/N]"
    Write-Host ""

    if ($confirm -notmatch "^[Yy]$") {
        Write-Host "Uninstall cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host " Stopping all services..." -ForegroundColor Yellow
docker compose down -v

Write-Host " Removing Docker images..." -ForegroundColor Yellow
try {
    docker rmi csfrace-scrape-backend csfrace-scrape-frontend 2>$null
    Write-Host "OK: Docker images removed" -ForegroundColor Green
} catch {
    Write-Host "OK: Docker images already removed" -ForegroundColor Green
}

Write-Host " Removing build cache..." -ForegroundColor Yellow
docker builder prune -f
Write-Host "OK: Build cache cleared" -ForegroundColor Green

Write-Host " Removing SSL certificate files..." -ForegroundColor Yellow
if (Test-Path "nginx\ssl") {
    Remove-Item -Recurse -Force "nginx\ssl"
    Write-Host "OK: SSL certificate files removed" -ForegroundColor Green
} else {
    Write-Host "OK: No SSL certificate files found" -ForegroundColor Green
}

Write-Host " Removing SSL certificate from Windows trust store..." -ForegroundColor Yellow
try {
    $cert = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Subject -eq "CN=localhost" }
    if ($cert) {
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
        $store.Open("ReadWrite")
        $store.Remove($cert)
        $store.Close()
        Write-Host "OK: SSL certificate removed from Windows trust store" -ForegroundColor Green
    } else {
        Write-Host "OK: No localhost certificate found in trust store" -ForegroundColor Green
    }
} catch {
    Write-Host "Warning: Could not remove certificate from trust store (may require admin privileges)" -ForegroundColor Yellow
    Write-Host "   You can manually remove it with: .\scripts\remove-localhost-cert.ps1" -ForegroundColor Gray
}

Write-Host " Removing output files..." -ForegroundColor Yellow
if (Test-Path "output") {
    Remove-Item -Recurse -Force "output"
    Write-Host "OK: Output files removed" -ForegroundColor Green
} else {
    Write-Host "OK: No output files found" -ForegroundColor Green
}

Write-Host " Removing environment configuration..." -ForegroundColor Yellow
if (Test-Path ".env") {
    Remove-Item -Force ".env"
    Write-Host "OK: .env file removed" -ForegroundColor Green
} else {
    Write-Host "OK: No .env file found" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " UNINSTALL COMPLETE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Everything has been removed except:" -ForegroundColor Cyan
Write-Host "   - Source code (Git repository)" -ForegroundColor White
Write-Host "   - Base Docker images (postgres, redis, etc.)" -ForegroundColor White
Write-Host ""
Write-Host "To reinstall: Run .\scripts\install.ps1" -ForegroundColor Cyan
Write-Host "To remove source code: cd .. && Remove-Item -Recurse -Force csfrace-scrape" -ForegroundColor Cyan
Write-Host ""
