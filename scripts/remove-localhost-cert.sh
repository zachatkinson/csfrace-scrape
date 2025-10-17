#!/bin/bash
# Remove localhost SSL certificate from macOS keychain
# This is an OPTIONAL cleanup script - certificates are intentionally shared across projects
# Usage: ./scripts/remove-localhost-cert.sh

set -e

echo "🔒 Remove localhost SSL Certificate from macOS Keychain"
echo "========================================================"
echo ""
echo "⚠️  WARNING: This will remove the localhost certificate from your"
echo "   macOS System Keychain. This certificate may be used by other"
echo "   local development projects on your machine."
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    echo "❌ Certificate removal cancelled"
    exit 0
fi

echo "🗑️  Removing localhost certificate from macOS keychain..."

# Try to find and remove localhost certificates
if sudo security find-certificate -c localhost -a -Z /Library/Keychains/System.keychain 2>/dev/null | grep -q "localhost"; then
    if sudo security delete-certificate -c localhost /Library/Keychains/System.keychain 2>/dev/null; then
        echo "✅ Certificate removed from macOS keychain"
    else
        echo "⚠️  Could not remove certificate automatically"
        echo ""
        echo "To remove manually:"
        echo "1. Open Keychain Access app"
        echo "2. Select 'System' keychain"
        echo "3. Search for 'localhost'"
        echo "4. Right-click and delete the certificate"
    fi
else
    echo "ℹ️  No localhost certificate found in keychain"
fi

echo ""
echo "✅ Done!"
