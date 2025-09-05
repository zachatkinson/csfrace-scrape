# Claude Code Best Practices - CSFrace Scrape Wrapper

## Project Overview
This repository serves as the orchestration wrapper for the CSFrace scraping application, coordinating between the backend scraper (`csfrace-scrape-back`) and frontend interface (`csfrace-scrape-front`). It provides Docker orchestration, environment management, and deployment coordination.

## Architecture Overview
```
csfrace-scrape/                    # This wrapper repository
├── docker compose.yml             # Multi-service orchestration
├── docker compose.dev.yml         # Development environment
├── docker compose.prod.yml        # Production environment
├── .env.example                   # Environment template
├── .gitignore                     # Wrapper-level ignores
├── README.md                      # Overall project documentation
├── scripts/                       # Orchestration scripts
├── backend/                       # Git submodule: csfrace-scrape-back
└── frontend/                      # Git submodule: csfrace-scrape-front
```

## MANDATORY Wrapper-Specific Standards

### 1. Git Submodule Management (MANDATORY)
**All submodule operations must follow these strict patterns:**

```bash
# Initial setup
git submodule add https://github.com/zachatkinson/csfrace-scrape-back.git backend
git submodule add https://github.com/zachatkinson/csfrace-scrape-front.git frontend

# Clone with submodules
git clone --recurse-submodules https://github.com/zachatkinson/csfrace-scrape.git

# Update submodules
git submodule update --remote --merge

# Working with submodule changes
cd backend && git checkout main && git pull
cd ../frontend && git checkout main && git pull
cd .. && git add . && git commit -m "chore: update submodules"
```

**Submodule Best Practices:**
- **NEVER commit submodule changes without explicit intent**
- **ALWAYS use `--recurse-submodules` for clones**
- **Document submodule update procedures in README**
- **Pin submodules to specific commits for releases**

### 2. Environment Orchestration (MANDATORY)
**Centralized environment management across all services:**

```bash
# .env structure (MANDATORY)
# Global Configuration
COMPOSE_PROJECT_NAME=csfrace-scrape
ENVIRONMENT=development  # development|staging|production

# Backend Configuration  
BACKEND_PORT=8000
BACKEND_LOG_LEVEL=INFO
SCRAPER_CONCURRENT_REQUESTS=10

# Frontend Configuration
FRONTEND_PORT=3000
FRONTEND_API_URL=http://backend:8000

# Shared Services
REDIS_URL=redis://redis:6379
POSTGRES_URL=postgresql://postgres:password@postgres:5432/csfrace
```

### 3. Docker Orchestration Standards (MANDATORY)
**Multi-service coordination with proper networking and dependencies:**

**Service Dependencies (MANDATORY):**
```yaml
# docker compose.yml
version: '3.8'

networks:
  csfrace-network:
    driver: bridge

volumes:
  postgres-data:
  redis-data:

services:
  backend:
    build: ./backend
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - csfrace-network
    
  frontend:
    build: ./frontend
    depends_on:
      - backend
    networks:
      - csfrace-network
    
  postgres:
    image: postgres:15
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - csfrace-network
      
  redis:
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - csfrace-network
```

### 4. Development Workflow (MANDATORY)
**Coordinated development across repositories:**

```bash
# Development Commands (MANDATORY)
# Start development environment
docker compose -f docker compose.dev.yml up -d

# View logs across all services
docker compose logs -f

# Scale services
docker compose up -d --scale backend=2 --scale frontend=2

# Execute commands in running services
docker compose exec backend uv run python -m pytest
docker compose exec frontend npm test

# Rebuild specific service
docker compose build --no-cache backend
```

### 5. Cross-Repository Standards (MANDATORY)
**Standards that must be consistent across both frontend and backend:**

#### Shared Coding Standards:
- **SOLID Principles**: All repositories must follow SOLID design principles
- **DRY Principle**: No code duplication within or across repositories
- **Zero Technical Debt Policy**: Address technical debt immediately
- **Environment Variables**: All configuration via environment variables
- **Structured Logging**: Consistent log formats across services
- **Error Handling**: Comprehensive error handling and user feedback
- **Security**: Input validation, sanitization, and secure defaults

#### Shared Quality Gates:
- **Pre-commit Hooks**: All repositories must have pre-commit hooks
- **Code Coverage**: Minimum coverage thresholds per repository
- **Security Scanning**: Automated vulnerability scanning
- **Dependency Updates**: Coordinated dependency management
- **API Contracts**: Versioned API contracts between services

