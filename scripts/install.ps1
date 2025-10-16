# Simple one-command installation script for Windows
# Usage: .\scripts\install.ps1

$ErrorActionPreference = "Stop"

Write-Host "🚀 CSFrace Scrape - Installation" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Check if .env exists
if (!(Test-Path .env)) {
    Write-Host "📝 Creating .env file from template..." -ForegroundColor Yellow
    Copy-Item .env.example .env
    Write-Host "✅ .env created" -ForegroundColor Green
} else {
    Write-Host "✅ .env already exists" -ForegroundColor Green
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
Write-Host "   Frontend:    http://localhost:3000"
Write-Host "   Backend API: http://localhost:8000"
Write-Host "   API Docs:    http://localhost:8000/docs"
Write-Host "   Grafana:     http://localhost:3001 (admin/admin)"
Write-Host "   Prometheus:  http://localhost:9090"
Write-Host ""
Write-Host "🎉 Ready to use!" -ForegroundColor Green
