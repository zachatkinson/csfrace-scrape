#!/bin/bash

# Create HTTPS certificates for local development
# Required for Google OAuth and secure local development

set -e  # Exit on error

echo "🔒 Creating HTTPS certificates for local development..."

# Check if certificates already exist
if [ -f "nginx/ssl/localhost.crt" ] && [ -f "nginx/ssl/localhost.key" ]; then
    echo ""
    echo "ℹ️  SSL certificates already exist in nginx/ssl/"

    # Check certificate expiration
    EXPIRY_DATE=$(openssl x509 -enddate -noout -in nginx/ssl/localhost.crt | cut -d= -f2)
    EXPIRY_EPOCH=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$EXPIRY_DATE" "+%s" 2>/dev/null || date -d "$EXPIRY_DATE" "+%s" 2>/dev/null)
    CURRENT_EPOCH=$(date "+%s")
    DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))

    if [ $DAYS_UNTIL_EXPIRY -lt 30 ]; then
        echo "⚠️  Certificate expires in $DAYS_UNTIL_EXPIRY days - regeneration recommended"
        echo ""
        read -p "Do you want to regenerate the certificate? (yes/no): " -r
    else
        echo "✅ Certificate is valid for $DAYS_UNTIL_EXPIRY more days"
        echo ""
        read -p "Do you want to regenerate anyway? (yes/no): " -r
    fi

    echo ""

    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        echo "✅ Using existing certificates"
        echo ""
        echo "To use the existing certificates:"
        echo "1. Restart nginx container: docker compose restart nginx"
        echo "2. Access https://localhost in your browser"
        exit 0
    fi

    echo "🗑️  Removing old certificates..."
    rm -f nginx/ssl/localhost.crt nginx/ssl/localhost.key nginx/ssl/localhost.csr
fi

# Create nginx ssl directory
mkdir -p nginx/ssl

# Generate private key
echo "📝 Generating private key..."
openssl genrsa -out nginx/ssl/localhost.key 2048

# Create certificate signing request with Subject Alternative Names
echo "📝 Creating certificate signing request..."
openssl req -new -key nginx/ssl/localhost.key \
  -out nginx/ssl/localhost.csr \
  -subj "/C=US/ST=CA/L=SF/O=Dev/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,DNS:*.localhost,IP:127.0.0.1"

# Generate self-signed certificate with SAN
echo "📝 Generating self-signed certificate..."
openssl x509 -req \
  -in nginx/ssl/localhost.csr \
  -signkey nginx/ssl/localhost.key \
  -out nginx/ssl/localhost.crt \
  -days 365 \
  -extfile <(printf "subjectAltName=DNS:localhost,DNS:*.localhost,IP:127.0.0.1")

# Set proper permissions
chmod 600 nginx/ssl/localhost.key
chmod 644 nginx/ssl/localhost.crt

echo ""
echo "✅ HTTPS certificates created in nginx/ssl/ directory"

# Add to macOS keychain
echo ""
echo "🔐 Adding certificate to macOS keychain..."
if sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain nginx/ssl/localhost.crt; then
    echo "✅ Certificate added to macOS keychain and trusted"
else
    echo "⚠️  Could not add to keychain automatically. You may need to:"
    echo "   1. Open Keychain Access"
    echo "   2. Import nginx/ssl/localhost.crt"
    echo "   3. Double-click the certificate and set 'Always Trust'"
fi

echo ""
echo "🚀 Next steps:"
echo "1. Restart nginx container: docker compose restart nginx"
echo "2. Access https://localhost in your browser"
echo "3. Add https://localhost to OAuth redirect URIs if using OAuth"