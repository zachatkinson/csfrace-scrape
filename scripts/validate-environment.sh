#!/bin/bash
# =============================================================================
# Environment Configuration Validator
# =============================================================================
# SOLID Principles Implementation:
# - Single Responsibility: Validates environment configuration
# - Open/Closed: Extensible validation rules without modifying core logic
# - DRY: Centralized validation logic
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env.dev"

echo -e "${BLUE}🔍 CSFrace Environment Configuration Validator${NC}"
echo -e "${BLUE}===============================================${NC}"

# =============================================================================
# VALIDATION FUNCTIONS (Single Responsibility)
# =============================================================================

validate_file_exists() {
    local file_path="$1"
    local description="$2"
    
    if [[ -f "$file_path" ]]; then
        echo -e "${GREEN}✅ $description exists: $file_path${NC}"
        return 0
    else
        echo -e "${RED}❌ $description missing: $file_path${NC}"
        return 1
    fi
}

validate_env_var() {
    local var_name="$1"
    local description="$2"
    local required="${3:-true}"
    
    if [[ -n "${!var_name:-}" ]]; then
        echo -e "${GREEN}✅ $description: ${!var_name}${NC}"
        return 0
    elif [[ "$required" == "true" ]]; then
        echo -e "${RED}❌ $description missing: $var_name${NC}"
        return 1
    else
        echo -e "${YELLOW}⚠️  $description optional: $var_name (not set)${NC}"
        return 0
    fi
}

validate_database_url() {
    local db_url="${DATABASE_URL:-}"
    local expected_db="${POSTGRES_DB:-}"
    
    if [[ "$db_url" == *"/$expected_db"* ]]; then
        echo -e "${GREEN}✅ Database URL matches database name${NC}"
        return 0
    else
        echo -e "${RED}❌ Database URL mismatch: Expected '$expected_db' in '$db_url'${NC}"
        return 1
    fi
}

validate_redis_url() {
    local redis_url="${REDIS_URL:-}"
    local expected_host="${REDIS_HOST:-}"
    local expected_port="${REDIS_PORT:-}"
    
    if [[ "$redis_url" == *"$expected_host:$expected_port"* ]]; then
        echo -e "${GREEN}✅ Redis URL matches host:port configuration${NC}"
        return 0
    else
        echo -e "${RED}❌ Redis URL mismatch: Expected '$expected_host:$expected_port' in '$redis_url'${NC}"
        return 1
    fi
}

validate_cors_origins() {
    local cors_origins="${CORS_ORIGINS:-}"
    local frontend_port="${FRONTEND_PORT:-}"
    local grafana_port="${GRAFANA_PORT:-}"
    
    local errors=0
    
    if [[ "$cors_origins" == *"localhost:$frontend_port"* ]]; then
        echo -e "${GREEN}✅ CORS includes frontend port $frontend_port${NC}"
    else
        echo -e "${RED}❌ CORS missing frontend port: localhost:$frontend_port${NC}"
        ((errors++))
    fi
    
    if [[ "$cors_origins" == *"localhost:$grafana_port"* ]]; then
        echo -e "${GREEN}✅ CORS includes Grafana port $grafana_port${NC}"
    else
        echo -e "${RED}❌ CORS missing Grafana port: localhost:$grafana_port${NC}"
        ((errors++))
    fi
    
    return $errors
}

validate_port_conflicts() {
    local ports=("$@")
    local seen_ports=""
    local conflicts=""
    
    # Check for duplicate ports
    for port in "${ports[@]}"; do
        if [[ "$seen_ports" == *" $port "* ]]; then
            conflicts="$conflicts $port"
        else
            seen_ports="$seen_ports $port "
        fi
    done
    
    if [[ -z "$conflicts" ]]; then
        echo -e "${GREEN}✅ No port conflicts detected${NC}"
        return 0
    else
        echo -e "${RED}❌ Port conflicts detected:$conflicts${NC}"
        return 1
    fi
}

# =============================================================================
# MAIN VALIDATION LOGIC (Open/Closed Principle)
# =============================================================================

