# CSFrace Scrape - Windows Local Setup (Single-User)

[![Windows 10/11](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![PowerShell 7+](https://img.shields.io/badge/PowerShell-7%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/PowerShell/PowerShell)
[![Docker](https://img.shields.io/badge/Docker-24.0%2B-2496ED?logo=docker&logoColor=white)](https://www.docker.com/products/docker-desktop/)
[![No OAuth Required](https://img.shields.io/badge/OAuth-Not_Required-brightgreen)](https://github.com/zachatkinson/csfrace-scrape)

**Single-user local installation for Windows with NO OAuth setup required.** Perfect for personal scraping on your Windows machine!

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
  - [Required Software](#required-software)
  - [System Requirements](#system-requirements)
- [Quick Start](#quick-start)
  - [One-Command Installation](#one-command-installation)
  - [What the Installer Does](#what-the-installer-does)
- [Service URLs](#service-urls)
- [What This Setup Does](#what-this-setup-does)
  - [Backend Configuration](#backend-configuration)
  - [Frontend Configuration](#frontend-configuration)
  - [Development Mode](#development-mode)
- [Common Commands](#common-commands)
  - [Start/Stop Services](#startstop-services)
  - [View Logs](#view-logs)
  - [Rebuild After Changes](#rebuild-after-changes)
  - [Check Status](#check-status)
- [Uninstalling](#uninstalling)
  - [Automated Uninstall](#automated-uninstall-recommended)
- [Troubleshooting](#troubleshooting)
  - [Services Won't Start](#services-wont-start)
  - [Cannot Find .env File](#cannot-find-env-file)
  - [Port Already in Use](#port-already-in-use)
  - [Frontend Shows Login Page](#frontend-shows-login-page)
  - [Auth Bypassed Not Showing](#auth-bypassed-not-showing-in-logs)
- [Manual Installation](#manual-installation)
- [For Production Deployment](#for-production-deployment)
- [Need Help?](#need-help)

---

## Overview

This guide is for Windows users who want to run CSFrace Scrape **locally for personal use** without setting up OAuth providers.

**Key Benefits:**
- ✅ **No OAuth configuration needed** - Skip Google/GitHub/Facebook setup entirely
- ✅ **No login required** - Direct access to scraping features
- ✅ **Single-user mode** - All jobs belong to "local-user"
- ✅ **One-command install** - Automated setup in minutes
- ✅ **Preserves OAuth code** - Can enable multi-user mode later

**Perfect for:**
- Personal scraping projects
- Local development
- Testing and experimentation
- Single-user deployments

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

**Important:** Docker Desktop must be running before installation.

#### 3. WSL 2 (Windows Subsystem for Linux 2)

Docker Desktop requires WSL 2 to run containers on Windows.

**Install WSL 2:**

1. Open PowerShell as **Administrator**
2. Run:
   ```powershell
   wsl --install
   ```
3. Restart your computer when prompted

**More Info:** [WSL Installation Guide](https://docs.microsoft.com/en-us/windows/wsl/install)

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **RAM** | 4GB | 8GB |
| **Disk Space** | 10GB free | 20GB+ free |
| **CPU** | 2 cores 64-bit | 4+ cores |
| **Windows Version** | Windows 10 version 2004+ | Windows 11 |

---

## Quick Start

### One-Command Installation

**1. Clone the repository:**

```powershell
# Clone with submodules
git clone --recurse-submodules https://github.com/zachatkinson/csfrace-scrape.git
cd csfrace-scrape
```

**2. Run the automated installer (as Administrator):**

> **IMPORTANT:** The installer requires **Administrator privileges** to add SSL certificates to Windows' Trusted Root store.

**Steps:**

1. **Open PowerShell as Administrator:**
   - Press `Win + X`
   - Select **Windows PowerShell (Admin)** or **Terminal (Admin)**
   - Or: Right-click PowerShell icon → **Run as Administrator**

2. **Navigate to the project folder:**
   ```powershell
   cd path\to\csfrace-scrape
   ```

3. **Run the installer:**
   ```powershell
   .\scripts\install-local.ps1
   ```

**That's it!** ✨

The installer will:
- ✅ Check PowerShell 7 and Docker
- ✅ Verify Administrator privileges (required for SSL certificates)
- ✅ Set up environment files automatically
- ✅ Generate SSL certificates and add to Windows Trusted Root store
- ✅ Build Docker containers (5-10 minutes)
- ✅ Start all services
- ✅ Wait for services to be healthy
- ✅ Open your browser to https://localhost

**Expected Duration:** 5-10 minutes (first time)

**When complete, you'll see:**
```
================================================================
  🎉 Installation Complete!
================================================================

Access your application at:

  🌐 Main App:    https://localhost
  📚 API Docs:    https://localhost/docs
  📊 Monitoring:  http://localhost:3001 (admin/admin)

================================================================

✨ NO LOGIN REQUIRED! ✨

This is a single-user local installation.
All scraping jobs will be saved to your local database.
```

### What the Installer Does

The automated installer (`install-local.ps1`) handles everything:

1. **✅ Verifies Requirements**
   - Checks PowerShell 7+
   - Verifies Docker is running

2. **✅ Handles Existing Data**
   - Detects previous installations
   - Prompts to preserve or delete existing data

3. **✅ Environment Configuration**
   - Copies `.env.windows.example` → `.env`
   - Copies `frontend/.env.local.example` → `frontend/.env`
   - Sets `SKIP_AUTH_FOR_DEVELOPMENT=true`
   - Sets `PUBLIC_ENABLE_OAUTH=false`

4. **✅ SSL Certificate Generation**
   - Generates self-signed certificates using PowerShell
   - Exports to nginx-compatible PEM format
   - Adds to Windows Trusted Root Certification Authorities
   - Enables trusted HTTPS access in your browser

5. **✅ Docker Build & Start**
   - Builds backend Docker image
   - Builds frontend Docker image
   - Starts all services with `docker-compose.dev.yml`

6. **✅ Health Checks**
   - Waits up to 60 seconds for services
   - Verifies backend is healthy
   - Shows service URLs

7. **✅ Browser Launch**
   - Auto-opens https://localhost after 5 seconds

---

## Service URLs

Once installed, access the application at:

| Service | URL | Description |
|---------|-----|-------------|
| **Frontend (HTTPS)** | https://localhost | Main application interface (recommended) |
| **Backend API (HTTPS)** | https://localhost/api | API endpoints (recommended) |
| **API Docs (HTTPS)** | https://localhost/docs | Interactive API documentation (recommended) |
| **Grafana** | http://localhost:3001 | Monitoring dashboards (admin/admin) |
| **Prometheus** | http://localhost:9090 | Metrics |
| **pgAdmin** | http://localhost:8080 | Database management (optional) |

**Note:** HTTPS is fully configured with self-signed certificates. Your browser may show a security warning the first time - this is normal for local development. Click "Advanced" and "Proceed to localhost" to continue.

---

## What This Setup Does

### Backend Configuration

The `.env` file created from `.env.windows.example` configures:

- ✅ **`SKIP_AUTH_FOR_DEVELOPMENT=true`** - Bypasses authentication
- ✅ **Creates default user** - All jobs belong to "local-user"
- ✅ **No OAuth setup** - Client IDs/secrets not needed
- ✅ **Development mode** - Better logging, hot-reloading

**How it works:**
```python
# backend/src/auth/dependencies.py
async def get_current_user_from_cookie(...):
    if auth_config.SKIP_AUTH_FOR_DEVELOPMENT:
        logger.debug("Auth bypassed - returning default local user")
        return await get_or_create_default_user(auth_service)
    # Normal OAuth flow (preserved but skipped)
```

### Frontend Configuration

The `frontend/.env` file configures:

- ✅ **`PUBLIC_ENABLE_OAUTH=false`** - Hides login UI
- ✅ **Direct access** - No confusing auth buttons
- ✅ **Simplified interface** - Go straight to scraping features

### Development Mode

Uses `docker-compose.dev.yml` for:
- ✅ HTTPS with self-signed certificates (trusted in Windows)
- ✅ Better logging for debugging
- ✅ Hot-reloading for code changes
- ✅ Smaller resource requirements

**Perfect for local personal use!** 🚀

---

## Common Commands

All commands work in PowerShell or Command Prompt.

### Start/Stop Services

```powershell
# Start services
docker compose -f docker-compose.dev.yml up -d

# Stop services (keeps data)
docker compose -f docker-compose.dev.yml down

# Stop and remove data (WARNING: deletes database)
docker compose -f docker-compose.dev.yml down -v
```

### View Logs

```powershell
# All services
docker compose -f docker-compose.dev.yml logs -f

# Just backend
docker compose -f docker-compose.dev.yml logs -f backend-dev

# Just frontend
docker compose -f docker-compose.dev.yml logs -f frontend-dev

# Last 100 lines
docker compose -f docker-compose.dev.yml logs --tail=100 -f
```

### Rebuild After Changes

```powershell
# Rebuild everything
docker compose -f docker-compose.dev.yml build --no-cache
docker compose -f docker-compose.dev.yml up -d

# Rebuild specific service
docker compose -f docker-compose.dev.yml build backend-dev
docker compose -f docker-compose.dev.yml up -d
```

### Check Status

```powershell
# List running containers
docker compose -f docker-compose.dev.yml ps

# View resource usage
docker stats

# Check service health
docker compose -f docker-compose.dev.yml ps backend-dev
```

---

## Uninstalling

### Automated Uninstall (Recommended)

```powershell
.\scripts\uninstall-local.ps1
```

**The uninstaller lets you choose what to remove:**

1. **Services and containers** ✅ (Always removed)
2. **Data volumes** (PostgreSQL, Redis, job data)
   - Choose **Yes** to start fresh next time
   - Choose **No** to preserve your scraped data
3. **Docker images** (Frees disk space)
   - Choose **Yes** to free ~2-3GB disk space
   - Choose **No** for faster reinstall (5-10 minutes saved)
4. **Configuration files** (.env files)
   - Choose **Yes** to remove all config
   - Choose **No** to keep your settings
5. **Output files** (converted_content/, dev-output/, dev-logs/)
   - Choose **Yes** to remove scraped data files
   - Choose **No** to keep your output
6. **Docker resource pruning** (Cleanup unused Docker resources)
   - Choose **Yes** to free additional space
   - Choose **No** to skip cleanup

**Example session:**
```
================================================================
  CSFrace Scrape - Local Uninstallation (Windows)
================================================================

⚠️  WARNING: This will stop all CSFrace services

Continue with uninstallation? [y/N]: y

⏳ Stopping services...
✅ Services stopped

Do you want to DELETE all data? (database, jobs, etc.) [y/N]: n
✅ Data preserved (volumes kept)

Delete Docker images? [y/N]: n
✅ Images preserved (faster next install)

Delete .env files? [y/N]: n
✅ Configuration files preserved

Delete output files? [y/N]: n
✅ Output files preserved

Prune Docker resources? [y/N]: y
⏳ Pruning Docker resources...
✅ Docker resources pruned

================================================================
  ✅ Uninstallation Complete
================================================================
```

---

## Troubleshooting

### Services Won't Start

**Check Docker is running:**
```powershell
docker ps
```

**Rebuild from scratch:**
```powershell
docker compose -f docker-compose.dev.yml down -v
docker compose -f docker-compose.dev.yml build --no-cache
docker compose -f docker-compose.dev.yml up -d
```

**Check logs for errors:**
```powershell
docker compose -f docker-compose.dev.yml logs -f
```

### Cannot Find .env File

Make sure you copied the example files:

```powershell
# Check if files exist
Test-Path .\.env
Test-Path .\frontend\.env

# If not, copy them
Copy-Item .env.windows.example .env
Copy-Item frontend/.env.local.example frontend/.env
```

### Port Already in Use

Check what's using the ports:

```powershell
# Check port 80 (nginx)
netstat -ano | findstr :80

# Check port 8000 (backend)
netstat -ano | findstr :8000

# Check port 3000 (frontend)
netstat -ano | findstr :3000

# Kill process (replace <PID> with actual PID)
Stop-Process -Id <PID> -Force
```

Or change ports in `.env`:
```powershell
notepad .env
# Edit:
# BACKEND_PORT=8001
# FRONTEND_PORT=3001
```

### Frontend Shows Login Page

Frontend is probably using production config. Check:

```powershell
Get-Content frontend\.env | Select-String "PUBLIC_ENABLE_OAUTH"
```

Should show: `PUBLIC_ENABLE_OAUTH=false`

If not:
```powershell
Copy-Item frontend/.env.local.example frontend/.env -Force
docker compose -f docker-compose.dev.yml restart frontend-dev
```

### "Auth Bypassed" Not Showing in Logs

Check if backend is using correct config:

```powershell
docker compose -f docker-compose.dev.yml exec backend-dev python -c "import os; print('SKIP_AUTH:', os.getenv('SKIP_AUTH_FOR_DEVELOPMENT'))"
```

Should show: `SKIP_AUTH: true`

If not:
```powershell
# Check .env file
Get-Content .\.env | Select-String "SKIP_AUTH"

# Should show: SKIP_AUTH_FOR_DEVELOPMENT=true

# Restart backend
docker compose -f docker-compose.dev.yml restart backend-dev
```

### Docker Desktop Not Starting

```powershell
# Restart Docker service (PowerShell as Administrator)
Stop-Service com.docker.service
Start-Service com.docker.service

# Or restart WSL
wsl --shutdown
# Then start Docker Desktop again
```

### "No space left on device"

```powershell
# Clean Docker system
docker system prune -a --volumes

# Or use Docker Desktop:
# Docker Desktop → Bug icon → Troubleshoot → Clean / Purge data
```

---

## Manual Installation

<details>
<summary>Click to expand manual installation steps</summary>

If you prefer manual setup or the automated installer fails:

```powershell
# 1. Clone repository
git clone --recurse-submodules https://github.com/zachatkinson/csfrace-scrape.git
cd csfrace-scrape

# 2. Copy environment files
Copy-Item .env.windows.example .env
Copy-Item frontend/.env.local.example frontend/.env

# 3. Start services (development mode)
docker compose -f docker-compose.dev.yml up -d

# 4. Wait for services to start (30-60 seconds)
Start-Sleep -Seconds 60

# 5. Open browser
Start-Process https://localhost
```

**Verify services are running:**
```powershell
docker compose -f docker-compose.dev.yml ps
```

**Check logs:**
```powershell
docker compose -f docker-compose.dev.yml logs -f
```

</details>

---

## For Production Deployment

If you later want to deploy this for **multiple users** with OAuth:

1. **Set up OAuth credentials** (Google/GitHub/Facebook/Apple)

2. **Update `.env`:**
   ```bash
   SKIP_AUTH_FOR_DEVELOPMENT=false
   OAUTH_GOOGLE_CLIENT_ID=your-client-id
   OAUTH_GOOGLE_CLIENT_SECRET=your-secret
   ```

3. **Update `frontend/.env`:**
   ```bash
   PUBLIC_ENABLE_OAUTH=true
   ```

4. **Use production compose file:**
   ```powershell
   docker compose up -d
   ```

**All your OAuth code is still there - just disabled for local use!** 🎯

See the [Windows Multi-User Installation Guide](./windows.md) for full production setup.

---

## Need Help?

1. **Check logs:**
   ```powershell
   docker compose -f docker-compose.dev.yml logs -f
   ```

2. **Check service health:**
   ```powershell
   docker compose -f docker-compose.dev.yml ps
   ```

3. **Restart services:**
   ```powershell
   docker compose -f docker-compose.dev.yml restart
   ```

4. **Open an issue:**
   - [GitHub Issues](https://github.com/zachatkinson/csfrace-scrape/issues)

5. **Read more documentation:**
   - [Main README](../../README.md)
   - [Installation Overview](./README.md)
   - [Windows Multi-User Setup](./windows.md)

---

## What Makes This Work?

### Backend (`SKIP_AUTH_FOR_DEVELOPMENT=true`)
- Bypasses authentication at the entry point
- Creates a default "local-user" automatically
- All jobs are owned by this user
- **Zero OAuth code deleted** - just bypassed!

### Frontend (`PUBLIC_ENABLE_OAUTH=false`)
- Hides login/register buttons
- Hides OAuth provider buttons
- Direct access to scraping features

### Development Mode (`docker-compose.dev.yml`)
- Uses HTTPS with self-signed certificates (trusted in Windows)
- Better logging for debugging
- Hot-reloading for code changes
- Smaller resource requirements

---

**Perfect for local personal use!** 🚀

**Need multi-user deployment?** See [Windows Multi-User Installation Guide](./windows.md)

**Ready to start scraping?** Open https://localhost and get started! 🎉
