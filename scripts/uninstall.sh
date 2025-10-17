#!/bin/bash
# Uninstall script - Complete removal of CSFrace Scrape
# Usage: ./scripts/uninstall.sh
# Non-interactive mode: SKIP_PROMPTS=1 ./scripts/uninstall.sh

set -e

echo "🗑️  CSFrace Scrape - Uninstallation"
echo "===================================="
echo ""
echo "⚠️  This will remove:"
echo "   - All containers"
echo "   - All Docker images"
echo "   - Build cache"
echo ""

if [ "$SKIP_PROMPTS" = "1" ]; then
    DELETE_DATA="no"
    echo "ℹ️  Data will be preserved (non-interactive mode)"
    echo ""
else
    read -p "DELETE all data (database, metrics, etc.)? [y/N]: " -r
    echo ""

    DELETE_DATA=$REPLY

    if [[ $DELETE_DATA =~ ^[Yy]$ ]]; then
        echo "⚠️  WARNING: This will permanently delete:"
        echo "   - All database data"
        echo "   - Redis cache"
        echo "   - Grafana dashboards and settings"
        echo "   - Prometheus metrics history"
        echo ""
        read -p "Are you ABSOLUTELY SURE? [y/N]: " -r
        echo ""

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            DELETE_DATA="no"
            echo "✓ Data will be preserved"
        fi
    else
        echo "✓ Data will be preserved for next installation"
    fi
fi

echo ""
echo "🛑 Stopping all services..."
docker compose down

if [[ $DELETE_DATA =~ ^[Yy]es$ ]]; then
    echo "🗑️  Removing volumes and all data..."
    docker compose down -v
else
    echo "✓ Keeping volumes (data preserved)"
fi

echo "🗑️  Removing Docker images..."
docker rmi csfrace-scrape-backend csfrace-scrape-frontend 2>/dev/null || echo "   (Images already removed)"

echo "🗑️  Removing build cache..."
docker builder prune -f

echo "🗑️  Removing SSL certificate files..."
if [ -d "nginx/ssl" ]; then
    rm -rf nginx/ssl
    echo "   ✓ SSL certificate files removed"
else
    echo "   (No SSL certificate files found)"
fi

# Check for output directory
if [ -d "output" ]; then
    if [ "$SKIP_PROMPTS" = "1" ]; then
        echo "ℹ️  Output files preserved (non-interactive mode)"
    else
        echo ""
        read -p "DELETE output files (scraped content)? [y/N]: " -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🗑️  Removing output files..."
            rm -rf output
            echo "   ✓ Output files removed"
        else
            echo "   ✓ Output files preserved"
        fi
    fi
fi

echo ""
echo "✅ Uninstallation complete!"
echo ""
echo "Note: The following were NOT removed:"
echo "   - Source code in this directory"
echo "   - .env configuration file"
echo "   - SSL certificates in system keychain (shared across projects)"
echo "   - Base Docker images (postgres, redis, etc.)"
echo ""
echo "To remove SSL certificate from system keychain:"
echo "   ./scripts/remove-localhost-cert.sh"
echo ""
echo "To remove source code: cd .. && rm -rf csfrace-scrape"
echo "To remove .env: rm .env"
