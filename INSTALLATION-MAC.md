# CSFrace Scrape - macOS Installation Guide

Complete installation guide for macOS (Intel & Apple Silicon).

## Prerequisites

### Required Software

1. **Docker Desktop for Mac**
   - Download: [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
   - **Minimum version**: Docker 24.0+, Docker Compose 2.20+
   - Works on both Intel and Apple Silicon (M1/M2/M3)

2. **Git**
   - Pre-installed on macOS or install via Homebrew: `brew install git`
   - **Minimum version**: Git 2.40+

### System Requirements

- **RAM**: 4GB minimum, 8GB recommended
- **Disk Space**: 10GB free space
- **CPU**: 2 cores minimum, 4 cores recommended
- **macOS**: 12.0 (Monterey) or later

## 🚀 Quick Start (Recommended)

### Automated Installation

```bash
# Clone the repository
git clone https://github.com/zachatkinson/csfrace-scrape.git
cd csfrace-scrape

# Run the automated fresh install test
./scripts/test-fresh-install-mac.sh
```

The automated script will:
1. ✅ Clean up any existing containers and volumes
2. ✅ Create fresh environment configuration
3. ✅ Build Docker images (5-10 minutes)
4. ✅ Start all services
5. ✅ Run health checks
6. ✅ Verify everything works

**That's it!** The script handles everything automatically.

## Manual Installation

If you prefer step-by-step control:

### Step 1: Install Docker Desktop

```bash
# Download Docker Desktop from the link above, or use Homebrew:
brew install --cask docker

# Start Docker Desktop from Applications folder
# Wait for Docker to start (whale icon in menu bar)

# Verify installation
docker --version
docker compose version
```

### Step 2: Clone Repository

```bash
git clone https://github.com/zachatkinson/csfrace-scrape.git
cd csfrace-scrape
```

### Step 3: Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your preferred settings (optional)
# Most settings work out-of-the-box for local development
nano .env  # or use your favorite editor
```

### Step 4: Build Images

```bash
# Build all Docker images (first time: 5-10 minutes)
docker compose build

# On Apple Silicon Macs, the frontend includes an ARM64 fix for lightningcss
# If you encounter build errors, try:
DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose build frontend
```

### Step 5: Start Services

```bash
# Start all services in detached mode
docker compose up -d

# Watch logs (optional)
docker compose logs -f
```

### Step 6: Verify Installation

```bash
# Check service health
docker compose ps

# Test backend API
curl http://localhost:8000/health/

# Open frontend in browser
open http://localhost:3000
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

# Last 100 lines
docker compose logs --tail=100 -f
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

# Stop and remove everything (including volumes/data)
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

## macOS-Specific Notes

### Apple Silicon (M1/M2/M3) Support

The frontend includes a built-in fix for lightningcss ARM64 compatibility:

```dockerfile
# Already in Dockerfile - no action needed
ARG BUILDPLATFORM=linux/amd64
FROM --platform=${BUILDPLATFORM} node:20-alpine
```

If you still encounter issues:

```bash
# Force AMD64 platform
DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose build

# Or set permanently in ~/.zshrc or ~/.bash_profile:
export DOCKER_DEFAULT_PLATFORM=linux/amd64
```

### Rosetta 2 (Intel Emulation)

For best performance on Apple Silicon, ensure Rosetta 2 is installed:

```bash
softwareupdate --install-rosetta --agree-to-license
```

### File Sharing

Docker Desktop may need access to your project directory:

1. Open Docker Desktop → **Preferences** → **Resources** → **File Sharing**
2. Ensure `/Users` is listed (it should be by default)
3. Click **Apply & Restart** if you made changes

### Performance Tuning

For better performance on macOS:

1. **Docker Desktop → Preferences → Resources**:
   - **CPUs**: 4+ cores recommended
   - **Memory**: 8GB+ recommended
   - **Disk**: 60GB+ recommended

2. **Use VirtioFS** (Docker Desktop 4.6+):
   - Docker Desktop → **Preferences** → **General**
   - Enable **Use VirtioFS** for better file system performance

## Troubleshooting

### Docker Desktop Not Starting

```bash
# Reset Docker Desktop
# Docker Desktop → Bug icon → Reset to factory defaults

# Or via command line:
rm -rf ~/Library/Group\ Containers/group.com.docker
rm -rf ~/Library/Containers/com.docker.docker
rm -rf ~/.docker

# Reinstall Docker Desktop
brew reinstall --cask docker
```

### Port Conflicts

```bash
# Check what's using ports
lsof -i :3000
lsof -i :8000

# Kill processes if needed
kill -9 <PID>

# Or change ports in .env file
```

### Services Won't Start

```bash
# Check Docker is running
docker ps

# Clean start
docker compose down -v
docker compose build --no-cache
docker compose up -d

# Check logs for errors
docker compose logs -f
```

### Permission Issues

```bash
# Fix script permissions
chmod +x scripts/*.sh

# Fix Docker socket permissions (rarely needed)
sudo chmod 666 /var/run/docker.sock
```

### Build Failures on Apple Silicon

```bash
# Clear Docker cache
docker builder prune -a

# Force AMD64 platform build
DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose build --no-cache

# If still failing, check Docker Desktop logs:
# Docker Desktop → Bug icon → Logs
```

### Database Issues

```bash
# Reset database (WARNING: deletes all data)
docker compose down -v
docker volume rm csfrace-scrape_postgres-data
docker compose up -d

# Check database logs
docker compose logs postgres
```

### "No space left on device"

```bash
# Clean Docker system
docker system prune -a --volumes

# Clean Docker Desktop cache
# Docker Desktop → Bug icon → Clean / Purge data

# Increase Docker Desktop disk size
# Docker Desktop → Preferences → Resources → Disk image size
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

# Remove Docker volumes (if not removed by -v)
docker volume rm csfrace-scrape_postgres-data
docker volume rm csfrace-scrape_redis-data
docker volume rm csfrace-scrape_grafana-data
docker volume rm csfrace-scrape_prometheus-data

# Remove repository
cd ..
rm -rf csfrace-scrape

# Uninstall Docker Desktop (optional)
# Docker Desktop → Bug icon → Uninstall
# Or via Homebrew:
brew uninstall --cask docker
```

## Getting Help

- **Documentation**: Check the main [README.md](README.md)
- **macOS Issues**: Look for Apple Silicon/macOS-specific errors first
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
