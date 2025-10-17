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
        $startFresh = Read-Host "Do you want to start FRESH (delete existing data)? (yes/no)"
        Write-Host ""

        if ($startFresh -eq "yes") {
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
