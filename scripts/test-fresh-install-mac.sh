#!/bin/bash
# Fresh Installation Test Script for macOS
# Simulates end-user first-time setup experience
# Usage: ./scripts/test-fresh-install-mac.sh

set -e  # Exit on error

echo "======================================"
echo "CSFrace Scrape - Fresh Install Test"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Stop and remove existing containers
echo -e "${YELLOW}Step 1: Stopping existing containers...${NC}"
docker compose down 2>/dev/null || true
docker compose -f docker-compose.dev.yml down 2>/dev/null || true
docker compose -f docker-compose.prod.yml down 2>/dev/null || true
echo -e "${GREEN}✓ Containers stopped${NC}"
echo ""

# Step 2: Remove all CSFrace volumes (fresh database)
echo -e "${YELLOW}Step 2: Removing old volumes for fresh database...${NC}"
docker volume rm csfrace-scrape_postgres-data 2>/dev/null || true
docker volume rm csfrace-scrape_redis-data 2>/dev/null || true
docker volume rm csfrace-scrape_grafana-data 2>/dev/null || true
docker volume rm csfrace-scrape_prometheus-data 2>/dev/null || true
echo -e "${GREEN}✓ Volumes removed${NC}"
echo ""

# Step 3: Remove built images (force rebuild)
echo -e "${YELLOW}Step 3: Removing built images to force fresh build...${NC}"
docker rmi csfrace-scrape-backend 2>/dev/null || true
docker rmi csfrace-scrape-frontend 2>/dev/null || true
echo -e "${GREEN}✓ Images removed${NC}"
echo ""

# Step 4: Verify .env file exists
echo -e "${YELLOW}Step 4: Checking environment configuration...${NC}"
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env from .env.example...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✓ .env created (please review and customize if needed)${NC}"
else
    echo -e "${GREEN}✓ .env exists${NC}"
fi
echo ""

# Step 5: Build fresh images
echo -e "${YELLOW}Step 5: Building Docker images (this may take 5-10 minutes)...${NC}"
docker compose build --no-cache
echo -e "${GREEN}✓ Images built successfully${NC}"
echo ""

# Step 6: Generate HTTPS certificates
echo -e "${YELLOW}Step 6: Generating HTTPS certificates...${NC}"
if [ -f ./create-https-cert.sh ]; then
    chmod +x ./create-https-cert.sh
    ./create-https-cert.sh
    echo -e "${GREEN}✓ HTTPS certificates created${NC}"
else
    echo -e "${YELLOW}⚠ create-https-cert.sh not found, skipping SSL setup${NC}"
fi
echo ""

# Step 7: Start services
echo -e "${YELLOW}Step 7: Starting all services...${NC}"
docker compose up -d
echo -e "${GREEN}✓ Services started${NC}"
echo ""

# Step 8: Wait for services to be healthy
echo -e "${YELLOW}Step 8: Waiting for services to be healthy (max 60 seconds)...${NC}"
for i in {1..12}; do
    echo "Health check attempt $i/12..."

    # Check backend health
    BACKEND_HEALTH=$(curl -s http://localhost:8000/health/ | grep -o '"status":"healthy"' || echo "")

    # Check frontend health
    FRONTEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ || echo "000")

    if [ "$FRONTEND_HEALTH" = "200" ] && [ -n "$BACKEND_HEALTH" ]; then
        echo -e "${GREEN}✓ All services healthy!${NC}"
        break
    fi

    if [ $i -eq 12 ]; then
        echo -e "${RED}✗ Services did not become healthy in time${NC}"
        echo "Check logs with: docker compose logs"
        exit 1
    fi

    sleep 5
done
echo ""

# Step 9: Run smoke tests
echo -e "${YELLOW}Step 9: Running smoke tests...${NC}"

# Test backend API
echo "Testing backend API..."
BACKEND_VERSION=$(curl -s http://localhost:8000/health/ | grep -o '"version":"[^"]*"' || echo "ERROR")
if [ "$BACKEND_VERSION" != "ERROR" ]; then
    echo -e "${GREEN}✓ Backend API responding: $BACKEND_VERSION${NC}"
else
    echo -e "${RED}✗ Backend API not responding${NC}"
    exit 1
fi

# Test frontend
echo "Testing frontend..."
if curl -s http://localhost:3000/ | grep -q "CSFrace"; then
    echo -e "${GREEN}✓ Frontend responding${NC}"
else
    echo -e "${RED}✗ Frontend not responding${NC}"
    exit 1
fi

# Test database
echo "Testing database connection..."
POSTGRES_CHECK=$(docker compose exec -T postgres pg_isready -U postgres || echo "ERROR")
if echo "$POSTGRES_CHECK" | grep -q "accepting connections"; then
    echo -e "${GREEN}✓ PostgreSQL accepting connections${NC}"
else
    echo -e "${RED}✗ PostgreSQL not ready${NC}"
    exit 1
fi

# Test Redis
echo "Testing Redis connection..."
REDIS_CHECK=$(docker compose exec -T redis redis-cli ping || echo "ERROR")
if [ "$REDIS_CHECK" = "PONG" ]; then
    echo -e "${GREEN}✓ Redis responding${NC}"
else
    echo -e "${RED}✗ Redis not responding${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}======================================"
echo "✓ Fresh Installation Test PASSED!"
echo "======================================${NC}"
echo ""
echo "Services are running at:"
echo "  - Frontend (HTTPS): https://localhost"
echo "  - Frontend (HTTP):  http://localhost:3000"
echo "  - Backend (HTTPS):  https://localhost/api"
echo "  - Backend (HTTP):   http://localhost:8000"
echo "  - API Docs:         http://localhost:8000/docs"
echo "  - Prometheus:       http://localhost:9090"
echo "  - Grafana:          http://localhost:3001 (admin/admin)"
echo ""
echo "Useful commands:"
echo "  - View logs:        docker compose logs -f"
echo "  - Stop services:    docker compose down"
echo "  - Restart:          docker compose restart"
echo "  - Full cleanup:     docker compose down -v"
echo ""
