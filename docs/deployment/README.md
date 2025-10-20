# CSFrace Scrape - Windows Deployment Guide
## Self-Hosted Installation with Docker Desktop

> **For Windows Users:** This guide will help you install and run CSFrace Scrape on your Windows PC

> **macOS/Linux Users:** See [CLIENT_DEPLOYMENT_GUIDE_UNIX.md](CLIENT_DEPLOYMENT_GUIDE_UNIX.md)

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Installation Steps](#installation-steps)
4. [Configuration](#configuration)
5. [Daily Usage](#daily-usage)
6. [Data Persistence & Backups](#data-persistence--backups)
7. [Troubleshooting](#troubleshooting)
8. [Updating](#updating)
9. [Uninstallation](#uninstallation)

---

## Overview

### What is CSFrace Scrape?

CSFrace Scrape is a self-hosted web application that converts WordPress content to Shopify-compatible format. It runs entirely on your computer using Docker Desktop.

### Architecture

```
Your Computer (Docker Desktop)
├── Backend (Python/FastAPI) - Content conversion engine
├── Frontend (Astro/React) - Web interface
├── PostgreSQL - User accounts and job data
├── Redis - Cache and sessions
├── Nginx - Routing and HTTPS
├── Prometheus - Metrics collection
└── Grafana - Monitoring dashboards
```

### Data Persistence

✅ **All your data persists** across restarts and updates:
- **User accounts** (PostgreSQL volume: `postgres-data`)
- **Conversion jobs** (PostgreSQL volume: `postgres-data`)
- **Session data** (Redis volume: `redis-data`)
- **Metrics history** (Prometheus volume: `prometheus-data`)
- **Dashboard configs** (Grafana volume: `grafana-data`)

---

## Prerequisites

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **RAM** | 4GB | 8GB+ |
| **CPU** | 2 cores | 4+ cores |
| **Disk Space** | 10GB free | 20GB+ free |
| **OS** | Windows 10+ (64-bit) | Windows 11 |

### Required Software

1. **Docker Desktop** (includes Docker Compose)
   - Download: https://www.docker.com/products/docker-desktop
   - Minimum version: Docker 20.10+ with Compose V2

2. **Git for Windows**
   - Download: https://git-scm.com/download/win
   - Includes OpenSSL (needed for SSL certificates)

---

## Installation Steps

### Step 1: Install Docker Desktop

1. **Download Docker Desktop Installer**
   - Visit: https://www.docker.com/products/docker-desktop
   - Download "Docker Desktop for Windows"

2. **Run the installer**
   - Double-click `Docker Desktop Installer.exe`
   - Follow the installation wizard
   - Enable WSL 2 feature when prompted (recommended)
   - Click "Install" and wait for completion

3. **Restart your computer** when prompted

4. **Start Docker Desktop**
   - Find Docker Desktop in your Start menu
   - Wait for Docker to start (whale icon appears in system tray)
   - Accept the Docker subscription agreement

5. **Verify Installation**

Open **PowerShell** and run:
```powershell
docker --version
# Should show: Docker version 24.0+

docker compose version
# Should show: Docker Compose version v2.20+
```

### Step 2: Download CSFrace Scrape

Open **PowerShell** and run:

```powershell
# Navigate to where you want to install (Documents is recommended)
cd $HOME\Documents

# Download the application
git clone --recurse-submodules https://github.com/zachatkinson/csfrace-scrape.git

# Enter the project directory
cd csfrace-scrape
```

### Step 3: Create Environment Configuration

Create your environment configuration file:

```powershell
# Copy the example file
Copy-Item .env.example .env
```

**Edit the `.env` file** (right-click → Edit with Notepad):

**CRITICAL: Change these default passwords!**

```bash
# REQUIRED: Change these passwords!
POSTGRES_PASSWORD=your-secure-postgres-password-here
GRAFANA_ADMIN_PASSWORD=your-secure-grafana-password-here
SECRET_KEY=your-secret-key-here-use-generator-below

# OAuth Providers (see Configuration section for setup)
OAUTH_GOOGLE_CLIENT_ID=
OAUTH_GOOGLE_CLIENT_SECRET=
OAUTH_GITHUB_CLIENT_ID=
OAUTH_GITHUB_CLIENT_SECRET=
OAUTH_MICROSOFT_CLIENT_ID=
OAUTH_MICROSOFT_CLIENT_SECRET=
OAUTH_FACEBOOK_CLIENT_ID=
OAUTH_FACEBOOK_CLIENT_SECRET=
OAUTH_APPLE_CLIENT_ID=
OAUTH_APPLE_CLIENT_SECRET=

# Optional: Customize ports (only if defaults conflict)
BACKEND_PORT=8000
FRONTEND_PORT=3010
POSTGRES_PORT=5432
```

**Generate Secure Secrets** in PowerShell:

```powershell
# Generate SECRET_KEY (copy the output)
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))

# Generate POSTGRES_PASSWORD (copy the output)
[Convert]::ToBase64String((1..24 | ForEach-Object { Get-Random -Maximum 256 }))

# Generate GRAFANA_ADMIN_PASSWORD (copy the output)
[Convert]::ToBase64String((1..16 | ForEach-Object { Get-Random -Maximum 256 }))
```

Paste these generated values into your `.env` file.

### Step 4: Generate SSL Certificates

SSL certificates enable HTTPS for secure connections.

```powershell
# Create SSL directory
New-Item -ItemType Directory -Force -Path nginx\ssl

# Generate self-signed certificate (valid for 365 days)
# Note: OpenSSL comes with Git for Windows
openssl req -x509 -nodes -days 365 -newkey rsa:2048 `
  -keyout nginx\ssl\private.key `
  -out nginx\ssl\certificate.crt `
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
```

**If openssl is not found:**
- Restart PowerShell
- Or install OpenSSL from: https://slproweb.com/products/Win32OpenSSL.html

### Step 5: Build and Start the Application

```powershell
# Pull and build Docker images (first time takes 5-15 minutes)
docker compose pull
docker compose build

# Start all services
docker compose up -d

# View startup logs (wait for all services to be healthy)
docker compose logs -f
# Press Ctrl+C to stop viewing logs (services keep running)
```

### Step 6: Verify Installation

Wait about 60 seconds for all services to start:

```powershell
# Check all services are healthy
docker compose ps
```

**Expected output:**
```
NAME                       STATUS
csfrace-scrape-backend-1   Up (healthy)
csfrace-scrape-frontend-1  Up (healthy)
csfrace-scrape-postgres-1  Up (healthy)
csfrace-scrape-redis-1     Up (healthy)
csfrace-scrape-nginx-1     Up
csfrace-scrape-prometheus-1 Up (healthy)
csfrace-scrape-grafana-1   Up (healthy)
```

### Step 7: Access the Application

Open your web browser and navigate to:

- **Main Application:** https://localhost
- **Backend API:** https://localhost/api/docs (Interactive API documentation)
- **Monitoring Dashboard:** http://localhost:3001 (Grafana)
- **Metrics:** http://localhost:9090 (Prometheus)

**Browser Security Warning:**

Your browser will warn about the self-signed SSL certificate. This is normal for local development:

- **Chrome/Edge:** Click "Advanced" → "Proceed to localhost (unsafe)"
- **Firefox:** Click "Advanced" → "Accept the Risk and Continue"

---

## Configuration

### Authentication Methods

CSFrace Scrape supports three modern authentication methods that can be used together:

#### **1. OAuth Single Sign-On (SSO)** ⭐

Sign in with your existing trusted accounts - no need to create new passwords!

**Supported Providers:**
- **Google** - Sign in with your Google account
- **GitHub** - Sign in with your GitHub account
- **Microsoft** - Sign in with your Microsoft/Azure account
- **Facebook** - Sign in with your Facebook account
- **Apple** - Sign in with your Apple ID

**Benefits:**
- Professional, modern authentication experience
- No need to remember additional passwords
- Secure OAuth 2.0 flows
- Leverages accounts you already trust

**Setup OAuth Providers:**

See these detailed setup guides:
- `SETUP_GOOGLE_OAUTH.md` - Setup Google OAuth credentials
- `SETUP_GITHUB_OAUTH.md` - Setup GitHub OAuth credentials
- `SETUP_MICROSOFT_OAUTH.md` - Setup Microsoft OAuth credentials
- `SETUP_FACEBOOK_OAUTH.md` - Setup Facebook OAuth credentials
- `SETUP_APPLE_OAUTH.md` - Setup Apple OAuth credentials

After configuring providers, add the credentials to your `.env` file.

#### **2. WebAuthn/Passkeys** 🔐

Modern, passwordless biometric authentication:
- Windows Hello (fingerprint, face recognition, PIN)
- Hardware security keys (YubiKey, etc.)
- Most secure authentication method
- Already configured and ready to use

#### **3. Email/Password** 📧

Traditional authentication for maximum compatibility:
- Simple email and password registration
- No external dependencies
- Works completely offline
- Already configured and ready to use

**Recommendation:** Use OAuth SSO or WebAuthn for the best user experience and security!

### Customizing Resource Limits

If your system has more (or less) RAM available, you can adjust resource limits.

Edit `.env` file:

```bash
# For low-resource systems (4GB RAM)
BACKEND_MEMORY_LIMIT=1g
FRONTEND_MEMORY_LIMIT=512m
POSTGRES_MEMORY_LIMIT=1g
REDIS_MEMORY_LIMIT=256m

# For high-resource systems (16GB+ RAM)
BACKEND_MEMORY_LIMIT=4g
FRONTEND_MEMORY_LIMIT=2g
POSTGRES_MEMORY_LIMIT=4g
REDIS_MEMORY_LIMIT=2g
SCRAPER_CONCURRENT_REQUESTS=20
```

Then restart: `docker compose down` and `docker compose up -d`

---

## Daily Usage

### Starting the Application

```powershell
# Navigate to project directory
cd $HOME\Documents\csfrace-scrape

# Start all services
docker compose up -d

# Verify all services started
docker compose ps
```

### Stopping the Application

```powershell
# Stop all services (data persists)
docker compose down

# Or stop without removing containers (faster restart)
docker compose stop
```

### Viewing Logs

```powershell
# View all service logs
docker compose logs -f

# View specific service logs
docker compose logs -f backend
docker compose logs -f frontend

# View last 100 lines
docker compose logs --tail=100
```

### Checking Service Health

```powershell
# Check all services
docker compose ps

# Check backend health endpoint
curl -k https://localhost/health/

# Check database connection
docker compose exec postgres pg_isready -U postgres
```

---

## Data Persistence & Backups

### Understanding Data Storage

All your data is stored in Docker volumes and persists automatically:

```powershell
# List volumes
docker volume ls | Select-String csfrace-scrape
```

**Volumes:**
- `csfrace-scrape_postgres-data` - User accounts, jobs, auth data
- `csfrace-scrape_redis-data` - Cache, sessions
- `csfrace-scrape_prometheus-data` - Metrics history
- `csfrace-scrape_grafana-data` - Dashboards, configs

### Backup Procedure

#### Manual Backup

```powershell
# Create backup directory
$BackupDate = Get-Date -Format "yyyy-MM-dd"
New-Item -ItemType Directory -Force -Path "$HOME\csfrace-backups\$BackupDate"

# Backup PostgreSQL database
docker compose exec -T postgres pg_dump -U postgres csfrace > "$HOME\csfrace-backups\$BackupDate\database.sql"

# Backup Redis data
docker compose exec -T redis redis-cli SAVE
docker cp csfrace-scrape-redis-1:/data/dump.rdb "$HOME\csfrace-backups\$BackupDate\redis-dump.rdb"

# Backup environment configuration
Copy-Item .env "$HOME\csfrace-backups\$BackupDate\env-backup"

# Create archive
Compress-Archive -Path "$HOME\csfrace-backups\$BackupDate\*" -DestinationPath "$HOME\csfrace-backups\backup-$BackupDate.zip"
```

#### Automated Backup Script

Save this as `backup.ps1` in your project directory:

```powershell
# CSFrace Scrape Automated Backup Script
$BackupDir = "$HOME\csfrace-backups"
$DateTime = Get-Date -Format "yyyy-MM-dd-HHmmss"
$BackupPath = "$BackupDir\$DateTime"

# Create backup directory
New-Item -ItemType Directory -Force -Path $BackupPath | Out-Null

Write-Host "Starting backup at $(Get-Date)"

# Backup PostgreSQL
Write-Host "Backing up PostgreSQL..."
docker compose exec -T postgres pg_dump -U postgres csfrace > "$BackupPath\database.sql"

# Backup Redis
Write-Host "Backing up Redis..."
docker compose exec -T redis redis-cli SAVE | Out-Null
docker cp csfrace-scrape-redis-1:/data/dump.rdb "$BackupPath\redis-dump.rdb"

# Backup environment
Write-Host "Backing up configuration..."
Copy-Item .env "$BackupPath\env-backup"

# Create archive
Write-Host "Creating archive..."
Compress-Archive -Path "$BackupPath\*" -DestinationPath "$BackupDir\csfrace-backup-$DateTime.zip"

# Clean up temporary directory
Remove-Item -Recurse -Force $BackupPath

# Keep only last 30 backups
Get-ChildItem "$BackupDir\csfrace-backup-*.zip" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip 30 |
    Remove-Item

Write-Host "Backup completed: $BackupDir\csfrace-backup-$DateTime.zip"
```

**Schedule Automated Backups:**

1. Open **Task Scheduler** (search in Start menu)
2. Click "Create Basic Task"
3. Name: "CSFrace Scrape Backup"
4. Trigger: Daily at 2:00 AM
5. Action: Start a program
   - Program: `powershell.exe`
   - Arguments: `-File "C:\Users\YourUsername\Documents\csfrace-scrape\backup.ps1"`
6. Click Finish

### Restore Procedure

```powershell
# Extract backup
Expand-Archive -Path "$HOME\csfrace-backups\backup-YYYY-MM-DD-HHMMSS.zip" -DestinationPath "$HOME\csfrace-backups\restore"

# Stop services
docker compose down

# Restore PostgreSQL
docker compose up -d postgres
Start-Sleep -Seconds 10
Get-Content "$HOME\csfrace-backups\restore\database.sql" | docker compose exec -T postgres psql -U postgres -d csfrace

# Restore Redis
docker cp "$HOME\csfrace-backups\restore\redis-dump.rdb" csfrace-scrape-redis-1:/data/dump.rdb
docker compose restart redis

# Restore environment
Copy-Item "$HOME\csfrace-backups\restore\env-backup" .env

# Start all services
docker compose up -d

# Clean up
Remove-Item -Recurse -Force "$HOME\csfrace-backups\restore"
```

---

## Troubleshooting

### Common Issues

#### 1. Port Already in Use

**Error:** `Bind for 0.0.0.0:8000 failed: port is already allocated`

**Solution:** Change the port in `.env`:
```bash
# Edit .env file
BACKEND_PORT=8001  # Change from 8000
FRONTEND_PORT=3011  # Change from 3010
```

Then restart:
```powershell
docker compose down
docker compose up -d
```

#### 2. Services Not Starting

**Check logs:**
```powershell
docker compose logs backend
docker compose logs frontend
```

**Common causes:**
- Insufficient memory (increase Docker Desktop memory limit in Settings)
- Missing environment variables (check `.env` file)
- Database migration failures (check backend logs)

**Solution - Reset everything:**
```powershell
# WARNING: This removes all data!
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

#### 3. Frontend Can't Connect to Backend

**Check backend health:**
```powershell
curl -k https://localhost/health/
```

**Check nginx logs:**
```powershell
docker compose logs nginx
```

**Solution:** Verify CORS settings in `.env`:
```bash
CORS_ORIGINS=http://localhost:3010,https://localhost
```

#### 4. Database Connection Errors

**Check PostgreSQL:**
```powershell
docker compose exec postgres pg_isready -U postgres
docker compose logs postgres
```

**Solution - Reset database (WARNING: Deletes all data):**
```powershell
docker compose down
docker volume rm csfrace-scrape_postgres-data
docker compose up -d
```

#### 5. Out of Disk Space

**Check Docker disk usage:**
```powershell
docker system df
```

**Clean up unused images/containers:**
```powershell
# WARNING: Removes unused Docker data
docker system prune -a --volumes
```

#### 6. Docker Desktop Not Starting

**Common causes:**
- WSL 2 not installed or enabled
- Hyper-V not enabled
- Insufficient system resources

**Solution:**
1. Enable WSL 2:
   ```powershell
   wsl --install
   ```
2. Enable Hyper-V (Windows Pro/Enterprise):
   - Control Panel → Programs → Turn Windows features on or off
   - Check "Hyper-V"
   - Restart computer

3. Increase Docker Desktop resources:
   - Open Docker Desktop → Settings → Resources
   - Increase Memory to 6GB+
   - Increase CPU to 4 cores

### Getting Help

If you can't resolve an issue:

1. **Collect diagnostic information:**
```powershell
# Save logs
docker compose logs > csfrace-logs.txt

# Save system info
docker version > system-info.txt
docker compose ps >> system-info.txt
docker system df >> system-info.txt
```

2. **Check documentation:**
   - Backend docs: `backend\README.md`
   - Frontend docs: `frontend\README.md`
   - OAuth setup: `SETUP_*_OAUTH.md` files

3. **Contact support:** support@yourcompany.com (include logs)

---

## Updating

### Checking for Updates

```powershell
cd $HOME\Documents\csfrace-scrape
git fetch origin
git log HEAD..origin/master --oneline  # Shows new changes
```

### Update Procedure

```powershell
# 1. Backup first! (see Backup section above)
.\backup.ps1

# 2. Stop services
docker compose down

# 3. Pull latest code
git pull origin master
git submodule update --remote --merge

# 4. Pull latest images
docker compose pull

# 5. Rebuild if needed
docker compose build

# 6. Start services
docker compose up -d

# 7. Check health
docker compose ps
docker compose logs -f
```

### Rolling Back an Update

If the update causes issues:

```powershell
# Stop services
docker compose down

# Revert to previous version
git log --oneline  # Find previous commit hash
git checkout <previous-commit-hash>
git submodule update --init --recursive

# Restore backup (see Restore section above)

# Start services
docker compose up -d
```

---

## Uninstallation

### Complete Removal

```powershell
# 1. Backup first if you want to keep data!
.\backup.ps1

# 2. Stop and remove all containers
docker compose down -v  # WARNING: Removes all volumes!

# 3. Remove images
docker images 'csfrace-scrape*' -q | ForEach-Object { docker rmi $_ }

# 4. Remove project directory
cd ..
Remove-Item -Recurse -Force csfrace-scrape

# 5. (Optional) Uninstall Docker Desktop
# Control Panel → Programs → Uninstall Docker Desktop
```

### Keeping Data for Later

If you want to uninstall but keep your data:

```powershell
# Stop containers but keep volumes
docker compose down

# Remove project directory
cd ..
Remove-Item -Recurse -Force csfrace-scrape

# Your data volumes remain:
docker volume ls | Select-String csfrace-scrape

# To reinstall later: Follow installation steps, and your data will be restored
```

---

## Security Best Practices

### 1. Change Default Passwords

**Immediately after installation:**
- Edit `.env` file
- Change `POSTGRES_PASSWORD`
- Change `GRAFANA_ADMIN_PASSWORD`
- Change `SECRET_KEY`

Use the PowerShell generators from Step 3.

### 2. Regular Updates

- Check for updates weekly
- Apply security patches immediately
- Subscribe to security notifications

### 3. Network Security

- Keep CSFrace behind Windows Firewall
- Don't expose ports 5432 (PostgreSQL) or 6379 (Redis) externally
- Only expose port 443 (HTTPS) if remote access is needed

### 4. Backup Encryption

Encrypt your backups using Windows EFS or third-party tools like 7-Zip:

```powershell
# Encrypt with 7-Zip (install from https://www.7-zip.org/)
7z a -p -mhe=on "$HOME\csfrace-backups\backup-encrypted.7z" "$HOME\csfrace-backups\backup-YYYY-MM-DD.zip"
```

---

## Appendix

### Docker Desktop Settings

**Recommended settings:**

1. Open Docker Desktop → Settings
2. **Resources → Memory:** 6GB minimum, 8GB recommended
3. **Resources → CPUs:** 4 cores minimum
4. **Resources → Disk image size:** 50GB minimum
5. **General → Start Docker Desktop when you log in:** ✅ Enabled

### Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `ENVIRONMENT` | `production` | Environment mode |
| `BACKEND_PORT` | `8000` | Backend API port |
| `FRONTEND_PORT` | `3010` | Frontend web UI port |
| `POSTGRES_PORT` | `5432` | PostgreSQL port (internal) |
| `POSTGRES_USER` | `postgres` | Database username |
| `POSTGRES_PASSWORD` | (required) | Database password |
| `POSTGRES_DB` | `csfrace` | Database name |
| `REDIS_PORT` | `6379` | Redis port (internal) |
| `SECRET_KEY` | (required) | Application secret key |
| `GRAFANA_ADMIN_USER` | `admin` | Grafana username |
| `GRAFANA_ADMIN_PASSWORD` | (required) | Grafana password |
| `SCRAPER_CONCURRENT_REQUESTS` | `10` | Concurrent scraping jobs |

### Useful Commands Reference

```powershell
# Start services
docker compose up -d

# Stop services
docker compose down

# Restart a specific service
docker compose restart backend

# View logs
docker compose logs -f

# Execute command in container
docker compose exec backend python --version

# Access database shell
docker compose exec postgres psql -U postgres -d csfrace

# Access Redis CLI
docker compose exec redis redis-cli

# Check resource usage
docker stats

# Clean up unused resources
docker system prune
```

---

## Support

**Documentation:**
- Main README: `README.md`
- Backend API Docs: https://localhost/api/docs
- macOS/Linux Guide: `CLIENT_DEPLOYMENT_GUIDE_UNIX.md`

**Contact:**
- Email: support@yourcompany.com
- GitHub Issues: https://github.com/zachatkinson/csfrace-scrape/issues

**Community:**
- Discussions: https://github.com/zachatkinson/csfrace-scrape/discussions

---

## License

See `LICENSE` file in the project root.

---

**Last Updated:** 2025-10-15
**Version:** 1.0.0
**Platform:** Windows 10/11
