#!/bin/bash
# Uninstall script - Complete removal of CSFrace Scrape
# Usage: ./scripts/uninstall.sh

set -e

echo "🗑️  CSFrace Scrape - Uninstallation"
echo "===================================="
echo ""
echo "⚠️  WARNING: This will remove:"
echo "   - All containers"
echo "   - All volumes (including database data)"
echo "   - All Docker images"
echo "   - Build cache"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    echo "❌ Uninstallation cancelled"
    exit 0
fi

echo "🛑 Stopping all services..."
docker compose down

echo "🗑️  Removing volumes..."
docker compose down -v

echo "🗑️  Removing Docker images..."
docker rmi csfrace-scrape-backend csfrace-scrape-frontend 2>/dev/null || echo "   (Images already removed)"

echo "🗑️  Removing build cache..."
docker builder prune -f

echo ""
echo "✅ Uninstallation complete!"
echo ""
echo "Note: The following were NOT removed:"
echo "   - Source code in this directory"
echo "   - .env configuration file"
echo "   - Base Docker images (postgres, redis, etc.)"
echo ""
echo "To remove source code: cd .. && rm -rf csfrace-scrape"
echo "To remove .env: rm .env"
