#!/bin/bash
set -e

echo "🧹 Complete System Cleanup Script"
echo "=================================="
echo ""

# Stop all containers
echo "📦 Stopping all containers..."
docker compose down

# Remove all containers
echo "🗑️  Removing all containers..."
docker compose rm -f

# Remove all volumes (this will delete database data)
echo "💾 Removing all volumes (database data will be lost)..."
docker compose down -v

# Remove Docker images for this project
echo "🖼️  Removing project Docker images..."
docker rmi $(docker images -q 'csfrace-scrape*' 2>/dev/null) 2>/dev/null || echo "No project images to remove"

# Clean build cache
echo "🏗️  Cleaning build cache..."
docker builder prune -f

# Remove output files from backend
echo "📁 Removing backend output files..."
rm -rf backend/converted_content/* 2>/dev/null || true
rm -rf backend/*.log 2>/dev/null || true

# Remove frontend build artifacts
echo "🎨 Removing frontend build artifacts..."
rm -rf frontend/dist/* 2>/dev/null || true
rm -rf frontend/.astro/* 2>/dev/null || true

echo ""
echo "✅ Complete cleanup finished!"
echo ""
echo "Next steps:"
echo "1. Run: docker compose build --no-cache"
echo "2. Run: docker compose up -d"
echo "3. Wait for services to be healthy"
echo "4. Test with a fresh job submission"
