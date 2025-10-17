# Fresh Installation Test Script for Windows (PowerShell)
# Simulates end-user first-time setup experience
# Usage: .\scripts\test-fresh-install-windows.ps1

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "CSFrace Scrape - Fresh Install Test" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Stop and remove existing containers
Write-Host "Step 1: Stopping existing containers..." -ForegroundColor Yellow
docker compose down 2>$null
docker compose -f docker-compose.dev.yml down 2>$null
docker compose -f docker-compose.prod.yml down 2>$null
Write-Host "✓ Containers stopped" -ForegroundColor Green
Write-Host ""

# Step 2: Remove all CSFrace volumes (fresh database)
Write-Host "Step 2: Removing old volumes for fresh database..." -ForegroundColor Yellow
docker volume rm csfrace-scrape_postgres-data 2>$null
docker volume rm csfrace-scrape_redis-data 2>$null
docker volume rm csfrace-scrape_grafana-data 2>$null
docker volume rm csfrace-scrape_prometheus-data 2>$null
Write-Host "✓ Volumes removed" -ForegroundColor Green
Write-Host ""

# Step 3: Remove built images (force rebuild)
Write-Host "Step 3: Removing built images to force fresh build..." -ForegroundColor Yellow
docker rmi csfrace-scrape-backend 2>$null
docker rmi csfrace-scrape-frontend 2>$null
Write-Host "✓ Images removed" -ForegroundColor Green
Write-Host ""

# Step 4: Verify .env file exists
Write-Host "Step 4: Checking environment configuration..." -ForegroundColor Yellow
if (!(Test-Path .env)) {
    Write-Host "Creating .env from .env.example..." -ForegroundColor Yellow
    Copy-Item .env.example .env
    Write-Host "✓ .env created (please review and customize if needed)" -ForegroundColor Green
} else {
    Write-Host "✓ .env exists" -ForegroundColor Green
}
Write-Host ""

# Step 5: Build fresh images
Write-Host "Step 5: Building Docker images (this may take 5-10 minutes)..." -ForegroundColor Yellow
docker compose build --no-cache
Write-Host "✓ Images built successfully" -ForegroundColor Green
Write-Host ""

# Step 6: Generate HTTPS certificates
Write-Host "Step 6: Generating HTTPS certificates..." -ForegroundColor Yellow
if (Test-Path ".\create-https-cert.ps1") {
    try {
        & ".\create-https-cert.ps1"
        Write-Host "✓ HTTPS certificates created" -ForegroundColor Green
    } catch {
        Write-Host "⚠ SSL certificate generation failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "  Continuing without HTTPS (you can run .\create-https-cert.ps1 later)" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ create-https-cert.ps1 not found, skipping SSL setup" -ForegroundColor Yellow
}
Write-Host ""

# Step 7: Start services
Write-Host "Step 7: Starting all services..." -ForegroundColor Yellow
docker compose up -d
Write-Host "✓ Services started" -ForegroundColor Green
Write-Host ""

# Step 8: Wait for services to be healthy
Write-Host "Step 8: Waiting for services to be healthy (max 60 seconds)..." -ForegroundColor Yellow
$maxAttempts = 12
for ($i = 1; $i -le $maxAttempts; $i++) {
    Write-Host "Health check attempt $i/$maxAttempts..."

    # Check backend health
    try {
        $backendResponse = Invoke-RestMethod -Uri "http://localhost:8000/health/" -TimeoutSec 5
        $backendHealthy = $backendResponse.status -eq "healthy"
    } catch {
        $backendHealthy = $false
    }

    # Check frontend health
    try {
        $frontendResponse = Invoke-WebRequest -Uri "http://localhost:3000/" -TimeoutSec 5 -UseBasicParsing
        $frontendHealthy = $frontendResponse.StatusCode -eq 200
    } catch {
        $frontendHealthy = $false
    }

    if ($backendHealthy -and $frontendHealthy) {
        Write-Host "✓ All services healthy!" -ForegroundColor Green
        break
    }

    if ($i -eq $maxAttempts) {
        Write-Host "✗ Services did not become healthy in time" -ForegroundColor Red
        Write-Host "Check logs with: docker compose logs"
        exit 1
    }

    Start-Sleep -Seconds 5
}
Write-Host ""

# Step 9: Run smoke tests
Write-Host "Step 9: Running smoke tests..." -ForegroundColor Yellow

# Test backend API
Write-Host "Testing backend API..."
try {
    $backendHealth = Invoke-RestMethod -Uri "http://localhost:8000/health/"
    Write-Host "✓ Backend API responding: version $($backendHealth.version)" -ForegroundColor Green
} catch {
    Write-Host "✗ Backend API not responding" -ForegroundColor Red
    exit 1
}

# Test frontend
Write-Host "Testing frontend..."
try {
    $frontendPage = Invoke-WebRequest -Uri "http://localhost:3000/" -UseBasicParsing
    if ($frontendPage.Content -like "*CSFrace*") {
        Write-Host "✓ Frontend responding" -ForegroundColor Green
    } else {
        Write-Host "✗ Frontend not showing expected content" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Frontend not responding" -ForegroundColor Red
    exit 1
}

# Test database
Write-Host "Testing database connection..."
$postgresCheck = docker compose exec -T postgres pg_isready -U postgres
if ($postgresCheck -like "*accepting connections*") {
    Write-Host "✓ PostgreSQL accepting connections" -ForegroundColor Green
} else {
    Write-Host "✗ PostgreSQL not ready" -ForegroundColor Red
    exit 1
}

# Test Redis
Write-Host "Testing Redis connection..."
$redisCheck = docker compose exec -T redis redis-cli ping
if ($redisCheck -eq "PONG") {
    Write-Host "✓ Redis responding" -ForegroundColor Green
} else {
    Write-Host "✗ Redis not responding" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "✓ Fresh Installation Test PASSED!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Services are running at:"
Write-Host "  - Frontend (HTTPS): https://localhost"
Write-Host "  - Frontend (HTTP):  http://localhost:3000"
Write-Host "  - Backend (HTTPS):  https://localhost/api"
Write-Host "  - Backend (HTTP):   http://localhost:8000"
Write-Host "  - API Docs:         http://localhost:8000/docs"
Write-Host "  - Prometheus:       http://localhost:9090"
Write-Host "  - Grafana:          http://localhost:3001 (admin/admin)"
Write-Host ""
Write-Host "Useful commands:"
Write-Host "  - View logs:        docker compose logs -f"
Write-Host "  - Stop services:    docker compose down"
Write-Host "  - Restart:          docker compose restart"
Write-Host "  - Full cleanup:     docker compose down -v"
Write-Host ""
