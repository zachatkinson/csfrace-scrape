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

# Create SSL certificates for nginx (required before starting containers)
echo "🔒 Setting up HTTPS certificates..."
SSL_DIR="nginx/ssl"
mkdir -p "$SSL_DIR"

# Check if certificates already exist and are valid
CERTS_EXIST=false
CERTS_VALID=false

if [ -f "$SSL_DIR/localhost.crt" ] && [ -f "$SSL_DIR/localhost.key" ]; then
    CERTS_EXIST=true

    # Check certificate expiration (macOS uses different date command)
    if command -v openssl &> /dev/null; then
        EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$SSL_DIR/localhost.crt" 2>/dev/null | cut -d= -f2)
        if [ -n "$EXPIRY_DATE" ]; then
            # Convert to epoch time for comparison
            if date -j -f "%b %d %T %Y %Z" "$EXPIRY_DATE" "+%s" &> /dev/null; then
                EXPIRY_EPOCH=$(date -j -f "%b %d %T %Y %Z" "$EXPIRY_DATE" "+%s")
                CURRENT_EPOCH=$(date "+%s")
                DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))

                if [ $DAYS_UNTIL_EXPIRY -gt 30 ]; then
                    CERTS_VALID=true
                    echo "✅ Valid SSL certificates found (expires in $DAYS_UNTIL_EXPIRY days)"
                else
                    echo "⚠️  SSL certificates expire soon ($DAYS_UNTIL_EXPIRY days) - regenerating..."
                fi
            fi
        fi
    fi
fi

if [ "$CERTS_VALID" = false ]; then
    # Check if OpenSSL is available
    if ! command -v openssl &> /dev/null; then
        echo "❌ OpenSSL not found - required for HTTPS certificates"
        echo ""
        echo "Install OpenSSL:"
        echo "  brew install openssl"
        echo ""
        echo "After installing OpenSSL, run this script again."
        exit 1
    fi

    echo "📝 Generating SSL certificates..."

    # Generate private key
    openssl genrsa -out "$SSL_DIR/localhost.key" 2048 2>/dev/null

    # Create certificate config
    cat > "$SSL_DIR/localhost.cnf" <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=US
ST=CA
L=SF
O=Dev
CN=localhost

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
IP.1 = 127.0.0.1
EOF

    # Create certificate signing request
    openssl req -new -key "$SSL_DIR/localhost.key" \
        -out "$SSL_DIR/localhost.csr" \
        -config "$SSL_DIR/localhost.cnf" 2>/dev/null

    # Generate self-signed certificate
    openssl x509 -req \
        -in "$SSL_DIR/localhost.csr" \
        -signkey "$SSL_DIR/localhost.key" \
        -out "$SSL_DIR/localhost.crt" \
        -days 365 \
        -extensions v3_req \
        -extfile "$SSL_DIR/localhost.cnf" 2>/dev/null

    # Clean up temporary files
    rm -f "$SSL_DIR/localhost.cnf" "$SSL_DIR/localhost.csr"

    echo "✅ SSL certificates generated"

    # Try to add to macOS keychain (may require user interaction)
    if command -v security &> /dev/null; then
        echo "ℹ️  To trust the certificate in your browser, you can add it to your keychain:"
        echo "   sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $SSL_DIR/localhost.crt"
    fi
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
echo "   Frontend:    https://localhost (recommended)"
echo "   Backend API: https://localhost/api"
echo "   API Docs:    https://localhost/docs"
echo "   Grafana:     http://localhost:3001 (admin/admin)"
echo "   Prometheus:  http://localhost:9090"
echo ""

if [ "$CERTS_VALID" = true ]; then
    echo "🔒 HTTPS is configured and ready to use!"
else
    echo "🔒 HTTPS certificates generated"
    echo "   Note: Your browser may show a security warning for self-signed certificates"
fi

echo ""
echo "🎉 Ready to use!"
