# Contributing to CSFrace Scrape Wrapper

Thank you for your interest in contributing to the CSFrace Scrape project! This document provides guidelines for contributing to the **wrapper orchestration** repository.

## 🏗️ Project Structure

This repository orchestrates multiple components:

```
csfrace-scrape/                     # This wrapper repository  
├── backend/                        # Submodule: csfrace-scrape-back
├── frontend/                       # Submodule: csfrace-scrape-front  
├── docker compose*.yml             # Service orchestration
├── monitoring/                     # Grafana/Prometheus config
└── scripts/                        # Automation scripts
```

## 🎯 Contribution Areas

### Wrapper Repository (You're Here!)
- **Docker Compose orchestration**
- **Environment management**
- **Service networking configuration** 
- **Monitoring setup (Prometheus/Grafana)**
- **Deployment automation**
- **Documentation**

### Component Repositories
- **Backend Issues**: [csfrace-scrape-back](https://github.com/zachatkinson/csfrace-scrape-back/blob/master/CONTRIBUTING.md)
- **Frontend Issues**: [csfrace-scrape-front](https://github.com/zachatkinson/csfrace-scrape-front/blob/master/CONTRIBUTING.md)

## 🚀 Getting Started

### Prerequisites
```bash
# Required tools
git --version          # Git 2.30+
docker --version       # Docker 20.10+
docker compose --version  # Docker Compose 2.0+
```

### Initial Setup
```bash
# 1. Fork and clone with submodules
git clone --recurse-submodules https://github.com/YOUR_USERNAME/csfrace-scrape.git
cd csfrace-scrape

# 2. Set up environment
cp .env.example .env
# Edit .env with your preferences

# 3. Start development environment
docker compose -f docker compose.dev.yml up -d

# 4. Verify all services are healthy
docker compose ps
curl http://localhost:8000/health  # Backend
curl http://localhost:3000/        # Frontend
```

## 📋 Development Workflow

### 1. Create Feature Branch
```bash
# Update main and submodules first
git checkout main
git pull origin main
git submodule update --remote --merge

# Create feature branch
git checkout -b feature/your-feature-name
```

### 2. Make Changes
Focus on **orchestration concerns only**:
- Docker Compose configuration
- Environment variable management
- Service networking
- Monitoring configuration
- Documentation updates

**⚠️ Don't modify submodule code directly!**
- Make backend changes in the [backend repository](https://github.com/zachatkinson/csfrace-scrape-back)
- Make frontend changes in the [frontend repository](https://github.com/zachatkinson/csfrace-scrape-front)

### 3. Test Your Changes
```bash
# Test service startup
docker compose down -v
docker compose -f docker compose.dev.yml up -d

# Verify health checks
scripts/health-check.sh

# Test integration
scripts/test-integration.sh

# Check monitoring
open http://localhost:3001  # Grafana
open http://localhost:9090  # Prometheus
```

### 4. Update Documentation
- **README.md**: Update setup instructions if needed
- **.env.example**: Add new environment variables
- **CLAUDE.md**: Update standards if applicable
- **Inline comments**: Document complex configurations

### 5. Submit Pull Request
Follow the [Pull Request Template](.github/pull_request_template.md) checklist.

## 🛠️ Wrapper-Specific Standards

### Docker Compose Best Practices
```yaml
# ✅ Good: Explicit service configuration
services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    environment:
      - DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
    depends_on:
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
    networks:
      - app-network

# ❌ Bad: Hardcoded values, no health checks
services:
  backend:
    build: ./backend
    environment:
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/mydb
    depends_on:
      - postgres
```

### Environment Variable Management
```bash
# ✅ Good: Descriptive names with defaults
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=${POSTGRES_DB:-csfrace}
BACKEND_LOG_LEVEL=${BACKEND_LOG_LEVEL:-INFO}

# ❌ Bad: Unclear names, no defaults
DB_HOST=postgres
PORT=5432
DB=mydb
LOG=info
```

### Service Networking
```yaml
# ✅ Good: Explicit networks, internal communication
networks:
  app-network:
    driver: bridge

services:
  backend:
    networks:
      - app-network
    # Don't expose port if only used internally
  
  frontend:
    ports:
      - "3000:3000"  # Only expose what users need
    networks:
      - app-network
```

## 🧪 Testing Guidelines

### Pre-Submission Testing
```bash
# 1. Full environment test
docker compose down -v && docker compose up -d
# Wait for all services to be healthy

# 2. Integration test
curl http://localhost:3000/api/test-backend-connection
curl http://localhost:8000/health

# 3. Monitoring test
curl http://localhost:9090/-/healthy  # Prometheus
curl http://localhost:3001/api/health # Grafana

# 4. Cleanup test
docker compose down
docker system prune -f
```

### Testing Checklist
- [ ] All services start successfully
- [ ] Health checks pass for all services
- [ ] Frontend can reach backend API
- [ ] Database connections work
- [ ] Redis cache is accessible
- [ ] Monitoring dashboards load
- [ ] Logs are properly structured
- [ ] Service restart works correctly
- [ ] Clean shutdown works

## 📝 Commit Standards

### Commit Message Format
```
type(scope): brief description

Longer description if needed

Closes #123
```

### Types
- **feat**: New orchestration feature
- **fix**: Bug fix in configuration
- **docs**: Documentation updates
- **chore**: Submodule updates, maintenance
- **refactor**: Configuration refactoring
- **perf**: Performance improvements

### Scopes
- **docker**: Docker Compose changes
- **env**: Environment configuration
- **monitoring**: Prometheus/Grafana setup
- **network**: Service networking
- **docs**: Documentation updates
- **scripts**: Automation scripts

### Examples
```bash
git commit -m "feat(docker): add Redis service with health checks"
git commit -m "fix(env): correct PostgreSQL connection string template"
git commit -m "docs(readme): update setup instructions for new services"
git commit -m "chore(submodules): update backend and frontend to latest"
```

## 🐛 Bug Reports & Feature Requests

### Bug Reports
Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.yml):
- **Component**: Which wrapper component is affected
- **Environment**: Your development setup
- **Reproduction**: Clear steps to reproduce
- **Logs**: Relevant Docker/service logs

### Feature Requests  
Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.yml):
- **Category**: Type of wrapper enhancement
- **Problem**: Current limitation
- **Solution**: Proposed improvement
- **Priority**: Impact on workflow

## 🔧 Common Tasks

### Adding a New Service
```bash
# 1. Add service to docker compose.yml
services:
  new-service:
    image: service:latest
    environment:
      - CONFIG_VAR=${CONFIG_VAR:-default}
    healthcheck:
      test: ["CMD", "service-health-check"]
    networks:
      - app-network

# 2. Add environment variables to .env.example
CONFIG_VAR=default_value
NEW_SERVICE_PORT=8080

# 3. Update documentation
# - README.md: Add service description
# - Add monitoring configuration if needed

# 4. Test integration
docker compose up -d new-service
```

### Updating Submodules
```bash
# Update to latest versions
git submodule update --remote --merge

# Update to specific commits (for releases)
cd backend && git checkout v1.2.0
cd ../frontend && git checkout v1.1.0
cd .. && git add . && git commit -m "chore(submodules): pin to release versions"
```

### Adding Monitoring
```yaml
# monitoring/prometheus.yml
scrape_configs:
  - job_name: 'new-service'
    static_configs:
      - targets: ['new-service:8080']
    scrape_interval: 15s
    metrics_path: /metrics
```

## 🎯 Review Process

### Pull Request Review
1. **Automated checks**: All services must start successfully
2. **Manual review**: Code quality and documentation
3. **Integration test**: Full environment verification
4. **Documentation review**: Ensure updates are complete

### Reviewer Responsibilities
- ✅ Verify all services start and are healthy
- ✅ Check environment variable templating
- ✅ Validate service networking configuration
- ✅ Ensure proper resource limits and restart policies
- ✅ Review monitoring configuration
- ✅ Confirm documentation is updated

## 📞 Getting Help

- **Questions**: [GitHub Discussions](https://github.com/zachatkinson/csfrace-scrape/discussions)
- **Wrapper Issues**: [Open an issue](https://github.com/zachatkinson/csfrace-scrape/issues/new/choose)
- **Component Issues**: See component repository links above
- **Documentation**: [Project Wiki](https://github.com/zachatkinson/csfrace-scrape/wiki)

## 🏆 Recognition

Contributors will be recognized in:
- Repository README.md
- Release notes for significant contributions
- GitHub contributor statistics

Thank you for helping make CSFrace Scrape better! 🚀