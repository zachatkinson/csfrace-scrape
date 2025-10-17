#!/bin/bash
# Simple one-command installation script
# Usage: ./scripts/install.sh
# Non-interactive mode: SKIP_PROMPTS=1 ./scripts/install.sh

set -e

echo "🚀 CSFrace Scrape - Installation"
echo "================================="
echo ""

# Check for existing data volumes
EXISTING_VOLUMES=$(docker volume ls --filter name=csfrace-scrape --format "{{.Name}}" | wc -l)

if [ $EXISTING_VOLUMES -gt 0 ]; then
    if [ "$SKIP_PROMPTS" = "1" ]; then
        echo "ℹ️  Existing data found - preserving (non-interactive mode)"
        echo ""
    else
        echo "ℹ️  Existing data found from previous installation"
        echo ""
        read -p "Start FRESH (delete existing data)? [y/N]: " -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🗑️  Removing existing data volumes..."
            docker compose down -v 2>/dev/null || true
            echo "✓ Starting with fresh database"
        else
            echo "✓ Preserving existing data"
        fi
        echo ""
    fi
fi

# Check if .env exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "✅ .env created"
else
    echo "✅ .env already exists"
fi

echo ""
echo "🔨 Building Docker images..."
echo "   (First time: 5-10 minutes on ARM64 Macs, faster on AMD64)"
echo ""

# Build with progress output (redirect to show progress but not hang)
docker compose build 2>&1 | cat

echo ""
echo "🚢 Starting services..."
docker compose up -d

echo ""
echo "⏳ Waiting for services to be healthy..."

# Wait for backend health
for i in {1..30}; do
    if curl -s http://localhost:8000/health/ > /dev/null 2>&1; then
        echo "✅ Backend is healthy"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Backend did not become healthy"
        exit 1
    fi
    sleep 2
done

# Wait for frontend health
for i in {1..30}; do
    if curl -s http://localhost:3000/ > /dev/null 2>&1; then
        echo "✅ Frontend is healthy"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Frontend did not become healthy"
        exit 1
    fi
    sleep 2
done

echo ""
echo "✅ Installation complete!"
echo ""
echo "📍 Service URLs:"
echo "   Frontend:    https://localhost"
echo "   Backend API: https://localhost/api"
echo "   API Docs:    https://localhost/docs"
echo "   Grafana:     http://localhost:3001 (admin/admin)"
echo "   Prometheus:  http://localhost:9090"
echo ""
echo "💡 Note: HTTPS requires SSL certificates. Run ./create-https-cert.sh to generate them."
echo ""
echo "🎉 Ready to use!"
