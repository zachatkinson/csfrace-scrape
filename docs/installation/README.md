# CSFrace Scrape - Installation Guide

Complete installation guide for macOS and Windows.

## 🎯 Platform-Specific Guides

**Choose your operating system for detailed instructions:**

- **[macOS Installation Guide →](INSTALLATION-MAC.md)**
  - Intel and Apple Silicon (M1/M2/M3) support
  - Homebrew installation options
  - macOS-specific troubleshooting

- **[Windows Installation Guide →](INSTALLATION-WINDOWS.md)**
  - Windows 10/11 with WSL 2
  - PowerShell and Command Prompt examples
  - Windows-specific troubleshooting

---

## Overview

This guide covers the basic installation process. For platform-specific details, performance tuning, and troubleshooting, see the guides above.

## Prerequisites

### Required Software

1. **Docker Desktop** (includes Docker Compose)
   - **macOS**: [Download Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
   - **Windows**: [Download Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
   - **Minimum version**: Docker 24.0+, Docker Compose 2.20+

2. **Git**
   - **macOS**: Pre-installed or `brew install git`
   - **Windows**: [Download Git for Windows](https://git-scm.com/download/win)

### System Requirements

- **RAM**: 4GB minimum, 8GB recommended
- **Disk Space**: 10GB free space
- **CPU**: 2 cores minimum, 4 cores recommended

## Quick Start (Recommended)

### macOS / Linux

```bash
# Clone the repository
git clone https://github.com/zachatkinson/csfrace-scrape.git
cd csfrace-scrape

# Run the automated fresh install test
./scripts/test-fresh-install-mac.sh
```

### Windows (PowerShell)

```powershell
# Clone the repository
git clone https://github.com/zachatkinson/csfrace-scrape.git
cd csfrace-scrape

# Run the automated fresh install test
.\scripts\test-fresh-install-windows.ps1
```

The automated script will:
1. ✅ Clean up any existing containers and volumes
2. ✅ Create fresh environment configuration
3. ✅ Build Docker images (5-10 minutes)
4. ✅ Start all services
5. ✅ Run health checks
6. ✅ Verify everything works

## Manual Installation

If you prefer step-by-step control:

### Step 1: Clone Repository

```bash
git clone https://github.com/zachatkinson/csfrace-scrape.git
cd csfrace-scrape
```

### Step 2: Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your preferred settings (optional)
# Most settings work out-of-the-box for local development
nano .env  # or use your favorite editor
```

### Step 3: Build Images

```bash
# Build all Docker images (first time: 5-10 minutes)
docker compose build
```

### Step 4: Start Services

```bash
# Start all services in detached mode
docker compose up -d
```

### Step 5: Verify Installation

```bash
# Check service health
docker compose ps

# View logs
docker compose logs -f

# Test backend API
curl http://localhost:8000/health/

# Open frontend in browser
open http://localhost:3000  # macOS
start http://localhost:3000  # Windows
```

## Service URLs

Once installed, access the application at:

| Service | URL | Description |
|---------|-----|-------------|
| **Frontend** | http://localhost:3000 | Main web interface |
| **Backend API** | http://localhost:8000 | REST API |
| **API Documentation** | http://localhost:8000/docs | Interactive API docs (Swagger) |
| **Prometheus** | http://localhost:9090 | Metrics monitoring |
| **Grafana** | http://localhost:3001 | Analytics dashboards (admin/admin) |

## Common Commands

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f frontend
```

### Restart Services

```bash
# Restart all services
docker compose restart

# Restart specific service
docker compose restart backend
docker compose restart frontend
```

### Stop Services

```bash
# Stop without removing containers
docker compose stop

# Stop and remove containers (keeps volumes)
docker compose down

# Stop and remove everything (including volumes)
docker compose down -v
```

### Rebuild After Changes

```bash
# Rebuild specific service
docker compose build backend
docker compose build frontend

# Rebuild everything from scratch
docker compose build --no-cache

# Rebuild and restart
docker compose up -d --build
```

## Troubleshooting

### Services Won't Start

```bash
# Check Docker is running
docker --version
docker compose version

# Check for port conflicts
lsof -i :3000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Clean start
docker compose down -v
docker compose up -d
```

### Build Failures

```bash
# Clear Docker build cache
docker builder prune -a

# Rebuild from scratch
docker compose build --no-cache
```

### Database Issues

```bash
# Reset database (WARNING: deletes all data)
docker compose down -v
docker volume rm csfrace-scrape_postgres-data
docker compose up -d
```

### Permission Issues (macOS/Linux)

```bash
# Fix script permissions
chmod +x scripts/*.sh

# Fix Docker socket permissions (if needed)
sudo chmod 666 /var/run/docker.sock
```

### ARM64 Mac Issues (lightningcss)

The frontend Dockerfile includes an ARM64 compatibility fix for lightningcss. If you still see build errors:

```bash
# Force AMD64 platform
DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose build frontend
```

## Development vs Production

### Development Mode (Default)

```bash
# Uses docker-compose.yml
docker compose up -d

# Features:
# - Hot reload enabled
# - Debug logging
# - Source maps
# - Development dependencies
```

### Production Mode

```bash
# Uses docker-compose.prod.yml
docker compose -f docker-compose.prod.yml up -d

# Features:
# - Optimized builds
# - Minimal logging
# - No debug tools
# - Production dependencies only
```

## Updating

### Pull Latest Changes

```bash
# Stop services
docker compose down

# Pull latest code
git pull origin master

# Rebuild and restart
docker compose build
docker compose up -d
```

## Uninstalling

### Complete Removal

```bash
# Stop and remove everything
docker compose down -v

# Remove images
docker rmi csfrace-scrape-backend csfrace-scrape-frontend

# Remove repository
cd ..
rm -rf csfrace-scrape
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Docker Compose                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Frontend   │  │   Backend   │  │    Nginx    │        │
│  │  (Astro)    │  │  (FastAPI)  │  │ (Reverse    │        │
│  │  Port 3000  │  │  Port 8000  │  │  Proxy)     │        │
│  └──────┬──────┘  └──────┬──────┘  └─────────────┘        │
│         │                 │                                  │
│         └────────┬────────┘                                  │
│                  │                                           │
│  ┌───────────────┴──────────────┐  ┌─────────────┐        │
│  │       PostgreSQL 17          │  │   Redis 7   │        │
│  │    (Database Storage)        │  │  (Caching)  │        │
│  └──────────────────────────────┘  └─────────────┘        │
│                                                               │
│  ┌─────────────┐  ┌─────────────┐                          │
│  │ Prometheus  │  │   Grafana   │                          │
│  │ (Metrics)   │  │ (Analytics) │                          │
│  └─────────────┘  └─────────────┘                          │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Getting Help

- **Documentation**: Check the main [README.md](README.md)
- **Issues**: [GitHub Issues](https://github.com/zachatkinson/csfrace-scrape/issues)
- **Logs**: Always check `docker compose logs -f` first

## Next Steps

After successful installation:

1. **Configure OAuth** (optional): See [SETUP_APPLE_OAUTH.md](SETUP_APPLE_OAUTH.md)
2. **Review API**: Browse http://localhost:8000/docs
3. **Explore Frontend**: Open http://localhost:3000
4. **Monitor Performance**: Check Grafana at http://localhost:3001

---

**Need help?** Check the logs first: `docker compose logs -f`
