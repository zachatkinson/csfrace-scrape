# CSFrace Scrape - WordPress to Shopify Converter

[![CI/CD Pipeline](https://github.com/zachatkinson/csfrace-scrape/actions/workflows/integration.yml/badge.svg)](https://github.com/zachatkinson/csfrace-scrape/actions/workflows/integration.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Orchestration wrapper for the CSFrace scraping application** - Coordinates between backend scraper and frontend interface.

## 🏗️ Architecture Overview

This repository orchestrates a full-stack web scraping solution:

```
┌─────────────────────────────────────────────────────────┐
│                 CSFrace Scrape Wrapper                 │
│                (This Repository)                       │
├─────────────────────┬───────────────────────────────────┤
│     Frontend        │            Backend                │
│  (React/TypeScript) │      (Python/FastAPI)            │
│                     │                                   │
│  • User Interface   │  • WordPress Scraping            │
│  • Job Management   │  • Content Processing            │
│  • Result Display   │  • Shopify Format Export         │
│                     │  • API Endpoints                  │
└─────────────────────┴───────────────────────────────────┘
         │                           │
         └───────────┬───────────────┘
                     │
         ┌───────────────────────┐
         │   Shared Services     │
         │                       │
         │  • PostgreSQL DB      │
         │  • Redis Cache        │
         │  • Monitoring Stack   │
         └───────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Git with submodule support
- 8GB+ RAM recommended

### 1. Clone with Submodules
```bash
git clone --recurse-submodules https://github.com/zachatkinson/csfrace-scrape.git
cd csfrace-scrape
```

### 2. Environment Setup
```bash
# Copy environment template
cp .env.example .env

# Edit configuration (optional - defaults work for development)
nano .env
```

### 3. Start Development Environment
```bash
# Start all services
docker compose -f docker compose.dev.yml up -d

# View logs
docker compose logs -f
```

### 4. Access Applications
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Monitoring**: http://localhost:3001 (Grafana)

## 📦 Repository Structure

```
csfrace-scrape/                     # This orchestration repository
├── README.md                       # This file
├── CLAUDE.md                       # Development standards
├── docker compose.yml              # Production orchestration
├── docker compose.dev.yml          # Development environment
├── .env.example                    # Environment template
├── .gitignore                      # Git ignore rules
├── scripts/                        # Orchestration scripts
│   ├── setup.sh                   # Initial setup
│   ├── health-check.sh            # Service health verification
│   └── update-submodules.sh       # Submodule management
├── monitoring/                     # Monitoring configuration
│   ├── prometheus.yml             # Metrics collection
│   └── grafana/                   # Dashboards
├── backend/                        # Git submodule
│   └── → csfrace-scrape-back      # Python scraping backend
└── frontend/                       # Git submodule
    └── → csfrace-scrape-front     # React/TypeScript frontend
```

## 🛠️ Development Workflow

### Working with Submodules
```bash
# Update all submodules to latest
git submodule update --remote --merge

# Update specific submodule
cd backend && git pull origin main
cd frontend && git pull origin main

# Commit submodule updates
git add .
git commit -m "chore: update submodules to latest versions"
```

### Service Management
```bash
# Start specific services
docker compose up -d backend redis postgres

# Scale services
docker compose up -d --scale backend=2

# View service logs
docker compose logs -f backend
docker compose logs -f frontend

# Execute commands in services
docker compose exec backend uv run pytest
docker compose exec frontend npm test

# Restart services
docker compose restart backend
```

### Development Commands
```bash
# Full environment reset
docker compose down -v
docker compose build --no-cache
docker compose up -d

# Database operations
docker compose exec postgres psql -U postgres -d csfrace

# Cache operations
docker compose exec redis redis-cli

# Health checks
curl http://localhost:8000/health
curl http://localhost:3000/api/health
```

## 🔧 Configuration

### Environment Variables
Key configuration options in `.env`:

```bash
# Global Settings
COMPOSE_PROJECT_NAME=csfrace-scrape
ENVIRONMENT=development

# Backend Configuration
BACKEND_PORT=8000
SCRAPER_CONCURRENT_REQUESTS=10
SCRAPER_TIMEOUT=30

# Frontend Configuration
FRONTEND_PORT=3000
FRONTEND_API_URL=http://backend:8000

# Database
POSTGRES_HOST=postgres
POSTGRES_DB=csfrace
POSTGRES_USER=postgres
POSTGRES_PASSWORD=secure_password

# Cache
REDIS_URL=redis://redis:6379

# Monitoring
GRAFANA_ADMIN_PASSWORD=admin
```

### Service Ports
- **Frontend**: 3000
- **Backend API**: 8000
- **PostgreSQL**: 5432
- **Redis**: 6379
- **Grafana**: 3001
- **Prometheus**: 9090

## 🧪 Testing

### Integration Testing
```bash
# Run integration tests across all services
docker compose -f docker compose.test.yml up -d
scripts/run-integration-tests.sh
```

### Individual Service Testing
```bash
# Backend tests
docker compose exec backend uv run pytest tests/

# Frontend tests
docker compose exec frontend npm test

# End-to-end tests
docker compose exec e2e-tests npm run test:e2e
```

## 🚀 Production Deployment

### Docker Compose Production
```bash
# Build production images
docker compose -f docker compose.prod.yml build

# Deploy with health checks
docker compose -f docker compose.prod.yml up -d

# Verify deployment
scripts/health-check.sh
```

### Rolling Updates
```bash
# Update specific service
scripts/rolling-update.sh backend
scripts/rolling-update.sh frontend
```

## 📊 Monitoring & Observability

### Built-in Monitoring
- **Grafana Dashboards**: Service metrics and health
- **Prometheus Metrics**: Performance monitoring
- **Structured Logging**: Centralized log aggregation
- **Health Endpoints**: Service availability checks

### Accessing Monitoring
```bash
# Grafana (admin/admin)
open http://localhost:3001

# Prometheus
open http://localhost:9090

# View aggregated logs
docker compose logs -f --tail=100
```

## 🤝 Contributing

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/amazing-feature`
3. **Make changes to submodules** following their individual CLAUDE.md standards
4. **Update wrapper configuration** if needed
5. **Test integration**: `docker compose -f docker compose.test.yml up`
6. **Commit changes**: `git commit -m 'feat: add amazing feature'`
7. **Push to branch**: `git push origin feature/amazing-feature`
8. **Open Pull Request**

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 🐛 Troubleshooting

### Common Issues

**Submodules not loading:**
```bash
git submodule update --init --recursive
```

**Port conflicts:**
```bash
# Check what's using ports
lsof -i :3000 -i :8000

# Modify ports in .env file
```

**Services not starting:**
```bash
# Check logs
docker compose logs backend frontend

# Verify health
docker compose ps
```

**Database connection issues:**
```bash
# Reset database
docker compose down postgres
docker volume rm csfrace-scrape_postgres-data
docker compose up -d postgres
```

### Getting Help
- **Backend Issues**: [csfrace-scrape-back/issues](https://github.com/zachatkinson/csfrace-scrape-back/issues)
- **Frontend Issues**: [csfrace-scrape-front/issues](https://github.com/zachatkinson/csfrace-scrape-front/issues)
- **Integration Issues**: [Create issue in this repository](https://github.com/zachatkinson/csfrace-scrape/issues)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Backend Repository**: [csfrace-scrape-back](https://github.com/zachatkinson/csfrace-scrape-back)
- **Frontend Repository**: [csfrace-scrape-front](https://github.com/zachatkinson/csfrace-scrape-front)
- **Documentation**: [Wiki](https://github.com/zachatkinson/csfrace-scrape/wiki)
- **Issues**: [Bug Reports & Feature Requests](https://github.com/zachatkinson/csfrace-scrape/issues)

---

**Made with ❤️ for ethical web scraping**