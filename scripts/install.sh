#!/bin/bash
# Simple one-command installation script
# Usage: ./scripts/install.sh

set -e

echo "🚀 CSFrace Scrape - Installation"
echo "================================="
echo ""

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

# Build with progress output
docker compose build

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
echo "   Frontend:    http://localhost:3000"
echo "   Backend API: http://localhost:8000"
echo "   API Docs:    http://localhost:8000/docs"
echo "   Grafana:     http://localhost:3001 (admin/admin)"
echo "   Prometheus:  http://localhost:9090"
echo ""
echo "🎉 Ready to use!"
