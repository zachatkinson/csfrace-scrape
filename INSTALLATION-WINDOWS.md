# CSFrace Scrape - Windows Installation Guide

Complete installation guide for Windows 10/11.

## Prerequisites

### Required Software

1. **Docker Desktop for Windows**
   - Download: [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
   - **Minimum version**: Docker 24.0+, Docker Compose 2.20+
   - Requires **WSL 2** (Windows Subsystem for Linux 2)

2. **Git for Windows**
   - Download: [Git for Windows](https://git-scm.com/download/win)
   - **Minimum version**: Git 2.40+

3. **WSL 2**
   - Required by Docker Desktop
   - Installation instructions below

### System Requirements

- **RAM**: 4GB minimum, 8GB recommended
- **Disk Space**: 10GB free space
- **CPU**: 2 cores minimum, 4 cores recommended, 64-bit processor with virtualization support
- **Windows**: Windows 10 version 2004+ or Windows 11

## WSL 2 Setup

Docker Desktop requires WSL 2. Install it if you haven't already:

### PowerShell (Administrator)

```powershell
# Enable WSL and Virtual Machine Platform
wsl --install

# Restart your computer when prompted

# After restart, verify installation
wsl --version

# Set WSL 2 as default
wsl --set-default-version 2
```

## 🚀 Quick Start (Recommended)

### Automated Installation

**PowerShell (Run as Administrator):**

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

**That's it!** The script handles everything automatically.

## Manual Installation

If you prefer step-by-step control:

### Step 1: Install Docker Desktop

```powershell
# Download Docker Desktop from the link above

# Run the installer
# Docker Desktop Installer.exe

# Start Docker Desktop from Start Menu
# Wait for Docker to start (whale icon in system tray)

# Verify installation (PowerShell)
docker --version
docker compose version
```

### Step 2: Clone Repository

**PowerShell:**

```powershell
git clone https://github.com/zachatkinson/csfrace-scrape.git
cd csfrace-scrape
```

**Command Prompt:**

```cmd
git clone https://github.com/zachatkinson/csfrace-scrape.git
cd csfrace-scrape
```

### Step 3: Configure Environment

```powershell
# Copy example environment file
Copy-Item .env.example .env

# Edit .env with your preferred settings (optional)
# Most settings work out-of-the-box for local development
notepad .env  # or use your favorite editor
```

### Step 4: Build Images

```powershell
# Build all Docker images (first time: 5-10 minutes)
docker compose build
```

### Step 5: Start Services

```powershell
# Start all services in detached mode
docker compose up -d

# Watch logs (optional)
docker compose logs -f
```

### Step 6: Setup HTTPS (Recommended)

For secure local development and OAuth support:

```powershell
# Generate self-signed SSL certificates
.\create-https-cert.ps1

# Restart nginx to load new certificates
docker compose restart nginx
```

The script will:
- Generate SSL certificates for localhost
- Add certificate to Windows Trusted Root store
- Enable HTTPS access at https://localhost

**Note**: You may need to run PowerShell as Administrator for automatic certificate installation.

### Step 7: Verify Installation

```powershell
# Check service health
docker compose ps

# Test backend API via HTTPS (recommended)
Invoke-RestMethod -Uri https://localhost/health -SkipCertificateCheck

# Or via HTTP
Invoke-RestMethod -Uri http://localhost:8000/health/

# Open frontend in browser
start https://localhost
```

## Service URLs

Once installed, access the application at:

| Service | URL | Description |
|---------|-----|-------------|
| **Frontend (HTTPS)** | https://localhost | Main web interface (recommended) |
| **Frontend (HTTP)** | http://localhost:3000 | Alternative HTTP access |
| **Backend API (HTTPS)** | https://localhost/api | REST API via nginx (recommended) |
| **Backend API (HTTP)** | http://localhost:8000 | Direct backend access |
| **API Documentation** | http://localhost:8000/docs | Interactive API docs (Swagger) |
| **Prometheus** | http://localhost:9090 | Metrics monitoring |
| **Grafana** | http://localhost:3001 | Analytics dashboards (admin/admin) |

**Recommended**: Use HTTPS (https://localhost) for all development work, especially when using OAuth.

## Common Commands

All commands below work in **PowerShell** or **Command Prompt**.

### View Logs

```powershell
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f frontend

# Last 100 lines
docker compose logs --tail=100 -f
```

### Restart Services

```powershell
# Restart all services
docker compose restart

# Restart specific service
docker compose restart backend
docker compose restart frontend
```

### Stop Services

```powershell
# Stop without removing containers
docker compose stop

# Stop and remove containers (keeps volumes)
docker compose down

# Stop and remove everything (including volumes/data)
docker compose down -v
```

### Rebuild After Changes

```powershell
# Rebuild specific service
docker compose build backend
docker compose build frontend

# Rebuild everything from scratch
docker compose build --no-cache

# Rebuild and restart
docker compose up -d --build
```

## Windows-Specific Notes

### WSL 2 Integration

Docker Desktop runs containers in WSL 2 for best performance:

1. **Docker Desktop → Settings → Resources → WSL Integration**
2. Enable integration with your WSL 2 distributions
3. Click **Apply & Restart**

### Line Endings (CRLF vs LF)

Git on Windows converts line endings by default. To prevent issues:

```powershell
# Configure Git to not convert line endings
git config --global core.autocrlf input

# If you already cloned, fix existing files:
git rm --cached -r .
git reset --hard HEAD
```

### Performance Tips

For better performance on Windows:

1. **Docker Desktop → Settings → Resources**:
   - **CPUs**: 4+ cores recommended
   - **Memory**: 8GB+ recommended
   - **Disk**: 60GB+ recommended

2. **Store code in WSL 2 filesystem** (optional, for better performance):
   ```powershell
   # Access WSL 2 filesystem
   wsl

   # Clone in Linux filesystem
   cd ~
   git clone https://github.com/zachatkinson/csfrace-scrape.git
   cd csfrace-scrape

   # Run Docker commands from WSL
   docker compose up -d
   ```

### Windows Firewall

If you can't access services, check Windows Firewall:

1. **Windows Security → Firewall & network protection**
2. **Allow an app through firewall**
3. Look for **Docker Desktop** and ensure both **Private** and **Public** are checked

## Troubleshooting

### Docker Desktop Not Starting

```powershell
# Restart Docker Desktop
# System Tray → Docker icon → Restart

# Or restart Docker service (PowerShell as Administrator):
Stop-Service com.docker.service
Start-Service com.docker.service

# If still not working, restart WSL:
wsl --shutdown
# Then start Docker Desktop again
```

### "WSL 2 installation is incomplete"

```powershell
# Update WSL (PowerShell as Administrator)
wsl --update

# Install WSL 2 kernel update:
# Download from: https://aka.ms/wsl2kernel
# Run: wsl_update_x64.msi

# Restart computer
```

### Port Conflicts

```powershell
# Check what's using ports (PowerShell as Administrator)
netstat -ano | findstr :3000
netstat -ano | findstr :8000

# Kill processes if needed (replace <PID> with actual PID)
Stop-Process -Id <PID> -Force

# Or change ports in .env file
```

### Services Won't Start

```powershell
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

```powershell
# Run PowerShell as Administrator
# Right-click PowerShell icon → Run as Administrator

# Fix script execution policy (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Build Failures

```powershell
# Clear Docker cache
docker builder prune -a

# Rebuild from scratch
docker compose build --no-cache

# Check Docker Desktop logs:
# Docker Desktop → Bug icon → Troubleshoot → View logs
```

### Database Issues

```powershell
# Reset database (WARNING: deletes all data)
docker compose down -v
docker volume rm csfrace-scrape_postgres-data
docker compose up -d

# Check database logs
docker compose logs postgres
```

### "No space left on device"

```powershell
# Clean Docker system
docker system prune -a --volumes

# Clean Docker Desktop cache
# Docker Desktop → Bug icon → Troubleshoot → Clean / Purge data

# Increase Docker Desktop disk size
# Docker Desktop → Settings → Resources → Disk image size
```

### Hyper-V Issues

Docker Desktop requires Hyper-V. If you get Hyper-V errors:

```powershell
# Enable Hyper-V (PowerShell as Administrator)
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Restart computer when prompted
```

### "Access denied" Errors

```powershell
# Run PowerShell as Administrator
# Right-click PowerShell → Run as Administrator

# Or add your user to docker-users group:
# Computer Management → Local Users and Groups → Groups → docker-users
# Add your user account → OK → Log out and log back in
```

## Development vs Production

### Development Mode (Default)

```powershell
# Uses docker-compose.yml
docker compose up -d

# Features:
# - Hot reload enabled
# - Debug logging
# - Source maps
# - Development dependencies
```

### Production Mode

```powershell
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

```powershell
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

```powershell
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
Remove-Item -Recurse -Force csfrace-scrape

# Uninstall Docker Desktop (optional)
# Settings → Apps → Docker Desktop → Uninstall
```

## Getting Help

- **Documentation**: Check the main [README.md](README.md)
- **Windows Issues**: Look for WSL 2/Windows-specific errors first
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