### 6. Deployment Coordination (MANDATORY)
**Multi-service deployment orchestration:**

```bash
# Production Deployment (MANDATORY)
# Build production images
docker compose -f docker compose.prod.yml build

# Deploy with proper health checks
docker compose -f docker compose.prod.yml up -d

# Verify deployment health
scripts/health-check.sh

# Rolling updates
scripts/rolling-update.sh backend
scripts/rolling-update.sh frontend
```

### 7. API Contract Management (MANDATORY)
**Ensure frontend/backend compatibility:**

```typescript
// Shared API types (maintained in wrapper)
interface ScrapingRequest {
  url: string;
  options: {
    format: 'html' | 'markdown' | 'json';
    includeImages: boolean;
    timeout: number;
  };
}

interface ScrapingResponse {
  success: boolean;
  data?: {
    content: string;
    metadata: Record<string, any>;
  };
  error?: string;
}
```

### 8. Monitoring and Observability (MANDATORY)
**Coordinated monitoring across all services:**

```yaml
# Monitoring stack in docker compose.monitoring.yml
services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
  
  grafana:
    image: grafana/grafana:latest
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    ports:
      - "3001:3000"
    volumes:
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards
```

### 9. Documentation Standards (MANDATORY)
**Wrapper-level documentation requirements:**

- **README.md**: Overall project setup and architecture
- **SETUP.md**: Detailed setup instructions for all environments
- **API.md**: API contracts and integration patterns
- **DEPLOYMENT.md**: Production deployment procedures
- **TROUBLESHOOTING.md**: Common issues and solutions

### 10. CI/CD Coordination (MANDATORY)
**Orchestrated CI/CD across repositories:**

```yaml
# .github/workflows/integration.yml
name: Integration Tests

on:
  push:
    paths:
      - 'backend/**'
      - 'frontend/**'
      - 'docker compose*.yml'

jobs:
  integration-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive
      
      - name: Start services
        run: docker compose -f docker compose.test.yml up -d
      
      - name: Run integration tests
        run: |
          # Wait for services to be ready
          scripts/wait-for-services.sh
          
          # Run cross-service integration tests
          docker compose exec backend pytest tests/integration/
          docker compose exec frontend npm run test:integration
          
          # Run end-to-end tests
          docker compose exec e2e-tests npm run test:e2e
```

## Repository-Specific Rules

### Backend Repository Rules
- Individual repository maintains its own CLAUDE.md for Python/scraping-specific standards
- Backend handles: API development, scraping logic, data processing
- Must expose health endpoints for orchestration
- Must implement graceful shutdown handling

### Frontend Repository Rules  
- Individual repository maintains its own CLAUDE.md for React/TypeScript standards
- Frontend handles: UI components, user interactions, data visualization
- Must implement proper error boundaries
- Must handle backend unavailability gracefully

### Wrapper Repository Rules (This Repository)
- **NEVER contain application logic** - only orchestration
- **Coordinate deployments** across all services
- **Manage shared configurations** and secrets
- **Document overall architecture** and setup procedures
- **Implement end-to-end testing** across services

## Quality Checklist for Wrapper Repository
Before committing wrapper changes:
- [ ] All submodules are updated and committed
- [ ] Environment variables are documented and templated
- [ ] Docker compose files are valid and tested
- [ ] Health checks are implemented for all services
- [ ] README is updated with any architectural changes
- [ ] Integration tests pass across all services
- [ ] Deployment scripts are tested
- [ ] Monitoring dashboards reflect any new services

## Development Commands Reference

```bash
# Wrapper Development (MANDATORY commands)
# Initial setup
git clone --recurse-submodules https://github.com/zachatkinson/csfrace-scrape.git
cd csfrace-scrape
cp .env.example .env

# Start development environment
docker compose -f docker compose.dev.yml up -d

# View service logs
docker compose logs -f backend
docker compose logs -f frontend

# Update submodules
git submodule update --remote --merge

# Health check all services
curl http://localhost:8000/health  # Backend health
curl http://localhost:3000/        # Frontend health

# Stop all services
docker compose down

# Clean rebuild
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

This wrapper CLAUDE.md focuses on orchestration concerns while letting each repository maintain its own specific development standards.