#!/bin/bash
# CSFrace Scrape - Health Check Script
# Verifies all services are running and healthy

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
TIMEOUT=30
RETRY_INTERVAL=2

# Service configurations
declare -A SERVICES=(
    ["backend"]="http://localhost:8000/health"
    ["frontend"]="http://localhost:3000/"
    ["prometheus"]="http://localhost:9090/-/healthy"
    ["grafana"]="http://localhost:3001/api/health"
)

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if service is healthy
check_service_health() {
    local service=$1
    local url=$2
    local start_time=$(date +%s)
    
    log_info "Checking $service health at $url..."
    
    while true; do
        if curl -sf "$url" > /dev/null 2>&1; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            log_success "$service is healthy (${duration}s)"
            return 0
        fi
        
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -ge $TIMEOUT ]; then
            log_error "$service health check failed after ${TIMEOUT}s"
            return 1
        fi
        
        sleep $RETRY_INTERVAL
    done
}

# Check Docker services
check_docker_services() {
    log_info "Checking Docker service status..."
    
    # Get running services
    local running_services=$(docker compose ps --services --filter "status=running")
    
    if [ -z "$running_services" ]; then
        log_error "No services are running"
        return 1
    fi
    
    echo "Running services:"
    echo "$running_services" | while read service; do
        local status=$(docker compose ps "$service" --format "table {{.State}}" | tail -n +2)
        if [[ "$status" == *"healthy"* ]] || [[ "$status" == *"running"* ]]; then
            log_success "  ✅ $service: $status"
        else
            log_warning "  ⚠️  $service: $status"
        fi
    done
}

# Check service endpoints
check_service_endpoints() {
    log_info "Checking service endpoints..."
    
    local failed_services=()
    
    for service in "${!SERVICES[@]}"; do
        local url="${SERVICES[$service]}"
        if ! check_service_health "$service" "$url"; then
            failed_services+=("$service")
        fi
    done
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        log_error "Failed services: ${failed_services[*]}"
        return 1
    fi
    
    log_success "All service endpoints are healthy"
}

# Check database connectivity
check_database() {
    log_info "Checking database connectivity..."
    
    if docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
        log_success "PostgreSQL is ready"
    else
        log_error "PostgreSQL is not ready"
        return 1
    fi
    
    # Test actual connection
    if docker compose exec -T postgres psql -U postgres -d csfrace -c "SELECT 1;" > /dev/null 2>&1; then
        log_success "Database connection test passed"
    else
        log_error "Database connection test failed"
        return 1
    fi
}

# Check cache connectivity
check_cache() {
    log_info "Checking Redis cache connectivity..."
    
    if docker compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        log_success "Redis is responding"
    else
        log_error "Redis is not responding"
        return 1
    fi
    
    # Test cache operations
    if docker compose exec -T redis redis-cli set health_check "$(date)" > /dev/null 2>&1; then
        log_success "Redis write test passed"
        docker compose exec -T redis redis-cli del health_check > /dev/null 2>&1
    else
        log_error "Redis write test failed"
        return 1
    fi
}

# Display service status summary
show_status_summary() {
    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    Service Status Summary                   ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    # Show Docker compose status
    docker compose ps
    
    echo
    log_info "Quick access URLs:"
    echo "  🌐 Frontend:   http://localhost:3000"
    echo "  🔧 Backend:    http://localhost:8000"
    echo "  📊 Grafana:    http://localhost:3001 (admin/admin)"
    echo "  📈 Prometheus: http://localhost:9090"
    echo "  🗄️  pgAdmin:    http://localhost:8080 (admin@csfrace.local/admin)"
    echo "  📮 Redis UI:   http://localhost:8081 (admin/admin)"
}

# Main function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  CSFrace Health Check                       ║"
    echo "║                 Wrapper Orchestration                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    local overall_status=0
    
    # Run all health checks
    check_docker_services || overall_status=1
    check_database || overall_status=1
    check_cache || overall_status=1
    check_service_endpoints || overall_status=1
    
    # Show summary
    show_status_summary
    
    echo
    if [ $overall_status -eq 0 ]; then
        log_success "🎉 All health checks passed!"
        exit 0
    else
        log_error "❌ Some health checks failed"
        echo
        log_info "Troubleshooting tips:"
        echo "  • Check logs: docker compose logs -f"
        echo "  • Restart services: docker compose restart"
        echo "  • Full reset: docker compose down -v && docker compose up -d"
        exit 1
    fi
}

# Handle script arguments
case "${1:-help}" in
    "help"|"-h"|"--help")
        echo "Usage: $0 [option]"
        echo "Options:"
        echo "  help          Show this help message"
        echo "  quick         Quick health check (endpoints only)"
        echo "  full          Full health check (default)"
        echo "  services      Check Docker services only"
        echo "  endpoints     Check service endpoints only"
        ;;
    "quick")
        check_service_endpoints
        ;;
    "services")
        check_docker_services
        ;;
    "endpoints")
        check_service_endpoints
        ;;
    "full"|*)
        main
        ;;
esac