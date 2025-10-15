#!/bin/bash
# CSFrace Scrape - Client Setup Script
# This script helps clients get started quickly with Docker Desktop

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main setup
main() {
    echo "========================================"
    echo "  CSFrace Scrape - Client Setup"
    echo "========================================"
    echo ""

    # Check prerequisites
    info "Checking prerequisites..."

    if ! command_exists docker; then
        error "Docker is not installed. Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
    fi

    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running. Please start Docker Desktop and try again."
    fi

    info "✓ Docker is installed and running"

    if ! command_exists git; then
        warn "Git is not installed. You'll need to download the project manually."
    else
        info "✓ Git is installed"
    fi

    echo ""

    # Check if .env exists
    if [ ! -f ".env" ]; then
        info "Creating .env file from template..."
        if [ -f ".env.example" ]; then
            cp .env.example .env
            info "✓ .env file created"
            warn "IMPORTANT: Edit .env file and change default passwords!"
        else
            error ".env.example not found. Are you in the correct directory?"
        fi
    else
        info "✓ .env file already exists"
    fi

    echo ""

    # Generate secrets
    info "Generating secure secrets..."
    if command_exists openssl; then
        SECRET_KEY=$(openssl rand -hex 32)
        POSTGRES_PASSWORD=$(openssl rand -base64 24)

        # Update .env file with generated secrets
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/SECRET_KEY=.*/SECRET_KEY=$SECRET_KEY/" .env
            sed -i '' "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$POSTGRES_PASSWORD/" .env
        else
            # Linux
            sed -i "s/SECRET_KEY=.*/SECRET_KEY=$SECRET_KEY/" .env
            sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$POSTGRES_PASSWORD/" .env
        fi

        info "✓ Generated SECRET_KEY"
        info "✓ Generated POSTGRES_PASSWORD"
    else
        warn "OpenSSL not found. Please manually set SECRET_KEY and POSTGRES_PASSWORD in .env"
    fi

    echo ""

    # Generate SSL certificates
    info "Generating SSL certificates for HTTPS..."
    if [ ! -d "nginx/ssl" ]; then
        mkdir -p nginx/ssl
    fi

    if [ ! -f "nginx/ssl/certificate.crt" ] || [ ! -f "nginx/ssl/private.key" ]; then
        if command_exists openssl; then
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout nginx/ssl/private.key \
                -out nginx/ssl/certificate.crt \
                -subj "/C=US/ST=State/L=City/O=CSFrace/CN=localhost" >/dev/null 2>&1
            info "✓ SSL certificates generated"
        else
            warn "OpenSSL not found. Please manually generate SSL certificates."
        fi
    else
        info "✓ SSL certificates already exist"
    fi

    echo ""

    # Pull/build images
    info "Pulling Docker images (this may take 5-15 minutes on first run)..."
    if docker compose pull >/dev/null 2>&1; then
        info "✓ Docker images pulled"
    else
        warn "Failed to pull some images. Will try to build locally..."
    fi

    info "Building Docker images..."
    if docker compose build >/dev/null 2>&1; then
        info "✓ Docker images built"
    else
        error "Failed to build Docker images. Check logs with: docker compose build"
    fi

    echo ""

    # Start services
    info "Starting services..."
    if docker compose up -d; then
        info "✓ Services started"
    else
        error "Failed to start services. Check logs with: docker compose logs"
    fi

    echo ""

    # Wait for services to be healthy
    info "Waiting for services to become healthy (up to 60 seconds)..."
    sleep 10

    MAX_WAIT=60
    ELAPSED=0
    while [ $ELAPSED -lt $MAX_WAIT ]; do
        HEALTHY_COUNT=$(docker compose ps | grep -c "healthy" || true)
        if [ "$HEALTHY_COUNT" -ge 5 ]; then
            info "✓ All services are healthy"
            break
        fi
        sleep 5
        ELAPSED=$((ELAPSED + 5))
        echo -n "."
    done

    echo ""
    echo ""

    # Final status
    info "Checking service status..."
    docker compose ps

    echo ""
    echo "========================================"
    echo "  Setup Complete!"
    echo "========================================"
    echo ""
    echo "✓ Services are running"
    echo ""
    echo "Access your application:"
    echo "  Main App:    https://localhost"
    echo "  API Docs:    https://localhost/api/docs"
    echo "  Monitoring:  http://localhost:3001"
    echo ""
    echo "Default Credentials:"
    echo "  Application: Register a new account"
    echo "  Grafana:     admin / admin (change on first login)"
    echo ""
    echo "Important Next Steps:"
    echo "  1. Change default passwords in .env file"
    echo "  2. Accept the self-signed SSL certificate in your browser"
    echo "  3. Register your first user account"
    echo "  4. Set up regular backups (see CLIENT_DEPLOYMENT_GUIDE.md)"
    echo ""
    echo "For detailed documentation, see CLIENT_DEPLOYMENT_GUIDE.md"
    echo ""

    # Show logs
    read -p "Would you like to view service logs? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker compose logs -f
    fi
}

# Run main function
main "$@"
