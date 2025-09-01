#!/bin/bash
# CSFrace Scrape - Initial Setup Script
# Sets up development environment and validates configuration

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Git
    if ! command -v git &> /dev/null; then
        log_error "Git is required but not installed"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is required but not installed"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is required but not installed"
        exit 1
    fi
    
    log_success "All prerequisites are installed"
}

# Initialize submodules
setup_submodules() {
    log_info "Setting up git submodules..."
    
    if [ ! -d "backend/.git" ] || [ ! -d "frontend/.git" ]; then
        log_info "Initializing submodules..."
        git submodule update --init --recursive
    else
        log_info "Updating existing submodules..."
        git submodule update --remote --merge
    fi
    
    log_success "Submodules are ready"
}

# Setup environment
setup_environment() {
    log_info "Setting up environment configuration..."
    
    if [ ! -f ".env" ]; then
        log_info "Creating .env from template..."
        cp .env.example .env
        log_warning "Please review and customize .env file before starting services"
    else
        log_info ".env file already exists"
    fi
    
    # Create development directories
    mkdir -p dev-output dev-logs dev-backups
    
    log_success "Environment setup complete"
}

# Validate configuration
validate_config() {
    log_info "Validating Docker Compose configuration..."
    
    # Validate production config
    if docker-compose -f docker-compose.yml config --quiet; then
        log_success "Production configuration is valid"
    else
        log_error "Production configuration has errors"
        exit 1
    fi
    
    # Validate development config
    if docker-compose -f docker-compose.dev.yml config --quiet; then
        log_success "Development configuration is valid"
    else
        log_error "Development configuration has errors"
        exit 1
    fi
}

# Build and test services
test_services() {
    log_info "Testing service startup..."
    
    # Start core services
    log_info "Starting core services (postgres, redis)..."
    docker-compose -f docker-compose.dev.yml up -d postgres-dev redis-dev
    
    # Wait for health checks
    log_info "Waiting for services to be healthy..."
    timeout 60s bash -c 'until docker-compose -f docker-compose.dev.yml ps | grep -E "(postgres-dev|redis-dev)" | grep -q "healthy"; do sleep 5; done'
    
    # Test connectivity
    log_info "Testing service connectivity..."
    docker-compose -f docker-compose.dev.yml exec -T postgres-dev pg_isready -U postgres
    docker-compose -f docker-compose.dev.yml exec -T redis-dev redis-cli ping
    
    # Cleanup
    log_info "Cleaning up test services..."
    docker-compose -f docker-compose.dev.yml down
    
    log_success "Service integration test passed"
}

# Main setup function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   CSFrace Scrape Setup                      ║"
    echo "║                  Wrapper Orchestration                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_prerequisites
    setup_submodules
    setup_environment
    validate_config
    
    # Ask if user wants to test services
    read -p "Would you like to test service startup? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        test_services
    fi
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                     Setup Complete!                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log_info "Next steps:"
    echo "  1. Review and customize .env file"
    echo "  2. Start development environment: docker-compose -f docker-compose.dev.yml up -d"
    echo "  3. Access services:"
    echo "     - Frontend: http://localhost:3000"
    echo "     - Backend: http://localhost:8000"
    echo "     - Grafana: http://localhost:3001 (admin/admin)"
    echo "  4. View logs: docker-compose -f docker-compose.dev.yml logs -f"
}

# Run main function
main "$@"