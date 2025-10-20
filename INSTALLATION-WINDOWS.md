# CSFrace Scrape - Windows Installation Guide

[![Windows 10/11](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![PowerShell 7+](https://img.shields.io/badge/PowerShell-7%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/PowerShell/PowerShell)
[![Docker](https://img.shields.io/badge/Docker-24.0%2B-2496ED?logo=docker&logoColor=white)](https://www.docker.com/products/docker-desktop/)
[![WSL 2](https://img.shields.io/badge/WSL-2-FCC624?logo=linux&logoColor=black)](https://docs.microsoft.com/en-us/windows/wsl/)

Complete installation guide for CSFrace Scrape on Windows 10/11.

---

## Table of Contents

- [Prerequisites](#prerequisites)
  - [Required Software](#required-software)
  - [System Requirements](#system-requirements)
  - [WSL 2 Setup](#wsl-2-setup)
- [Quick Start (Recommended)](#quick-start-recommended)
  - [1. Download the Project](#1-download-the-project)
  - [2. Extract Files](#2-extract-files)
  - [3. Run the Installer](#3-run-the-installer)
- [Manual Installation](#manual-installation)
- [Service URLs](#service-urls)
- [Common Commands](#common-commands)
- [Troubleshooting](#troubleshooting)
- [PowerShell Script Execution](#powershell-script-execution)
- [Updating](#updating)
- [Uninstalling](#uninstalling)

---

## Prerequisites

### Required Software

#### 1. PowerShell 7 or Higher

Windows comes with PowerShell 5.1 by default. You **must** upgrade to PowerShell 7+ for the installer to work.

**Quick Install:**
```powershell
winget install Microsoft.PowerShell
```

**Manual Download:** [Installing PowerShell on Windows](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5)

**Verify Installation:**
```powershell
$PSVersionTable.PSVersion
# Should show 7.x or higher
```

#### 2. Docker Desktop for Windows

**Download:** [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)

**Minimum Versions:**
- Docker 24.0+
- Docker Compose 2.20+

**Important:** Docker Desktop requires WSL 2 (see below).

#### 3. WSL 2 (Windows Subsystem for Linux 2)

Docker Desktop requires WSL 2 to run containers on Windows.

**Install WSL 2:**

1. Open PowerShell as **Administrator**
2. Run:
   ```powershell
   # Enable WSL and Virtual Machine Platform
   wsl --install

   # Restart your computer when prompted
   ```

3. After restart, verify:
   ```powershell
   wsl --version

   # Set WSL 2 as default
   wsl --set-default-version 2
   ```

**More Info:** [WSL Installation Guide](https://docs.microsoft.com/en-us/windows/wsl/install)

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **RAM** | 4GB | 8GB |
| **Disk Space** | 10GB free | 20GB+ free |
| **CPU** | 2 cores, 64-bit with virtualization | 4+ cores |
| **Windows Version** | Windows 10 version 2004+ | Windows 11 |

**Check Virtualization:**
- Open Task Manager → Performance tab → CPU
- Look for "Virtualization: Enabled"
- If disabled, enable in BIOS

---

## Quick Start (Recommended)

### 1. Download the Project

Visit [github.com/zachatkinson/csfrace-scrape](https://github.com/zachatkinson/csfrace-scrape):

1. Click the green **Code** button
2. Select **Download ZIP**
3. Save to your **Desktop** (or preferred location)

### 2. Extract Files

1. Right-click the downloaded ZIP file
2. Select **Extract All...**
3. Click **Extract** (creates `csfrace-scrape-master` folder)

### 3. Run the Installer

> **IMPORTANT:** The installer requires **Administrator privileges** to add SSL certificates to Windows' trusted root store.

**Steps:**

1. **Open PowerShell as Administrator:**
   - Press `Win + X`
   - Select **Windows PowerShell (Admin)** or **Terminal (Admin)**
   - Or: Right-click PowerShell icon → **Run as Administrator**

2. **Navigate to the extracted folder:**
   ```powershell
   cd "$env:USERPROFILE\Desktop\csfrace-scrape-master"
   ```

3. **Unblock and run the installer:**
   ```powershell
   # Unblock the script (required for unsigned scripts)
   Unblock-File -Path .\scripts\install.ps1

   # Run the installer
   .\scripts\install.ps1
   ```

**What the installer does:**
1. ✅ Checks PowerShell version (requires 7+)
2. ✅ Verifies Administrator privileges
3. ✅ Cleans up any existing containers
4. ✅ Creates `.env` configuration file
5. ✅ Generates SSL certificates using native PowerShell
6. ✅ Adds certificates to Windows Trusted Root store
7. ✅ Builds Docker images (5-10 minutes)
8. ✅ Starts all services
9. ✅ Runs health checks
10. ✅ Verifies everything works

**Expected Duration:** 5-10 minutes (first time)

**When complete, you'll see:**
```
OK: Installation complete!

Service URLs:
  Frontend:    https://localhost (recommended)
  Backend API: https://localhost/api
  API Docs:    https://localhost/docs
  Grafana:     http://localhost:3001 (admin/admin)
  Prometheus:  http://localhost:9090

HTTPS is configured and ready to use!

Ready to use!
```

---

## Manual Installation

<details>
<summary>Click to expand manual installation steps</summary>

If you prefer step-by-step control, follow these instructions:

### Step 1: Install Docker Desktop

1. Download from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)
2. Run the installer: `Docker Desktop Installer.exe`
3. Start Docker Desktop from Start Menu
4. Wait for Docker to start (whale icon in system tray)

**Verify Installation:**
```powershell
docker --version
docker compose version
```

### Step 2: Download Project Files

Follow [steps 1-2 from Quick Start](#quick-start-recommended)

### Step 3: Configure Environment

```powershell
# Navigate to project directory
cd "$env:USERPROFILE\Desktop\csfrace-scrape-master"

# Copy example environment file
Copy-Item .env.example .env

# Edit .env with your preferred settings (optional)
notepad .env
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

### Step 6: Verify Installation

```powershell
# Check service health
docker compose ps

# Test backend API via HTTPS
Invoke-RestMethod -Uri https://localhost/health -SkipCertificateCheck

# Open frontend in browser
start https://localhost
```

</details>

---

## Service URLs

Once installed, access the application at:

| Service | URL | Description |
|---------|-----|-------------|
| **Frontend (HTTPS)** | https://localhost | Main web interface (recommended) |
| **Backend API (HTTPS)** | https://localhost/api | REST API via nginx (recommended) |
| **API Documentation** | https://localhost/docs | Interactive API docs (Swagger UI) |
| **Grafana** | http://localhost:3001 | Analytics dashboards (admin/admin) |
| **Prometheus** | http://localhost:9090 | Metrics monitoring |
| **Frontend (HTTP)** | http://localhost:3000 | Direct access (without nginx) |
| **Backend API (HTTP)** | http://localhost:8000 | Direct access (without nginx) |

**Recommended:** Use HTTPS URLs (https://localhost) for all development work, especially when using OAuth.

---

## Common Commands

All commands work in **PowerShell** or **Command Prompt**.

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

# Stop and remove containers (keeps volumes/data)
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

### Check Status

```powershell
# List running containers
docker compose ps

# View resource usage
docker stats

# Check Docker disk usage
docker system df
```

---

## Troubleshooting

### Docker Desktop Not Starting

```powershell
# Restart Docker service (PowerShell as Administrator)
Stop-Service com.docker.service
Start-Service com.docker.service

# Or restart WSL
wsl --shutdown
# Then start Docker Desktop again
```

### "WSL 2 installation is incomplete"

```powershell
# Update WSL (PowerShell as Administrator)
wsl --update

# Restart computer
```

**If still not working:**
1. Download WSL 2 kernel update: https://aka.ms/wsl2kernel
2. Run: `wsl_update_x64.msi`
3. Restart computer

### Port Conflicts

```powershell
# Check what's using ports (PowerShell as Administrator)
netstat -ano | findstr :3000
netstat -ano | findstr :8000

# Kill process if needed (replace <PID> with actual PID)
Stop-Process -Id <PID> -Force

# Or change ports in .env file
notepad .env
# Edit FRONTEND_PORT and BACKEND_PORT
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

# Or use Docker Desktop:
# Docker Desktop → Bug icon → Troubleshoot → Clean / Purge data

# Increase Docker Desktop disk size:
# Docker Desktop → Settings → Resources → Disk image size
```

### Windows Firewall Blocking Connections

1. Open **Windows Security**
2. Click **Firewall & network protection**
3. Click **Allow an app through firewall**
4. Find **Docker Desktop**
5. Ensure both **Private** and **Public** are checked

### Hyper-V Not Enabled

Docker Desktop requires Hyper-V:

```powershell
# Enable Hyper-V (PowerShell as Administrator)
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Restart computer when prompted
```

### "Access denied" Errors

**Option 1:** Run PowerShell as Administrator
- Right-click PowerShell → **Run as Administrator**

**Option 2:** Add your user to `docker-users` group
1. Open **Computer Management** (Win + X → Computer Management)
2. Navigate to: Local Users and Groups → Groups → `docker-users`
3. Right-click `docker-users` → **Add to Group**
4. Add your user account
5. Log out and log back in

---

## PowerShell Script Execution

All PowerShell scripts in this project are unsigned. You may encounter execution policy errors.

### Available Scripts

| Script | Purpose | Requires Admin |
|--------|---------|----------------|
| `.\scripts\install.ps1` | Automated installation | **Yes** |
| `.\scripts\uninstall.ps1` | Automated uninstallation | Recommended |
| `.\create-https-cert.ps1` | Generate SSL certificates | **Yes** (optional) |
| `.\scripts\remove-localhost-cert.ps1` | Remove SSL certificate | **Yes** |

### Unblocking Scripts

**Method 1 - Unblock Downloaded Scripts (Recommended):**

```powershell
# Unblock specific script
Unblock-File -Path .\scripts\install.ps1

# Or unblock all scripts
Get-ChildItem -Path .\scripts -Filter "*.ps1" | Unblock-File
Get-ChildItem -Path . -Filter "*.ps1" | Unblock-File
```

**Method 2 - Temporary Execution Policy:**

```powershell
# Bypass for current session only
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Then run the script
.\scripts\install.ps1
```

**Method 3 - User-Level Execution Policy:**

```powershell
# Set policy for current user (persists)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Method 4 - Run as Administrator:**

1. Right-click PowerShell → **Run as Administrator**
2. Navigate to project folder
3. Run:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   .\scripts\install.ps1
   ```

---

## Updating

### Download Latest Version

1. **Stop services:**
   ```powershell
   docker compose down
   ```

2. **Download latest version:**
   - Visit https://github.com/zachatkinson/csfrace-scrape
   - Click **Code** → **Download ZIP**
   - Save to Desktop

3. **Replace old files:**
   - Extract new ZIP file
   - Delete or rename old `csfrace-scrape-master` folder
   - Move new folder to Desktop

4. **Rebuild and restart:**
   ```powershell
   cd "$env:USERPROFILE\Desktop\csfrace-scrape-master"
   docker compose build
   docker compose up -d
   ```

---

## Uninstalling

### Automated Uninstall (Recommended)

```powershell
# Unblock the script
Unblock-File -Path .\scripts\uninstall.ps1

# Run the uninstaller (as Administrator recommended)
.\scripts\uninstall.ps1
```

**The script will remove:**
- ✅ All Docker containers and images
- ✅ All database data (PostgreSQL)
- ✅ All cache data (Redis)
- ✅ All metrics/dashboards (Grafana, Prometheus)
- ✅ All scraped output files
- ✅ All SSL certificate files
- ✅ SSL certificate from Windows Trusted Root store
- ✅ Environment configuration (.env)
- ✅ Docker build cache

**Preserved:**
- Source code (Git repository)
- Base Docker images (postgres, redis, nginx, etc.)

### Manual Complete Removal

<details>
<summary>Click to expand manual uninstall steps</summary>

```powershell
# Stop and remove everything
docker compose down -v

# Remove images
docker rmi csfrace-scrape-backend csfrace-scrape-frontend

# Remove volumes
docker volume rm csfrace-scrape_postgres-data
docker volume rm csfrace-scrape_redis-data
docker volume rm csfrace-scrape_grafana-data
docker volume rm csfrace-scrape_prometheus-data

# Remove SSL certificate files
Remove-Item -Recurse -Force nginx\ssl

# Remove SSL certificate from Windows store
.\scripts\remove-localhost-cert.ps1

# Remove .env file
Remove-Item .env

# Remove source code
cd ..
Remove-Item -Recurse -Force csfrace-scrape-master

# Optional: Uninstall Docker Desktop
# Settings → Apps → Docker Desktop → Uninstall
```

</details>

---

## Performance Tuning

### Docker Desktop Settings

For better performance:

1. Open **Docker Desktop → Settings → Resources**
2. Adjust resource limits:
   - **CPUs**: 4+ cores recommended
   - **Memory**: 8GB+ recommended
   - **Disk**: 60GB+ recommended
3. Click **Apply & Restart**

### WSL 2 Integration

Ensure proper WSL 2 integration:

1. **Docker Desktop → Settings → Resources → WSL Integration**
2. Enable integration with your WSL 2 distributions
3. Click **Apply & Restart**

---

## Development vs Production

### Development Mode (Default with docker-compose.override.yml)

```powershell
docker compose up -d

# Features:
# - Hot reload enabled
# - Debug logging
# - Source maps
# - Development dependencies
```

### Production Mode

```powershell
# Temporarily rename override file
Rename-Item docker-compose.override.yml docker-compose.override.yml.backup

# Start in production mode
docker compose up -d

# Restore override when done
Rename-Item docker-compose.override.yml.backup docker-compose.override.yml
```

---

## Getting Help

- **Documentation**: Main [README.md](README.md)
- **Windows-Specific Issues**: Check this guide first
- **GitHub Issues**: [github.com/zachatkinson/csfrace-scrape/issues](https://github.com/zachatkinson/csfrace-scrape/issues)
- **Logs**: Always check `docker compose logs -f` first

---

## Next Steps

After successful installation:

1. **Configure OAuth** (optional): [SETUP_APPLE_OAUTH.md](SETUP_APPLE_OAUTH.md)
2. **Review API**: Browse https://localhost/docs
3. **Explore Frontend**: Open https://localhost
4. **Monitor Performance**: Check Grafana at http://localhost:3001

---

**Need help?** Check logs first: `docker compose logs -f`

**Found a bug?** [Report it on GitHub](https://github.com/zachatkinson/csfrace-scrape/issues)
