# CSFrace Scrape - WordPress to Shopify Converter

[![CI/CD Pipeline](https://github.com/zachatkinson/csfrace-scrape/actions/workflows/integration.yml/badge.svg)](https://github.com/zachatkinson/csfrace-scrape/actions/workflows/integration.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Full-stack monorepo for ethical WordPress content scraping and Shopify conversion** - Enterprise-grade web scraping with modern TypeScript/Python stack.

## ✨ Features

- 🚀 **Full-Stack Monorepo** - Backend (Python/FastAPI) + Frontend (Astro/React) in one repository
- 🔄 **Real-Time Updates** - Server-Sent Events (SSE) for live job status
- 🔐 **Enterprise Auth** - OAuth 2.0 (Google, GitHub, Facebook, Apple) + WebAuthn passkeys
- 📊 **Built-in Monitoring** - Prometheus metrics + Grafana dashboards
- 🐳 **Production-Ready Docker** - Multi-stage builds, health checks, security hardening
- 🧪 **100% Type Safety** - TypeScript strict mode + Python type hints
- ⚡ **High Performance** - Async/await patterns, Redis caching, optimized builds

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    CSFrace Scrape Monorepo                      │
│                   (Single Repository)                           │
├────────────────────────┬────────────────────────────────────────┤
│      Frontend          │           Backend                      │
│  (Astro + React)       │     (Python + FastAPI)                │
│                        │                                        │
│  • SSR with @astrojs/  │  • Async job queue                    │
│    node adapter        │  • WordPress scraping                 │
│  • Real-time SSE       │  • Shopify format export              │
│  • TypeScript strict   │  • OAuth2 + WebAuthn                  │
│  • Nanostores state    │  • PostgreSQL + Redis                 │
│  • Tailwind CSS 4      │  • Alembic migrations                 │
│                        │  • UV package manager                 │
└────────────────────────┴────────────────────────────────────────┘
         │                           │
         └───────────┬───────────────┘
                     │
         ┌───────────────────────────────┐
         │     Shared Infrastructure     │
         │                               │
         │  • PostgreSQL 17 (Database)   │
         │  • Redis 7 (Cache + Queue)    │
         │  • Prometheus (Metrics)       │
         │  • Grafana (Dashboards)       │
         │  • Nginx (Reverse Proxy)      │
         └───────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- **Docker Desktop** 24.0+ with Docker Compose 2.20+
- **Git** 2.40+
- **8GB RAM** (4GB minimum)
- **10GB disk space**

### Automated Installation (Recommended)

**macOS / Linux:**
```bash
git clone https://github.com/zachatkinson/csfrace-scrape.git
cd csfrace-scrape
./scripts/install.sh
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/zachatkinson/csfrace-scrape.git
cd csfrace-scrape
.\scripts\test-fresh-install-windows.ps1
```

**Note:** First-time build takes 5-10 minutes (ARM64 Macs may be slower due to Rosetta 2 emulation). Subsequent starts are instant using cached images.

The automated script handles:
- ✅ Complete cleanup of existing containers/volumes
- ✅ Fresh Docker build (5-10 minutes)
- ✅ Health checks for all services
- ✅ Smoke tests to verify functionality
- ✅ Service URL listing

### Manual Installation

```bash
# 1. Clone repository
git clone https://github.com/zachatkinson/csfrace-scrape.git
cd csfrace-scrape

# 2. Configure environment
cp .env.example .env

# 3. Build and start
docker compose build
docker compose up -d

# 4. Verify health
docker compose ps
docker compose logs -f
```

### Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| **Frontend** | http://localhost:3000 | - |
| **Backend API** | http://localhost:8000 | - |
| **API Docs** | http://localhost:8000/docs | Interactive Swagger UI |
| **Grafana** | http://localhost:3001 | admin/admin |
| **Prometheus** | http://localhost:9090 | - |

## 📦 Repository Structure

```
csfrace-scrape/                     # Monorepo root
├── README.md                       # This file
├── INSTALLATION.md                 # Detailed install guide
├── CLAUDE.md                       # Orchestration standards
├── docker-compose.yml              # Production orchestration
├── docker-compose.dev.yml          # Development environment
├── docker-compose.test.yml         # CI/CD testing
├── .env.example                    # Environment template
├── nginx/                          # Reverse proxy config
│   └── nginx.conf                 # Production routing
├── scripts/                        # Automation scripts
│   ├── test-fresh-install-mac.sh  # macOS test script
│   ├── test-fresh-install-windows.ps1  # Windows test script
│   ├── init-db.sql                # Database initialization
│   └── complete-cleanup.sh        # Full cleanup utility
├── monitoring/                     # Observability stack
│   ├── prometheus.yml             # Metrics collection
│   └── grafana/                   # Dashboard configs
├── backend/                        # Python backend (NOT a submodule)
│   ├── CLAUDE.md                  # Backend dev standards
│   ├── Dockerfile                 # Multi-stage Python build
│   ├── docker-entrypoint.sh       # Migration runner
│   ├── pyproject.toml             # UV package config
│   ├── uv.lock                    # Dependency lock
│   ├── alembic.ini                # Database migrations
│   ├── alembic/                   # Migration scripts
│   ├── src/                       # Application code
│   │   ├── api/                   # FastAPI routes
│   │   ├── auth/                  # OAuth + WebAuthn
│   │   ├── core/                  # Business logic
│   │   ├── database/              # SQLAlchemy models
│   │   └── monitoring/            # Metrics + events
│   └── tests/                     # Pytest test suite
└── frontend/                       # Astro frontend (NOT a submodule)
    ├── CLAUDE.md                  # Frontend dev standards
    ├── Dockerfile                 # Node 20 Alpine build
    ├── astro.config.ts            # SSR configuration
    ├── package.json               # pnpm packages
    ├── pnpm-lock.yaml             # Dependency lock
    ├── src/                       # Application code
    │   ├── pages/                 # Astro routes
    │   ├── components/            # React components
    │   ├── stores/                # Nanostores state
    │   ├── services/              # SSE clients
    │   └── layouts/               # Page templates
    └── tests/                     # Vitest + Playwright
```

## 🛠️ Development

### Common Commands

```bash
# View all service logs
docker compose logs -f

# View specific service logs
docker compose logs -f backend
docker compose logs -f frontend

# Restart services
docker compose restart backend
docker compose restart frontend

# Rebuild after code changes
docker compose build backend
docker compose build frontend
docker compose up -d

# Execute commands inside containers
docker compose exec backend uv run pytest
docker compose exec frontend pnpm test

# Database operations
docker compose exec postgres psql -U postgres -d csfrace

# Redis operations
docker compose exec redis redis-cli
```

### Development Workflow

```bash
# 1. Make changes to backend code in backend/src/
# 2. Rebuild backend image
docker compose build backend

# 3. Make changes to frontend code in frontend/src/
# 4. Rebuild frontend image
docker compose build frontend

# 5. Test changes
docker compose up -d
docker compose logs -f

# 6. Run tests
docker compose exec backend uv run pytest tests/
docker compose exec frontend pnpm test
```

### Environment Configuration

Key `.env` variables:

```bash
# Global
COMPOSE_PROJECT_NAME=csfrace-scrape
ENVIRONMENT=development|staging|production

# Backend
BACKEND_PORT=8000
SECRET_KEY=your-secret-key-here
DATABASE_URL=postgresql://postgres:password@postgres:5432/csfrace
REDIS_URL=redis://redis:6379/0

# Frontend
FRONTEND_PORT=3000
PUBLIC_API_BASE_URL=http://localhost:8000
SERVER_API_BASE_URL=http://backend:8000

# OAuth2 (optional)
OAUTH_GOOGLE_CLIENT_ID=your-google-client-id
OAUTH_GITHUB_CLIENT_ID=your-github-client-id
OAUTH_FACEBOOK_CLIENT_ID=your-facebook-client-id
OAUTH_APPLE_CLIENT_ID=your-apple-client-id

# Monitoring
PROMETHEUS_PORT=9090
GRAFANA_ADMIN_PASSWORD=admin
```

## 🧪 Testing

### Integration Tests (CI/CD)

```bash
# Run full integration test suite
docker compose -f docker-compose.test.yml up -d --wait
# Tests run automatically in CI
```

### Unit Tests

```bash
# Backend tests (pytest)
docker compose exec backend uv run pytest tests/ -v --cov=src

# Frontend tests (vitest)
docker compose exec frontend pnpm test

# Frontend E2E tests (playwright)
docker compose exec frontend pnpm test:e2e
```

### Manual Testing

```bash
# Test backend health
curl http://localhost:8000/health/

# Test frontend
open http://localhost:3000  # macOS
start http://localhost:3000  # Windows

# Test API endpoints
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

## 🚀 Production Deployment

### Docker Compose Production

```bash
# Build production images
docker compose -f docker-compose.prod.yml build

# Deploy with health checks
docker compose -f docker-compose.prod.yml up -d

# Verify deployment
curl http://localhost:8000/health/
curl http://localhost:3000/
```

### Environment Requirements

- **CPU**: 2 cores minimum, 4 cores recommended
- **RAM**: 4GB minimum, 8GB recommended
- **Disk**: 10GB free space
- **Network**: Stable internet for OAuth callbacks

### Security Hardening

- ✅ Non-root Docker users
- ✅ Multi-stage builds (no build tools in production)
- ✅ Security scanning (Trivy in CI)
- ✅ Dependency vulnerability checks
- ✅ HTTP-only cookies
- ✅ CORS configuration
- ✅ Rate limiting
- ✅ Input validation

## 📊 Monitoring & Observability

### Built-in Dashboards

**Grafana** (http://localhost:3001):
- Service health overview
- Request rate and latency
- Database connection pool
- Redis cache hit rate
- Job queue metrics
- Error rates

**Prometheus** (http://localhost:9090):
- Raw metrics endpoint
- Query interface
- Alert rules

### Key Metrics

```bash
# Backend metrics
curl http://localhost:8000/metrics

# Frontend health
curl http://localhost:3000/

# Database stats
docker compose exec postgres psql -U postgres -c '\dt+'

# Redis info
docker compose exec redis redis-cli INFO
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Make changes following standards in `CLAUDE.md`
4. Run tests: `docker compose exec backend uv run pytest`
5. Commit changes: `git commit -m 'feat: add amazing feature'`
6. Push to branch: `git push origin feature/amazing-feature`
7. Open Pull Request

### Development Standards

- **Backend**: Python 3.13, FastAPI, UV package manager, type hints, pytest
- **Frontend**: Astro + React, TypeScript strict mode, nanostores, vitest
- **Code Style**: Ruff (Python), ESLint + Prettier (TypeScript)
- **Commits**: Conventional commits format
- **Documentation**: Update README and CLAUDE.md

## 🐛 Troubleshooting

See [INSTALLATION.md](INSTALLATION.md) for comprehensive troubleshooting guide.

### Quick Fixes

**Services won't start:**
```bash
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

**Port conflicts:**
```bash
# Check what's using ports
lsof -i :3000 -i :8000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Change ports in .env
```

**Database errors:**
```bash
# Reset database (WARNING: deletes data)
docker compose down -v
docker volume rm csfrace-scrape_postgres-data
docker compose up -d
```

**Build failures:**
```bash
# Clear Docker cache
docker builder prune -a
docker compose build --no-cache
```

### Getting Help

- 📖 **Documentation**: [INSTALLATION.md](INSTALLATION.md) for setup guide
- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/zachatkinson/csfrace-scrape/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/zachatkinson/csfrace-scrape/discussions)
- 📝 **Logs**: Always check `docker compose logs -f` first

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Repository**: [github.com/zachatkinson/csfrace-scrape](https://github.com/zachatkinson/csfrace-scrape)
- **Issues**: [Bug Reports & Feature Requests](https://github.com/zachatkinson/csfrace-scrape/issues)
- **CI/CD**: [GitHub Actions](https://github.com/zachatkinson/csfrace-scrape/actions)

## 🎯 Tech Stack

### Backend
- **Language**: Python 3.13
- **Framework**: FastAPI 0.115+
- **Package Manager**: UV (40% faster than pip)
- **Database**: PostgreSQL 17 + SQLAlchemy 2.0
- **Cache**: Redis 7
- **Auth**: OAuth2 + WebAuthn
- **Testing**: Pytest + Hypothesis
- **Linting**: Ruff + MyPy

### Frontend
- **Framework**: Astro 5.1 (SSR)
- **UI Library**: React 19
- **Language**: TypeScript 5.7 (strict mode)
- **Package Manager**: pnpm 9
- **Styling**: Tailwind CSS 4
- **State**: Nanostores (286 bytes)
- **Testing**: Vitest + Playwright
- **Linting**: ESLint + Prettier

### Infrastructure
- **Containerization**: Docker + Docker Compose
- **Reverse Proxy**: Nginx 1.25
- **Monitoring**: Prometheus + Grafana
- **CI/CD**: GitHub Actions

---

**Made with ❤️ for ethical web scraping**