main() {
    local validation_errors=0
    
    echo -e "${BLUE}📋 Step 1: File Existence Validation${NC}"
    validate_file_exists "$ENV_FILE" "Environment file" || ((validation_errors++))
    validate_file_exists "$PROJECT_ROOT/docker-compose.dev.yml" "Development compose file" || ((validation_errors++))
    
    echo -e "\n${BLUE}📋 Step 2: Loading Environment Configuration${NC}"
    if [[ -f "$ENV_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$ENV_FILE"
        echo -e "${GREEN}✅ Environment file loaded${NC}"
    else
        echo -e "${RED}❌ Cannot proceed without environment file${NC}"
        exit 1
    fi
    
    echo -e "\n${BLUE}📋 Step 3: Core Configuration Validation${NC}"
    validate_env_var "ENVIRONMENT" "Environment type" || ((validation_errors++))
    validate_env_var "COMPOSE_PROJECT_NAME" "Compose project name" || ((validation_errors++))
    
    echo -e "\n${BLUE}📋 Step 4: Database Configuration Validation${NC}"
    validate_env_var "POSTGRES_HOST" "PostgreSQL host" || ((validation_errors++))
    validate_env_var "POSTGRES_PORT" "PostgreSQL port" || ((validation_errors++))
    validate_env_var "POSTGRES_DB" "PostgreSQL database name" || ((validation_errors++))
    validate_env_var "POSTGRES_USER" "PostgreSQL user" || ((validation_errors++))
    validate_env_var "DATABASE_URL" "Database URL" || ((validation_errors++))
    validate_database_url || ((validation_errors++))
    
    echo -e "\n${BLUE}📋 Step 5: Redis Configuration Validation${NC}"
    validate_env_var "REDIS_HOST" "Redis host" || ((validation_errors++))
    validate_env_var "REDIS_PORT" "Redis port" || ((validation_errors++))
    validate_env_var "REDIS_URL" "Redis URL" || ((validation_errors++))
    validate_redis_url || ((validation_errors++))
    
    echo -e "\n${BLUE}📋 Step 6: Service Configuration Validation${NC}"
    validate_env_var "BACKEND_PORT" "Backend port" || ((validation_errors++))
    validate_env_var "FRONTEND_PORT" "Frontend port" || ((validation_errors++))
    validate_env_var "GRAFANA_PORT" "Grafana port" || ((validation_errors++))
    validate_env_var "PROMETHEUS_PORT" "Prometheus port" || ((validation_errors++))
    
    echo -e "\n${BLUE}📋 Step 7: Network Configuration Validation${NC}"
    validate_env_var "CORS_ORIGINS" "CORS origins" || ((validation_errors++))
    validate_cors_origins || ((validation_errors++))
    
    echo -e "\n${BLUE}📋 Step 8: Port Conflict Detection${NC}"
    local all_ports=(
        "${BACKEND_PORT:-8000}"
        "${FRONTEND_PORT:-3000}" 
        "${GRAFANA_PORT:-3001}"
        "${PROMETHEUS_PORT:-9090}"
        "${POSTGRES_PORT:-5432}"
        "${REDIS_PORT:-6379}"
    )
    validate_port_conflicts "${all_ports[@]}" || ((validation_errors++))
    
    echo -e "\n${BLUE}📋 Step 9: Security Configuration Validation${NC}"
    validate_env_var "SECRET_KEY" "Backend secret key" || ((validation_errors++))
    if [[ "${SECRET_KEY:-}" == *"change-in-production"* && "${ENVIRONMENT}" != "development" ]]; then
        echo -e "${RED}❌ Using development secret key in ${ENVIRONMENT} environment${NC}"
        ((validation_errors++))
    else
        echo -e "${GREEN}✅ Secret key appropriate for ${ENVIRONMENT} environment${NC}"
    fi
    
    # =============================================================================
    # FINAL RESULTS
    # =============================================================================
    
    echo -e "\n${BLUE}===============================================${NC}"
    if [[ $validation_errors -eq 0 ]]; then
        echo -e "${GREEN}🎉 All validations passed! Environment is properly configured.${NC}"
        echo -e "${GREEN}✅ Ready to start development services${NC}"
        exit 0
    else
        echo -e "${RED}❌ $validation_errors validation error(s) found${NC}"
        echo -e "${YELLOW}💡 Please fix the issues above before starting services${NC}"
        exit 1
    fi
}

# Run main function
main "$@"