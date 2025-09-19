#!/bin/bash
# Service Readiness Script for CSFrace Integration Testing
# Waits for all critical services to be healthy before proceeding with tests

set -euo pipefail

# Configuration
BACKEND_URL="${BACKEND_URL:-http://localhost:${BACKEND_PORT:-8001}}"
FRONTEND_URL="${FRONTEND_URL:-http://localhost:${FRONTEND_PORT:-3001}}"
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5433}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-csfrace_test}"
REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6380}"
MAX_WAIT_TIME=300  # 5 minutes
RETRY_INTERVAL=5   # 5 seconds

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Generic wait function
wait_for_service() {
    local service_name="$1"
    local check_command="$2"
    local max_attempts=$((MAX_WAIT_TIME / RETRY_INTERVAL))
    local attempt=1

    log_info "Waiting for $service_name to be ready..."

    while [ $attempt -le $max_attempts ]; do
        if eval "$check_command" >/dev/null 2>&1; then
            log_success "$service_name is ready!"
            return 0
        fi

        log_info "Attempt $attempt/$max_attempts: $service_name not ready yet, waiting ${RETRY_INTERVAL}s..."
        sleep $RETRY_INTERVAL
        attempt=$((attempt + 1))
    done

    log_error "$service_name failed to become ready within ${MAX_WAIT_TIME} seconds"
    return 1
}

# Service-specific health checks
check_postgres() {
    pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB"
}

check_redis() {
    redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping | grep -q "PONG"
}

check_backend() {
    curl -f -s "$BACKEND_URL/health/" | grep -q "healthy"
}

check_frontend() {
    curl -f -s "$FRONTEND_URL/" >/dev/null
}

# Install required tools if not available
install_tools() {
    log_info "Checking for required tools..."

    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        log_warning "curl not found, attempting to install..."
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update && apt-get install -y curl
        elif command -v yum >/dev/null 2>&1; then
            yum install -y curl
        elif command -v apk >/dev/null 2>&1; then
            apk add curl
        else
            log_error "Cannot install curl - package manager not found"
            exit 1
        fi
    fi

    # Check for PostgreSQL client
    if ! command -v pg_isready >/dev/null 2>&1; then
        log_warning "pg_isready not found, attempting to install PostgreSQL client..."
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update && apt-get install -y postgresql-client
        elif command -v yum >/dev/null 2>&1; then
            yum install -y postgresql
        elif command -v apk >/dev/null 2>&1; then
            apk add postgresql-client
        else
            log_error "Cannot install PostgreSQL client - package manager not found"
            exit 1
        fi
    fi

    # Check for Redis client
    if ! command -v redis-cli >/dev/null 2>&1; then
        log_warning "redis-cli not found, attempting to install Redis client..."
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update && apt-get install -y redis-tools
        elif command -v yum >/dev/null 2>&1; then
            yum install -y redis
        elif command -v apk >/dev/null 2>&1; then
            apk add redis
        else
            log_error "Cannot install Redis client - package manager not found"
            exit 1
        fi
    fi

    log_success "All required tools are available"
}

# Main execution
main() {
    log_info "Starting service readiness check for CSFrace integration testing"
    log_info "Configuration:"
    log_info "  Backend URL: $BACKEND_URL"
    log_info "  Frontend URL: $FRONTEND_URL"
    log_info "  PostgreSQL: $POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB"
    log_info "  Redis: $REDIS_HOST:$REDIS_PORT"
    log_info "  Max wait time: ${MAX_WAIT_TIME}s"

    # Install tools if needed
    install_tools

    # Wait for services in dependency order
    log_info "Checking services in dependency order..."

    # Database services first
    wait_for_service "PostgreSQL" "check_postgres" || exit 1
    wait_for_service "Redis" "check_redis" || exit 1

    # Application services
    wait_for_service "Backend API" "check_backend" || exit 1
    wait_for_service "Frontend" "check_frontend" || exit 1

    log_success "All services are ready! Integration testing can proceed."

    # Additional verification
    log_info "Performing additional health checks..."

    # Test database connection
    if command -v psql >/dev/null 2>&1; then
        if PGPASSWORD="test-password" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" >/dev/null 2>&1; then
            log_success "PostgreSQL connection verified"
        else
            log_warning "PostgreSQL connection test failed"
        fi
    fi

    # Test Redis connection
    if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" set test_key "test_value" >/dev/null 2>&1 && \
       redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" get test_key >/dev/null 2>&1 && \
       redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" del test_key >/dev/null 2>&1; then
        log_success "Redis read/write operations verified"
    else
        log_warning "Redis operation test failed"
    fi

    # Test API endpoints
    if curl -f -s "$BACKEND_URL/docs" >/dev/null 2>&1; then
        log_success "Backend API documentation accessible"
    else
        log_warning "Backend API documentation not accessible"
    fi

    log_success "Service readiness check completed successfully!"
}

# Execute main function
main "$@"