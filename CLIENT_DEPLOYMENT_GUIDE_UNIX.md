# CSFrace Scrape - macOS/Linux Deployment Guide
## Self-Hosted Installation with Docker Desktop

> **For macOS & Linux Users:** This guide will help you install and run CSFrace Scrape on your Mac or Linux machine

> **Windows Users:** See [CLIENT_DEPLOYMENT_GUIDE.md](CLIENT_DEPLOYMENT_GUIDE.md)

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

CSFrace Scrape is a self-hosted web application that converts WordPress content to Shopify-compatible format. It runs entirely on your computer using Docker.

### Data Persistence

✅ **All your data persists** across restarts and updates via Docker volumes:
- User accounts & conversion jobs (PostgreSQL)
- Cache & sessions (Redis)
- Metrics & dashboards (Prometheus, Grafana)

---

## Prerequisites

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **RAM** | 4GB | 8GB+ |
| **CPU** | 2 cores | 4+ cores |
| **Disk Space** | 10GB free | 20GB+ free |
| **OS** | macOS 10.15+ / Ubuntu 20.04+ | Latest version |

### Required Software

**macOS:**
- Docker Desktop: https://www.docker.com/products/docker-desktop
- Git (pre-installed) or via Homebrew: `brew install git`

**Linux (Ubuntu/Debian):**
- Docker Engine (see installation below)
- Git: `sudo apt-get install git`

---

## Installation Steps

### Step 1: Install Docker

#### macOS

```bash
# Download Docker.dmg from https://www.docker.com/products/docker-desktop
# Double-click Docker.dmg to open the installer
# Drag Docker.app to Applications folder
# Open Docker from Applications
# Wait for Docker to start (whale icon in menu bar)
```

Verify:
```bash
docker --version    # Should show: Docker version 24.0+
docker compose version  # Should show: Docker Compose version v2.20+
```

#### Linux (Ubuntu/Debian)

```bash
# Install Docker Engine
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Log out and log back in for group changes to take effect
newgrp docker

# Verify installation
docker --version
docker compose version
```

### Step 2: Download CSFrace Scrape

```bash
# Navigate to installation directory
cd ~/Applications  # or any directory you prefer

# Download the application
git clone --recurse-submodules https://github.com/zachatkinson/csfrace-scrape.git

# Enter the project directory
cd csfrace-scrape
```

### Step 3: Create Environment Configuration

```bash
# Copy the example file
cp .env.example .env
```

**Edit the `.env` file:**

**CRITICAL: Change these default passwords!**

```bash
# Required: Change these passwords
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
```

**Generate Secure Secrets:**

```bash
# Generate SECRET_KEY (64 characters)
openssl rand -hex 32

# Generate POSTGRES_PASSWORD (32 characters)
openssl rand -base64 24

# Generate GRAFANA_ADMIN_PASSWORD (24 characters)
openssl rand -base64 16
```

Paste these generated values into your `.env` file.

### Step 4: Generate SSL Certificates

```bash
# Create SSL directory
mkdir -p nginx/ssl

# Generate self-signed certificate (valid for 365 days)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/private.key \
  -out nginx/ssl/certificate.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
```

### Step 5: Build and Start the Application

```bash
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

```bash
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
- **Backend API:** https://localhost/api/docs
- **Monitoring Dashboard:** http://localhost:3001 (Grafana)
- **Metrics:** http://localhost:9090 (Prometheus)

**Browser Security Warning:**

Your browser will warn about the self-signed SSL certificate. This is normal:

- **Chrome/Edge:** Click "Advanced" → "Proceed to localhost (unsafe)"
- **Firefox:** Click "Advanced" → "Accept the Risk and Continue"
- **Safari:** Click "Show Details" → "visit this website"

---

## Configuration

### Authentication Methods

CSFrace Scrape supports three modern authentication methods:

#### **1. OAuth Single Sign-On (SSO)** ⭐

Sign in with your existing trusted accounts!

**Supported Providers:**
- Google, GitHub, Microsoft, Facebook, Apple

**Setup:**
See detailed setup guides:
- `SETUP_GOOGLE_OAUTH.md`
- `SETUP_GITHUB_OAUTH.md`
- `SETUP_MICROSOFT_OAUTH.md`
- `SETUP_FACEBOOK_OAUTH.md`
- `SETUP_APPLE_OAUTH.md`

#### **2. WebAuthn/Passkeys** 🔐

Biometric authentication:
- Face ID, Touch ID, hardware security keys
- Already configured and ready to use

#### **3. Email/Password** 📧

Traditional authentication:
- Simple email and password registration
- Already configured and ready to use

### Customizing Resource Limits

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

Then restart: `docker compose down && docker compose up -d`

---

## Daily Usage

### Starting the Application

```bash
# Navigate to project directory
cd ~/Applications/csfrace-scrape

# Start all services
docker compose up -d

# Verify all services started
docker compose ps
```

### Stopping the Application

```bash
# Stop all services (data persists)
docker compose down

# Or stop without removing containers (faster restart)
docker compose stop
```

### Viewing Logs

```bash
# View all service logs
docker compose logs -f

# View specific service logs
docker compose logs -f backend
docker compose logs -f frontend

# View last 100 lines
docker compose logs --tail=100
```

### Checking Service Health

```bash
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

All data is stored in Docker volumes:

```bash
# List volumes
docker volume ls | grep csfrace-scrape

# Expected volumes:
# csfrace-scrape_postgres-data    (User accounts, jobs, auth data)
# csfrace-scrape_redis-data       (Cache, sessions)
# csfrace-scrape_prometheus-data  (Metrics history)
# csfrace-scrape_grafana-data     (Dashboards, configs)
```

### Backup Procedure

#### Manual Backup

```bash
# Create backup directory
mkdir -p ~/csfrace-backups/$(date +%Y-%m-%d)

# Backup PostgreSQL database
docker compose exec -T postgres pg_dump -U postgres csfrace > \
  ~/csfrace-backups/$(date +%Y-%m-%d)/database.sql

# Backup Redis data
docker compose exec -T redis redis-cli SAVE
docker cp csfrace-scrape-redis-1:/data/dump.rdb \
  ~/csfrace-backups/$(date +%Y-%m-%d)/redis-dump.rdb

# Backup environment configuration
cp .env ~/csfrace-backups/$(date +%Y-%m-%d)/env-backup

# Create tarball
tar -czf ~/csfrace-backups/backup-$(date +%Y-%m-%d).tar.gz \
  -C ~/csfrace-backups/$(date +%Y-%m-%d) .
```

#### Automated Backup Script

Save this as `backup.sh` in your project directory:

```bash
#!/bin/bash
# CSFrace Scrape Automated Backup Script

BACKUP_DIR="$HOME/csfrace-backups"
DATE=$(date +%Y-%m-%d-%H%M%S)
BACKUP_PATH="$BACKUP_DIR/$DATE"

# Create backup directory
mkdir -p "$BACKUP_PATH"

echo "Starting backup at $(date)"

# Backup PostgreSQL
echo "Backing up PostgreSQL..."
docker compose exec -T postgres pg_dump -U postgres csfrace > "$BACKUP_PATH/database.sql"

# Backup Redis
echo "Backing up Redis..."
docker compose exec -T redis redis-cli SAVE
docker cp csfrace-scrape-redis-1:/data/dump.rdb "$BACKUP_PATH/redis-dump.rdb"

# Backup environment
echo "Backing up configuration..."
cp .env "$BACKUP_PATH/env-backup"

# Create tarball
echo "Creating archive..."
tar -czf "$BACKUP_DIR/csfrace-backup-$DATE.tar.gz" -C "$BACKUP_PATH" .

# Clean up temporary directory
rm -rf "$BACKUP_PATH"

# Keep only last 30 backups
ls -t "$BACKUP_DIR"/csfrace-backup-*.tar.gz | tail -n +31 | xargs rm -f

echo "Backup completed: $BACKUP_DIR/csfrace-backup-$DATE.tar.gz"
```

Make it executable and schedule it:

```bash
# Make executable
chmod +x backup.sh

# Schedule daily backups with cron at 2 AM
crontab -e
# Add this line:
0 2 * * * cd ~/Applications/csfrace-scrape && ./backup.sh >> ~/csfrace-backups/backup.log 2>&1
```

### Restore Procedure

```bash
# Extract backup
tar -xzf ~/csfrace-backups/csfrace-backup-YYYY-MM-DD-HHMMSS.tar.gz -C /tmp/restore

# Stop services
docker compose down

# Restore PostgreSQL
docker compose up -d postgres
sleep 10
docker compose exec -T postgres psql -U postgres -d csfrace < /tmp/restore/database.sql

# Restore Redis
docker cp /tmp/restore/redis-dump.rdb csfrace-scrape-redis-1:/data/dump.rdb
docker compose restart redis

# Restore environment
cp /tmp/restore/env-backup .env

# Start all services
docker compose up -d

# Clean up
rm -rf /tmp/restore
```

---

## Troubleshooting

### Common Issues

#### 1. Port Already in Use

**Error:** `Bind for 0.0.0.0:8000 failed: port is already allocated`

**Solution:**
```bash
# Edit .env file
BACKEND_PORT=8001  # Change from 8000
FRONTEND_PORT=3011  # Change from 3010

# Restart
docker compose down && docker compose up -d
```

#### 2. Services Not Starting

```bash
# Check logs
docker compose logs backend
docker compose logs frontend

# Reset everything (WARNING: Removes all data!)
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

#### 3. Database Connection Errors

```bash
# Check PostgreSQL
docker compose exec postgres pg_isready -U postgres
docker compose logs postgres

# Reset database (WARNING: Deletes all data)
docker compose down
docker volume rm csfrace-scrape_postgres-data
docker compose up -d
```

#### 4. Out of Disk Space

```bash
# Check Docker disk usage
docker system df

# Clean up (WARNING: Removes unused data)
docker system prune -a --volumes
```

#### 5. Permission Denied (Linux)

```bash
# Ensure user is in docker group
sudo usermod -aG docker $USER
newgrp docker

# Or run with sudo
sudo docker compose up -d
```

### Getting Help

Collect diagnostic information:

```bash
# Save logs
docker compose logs > csfrace-logs.txt

# Save system info
docker version > system-info.txt
docker compose ps >> system-info.txt
docker system df >> system-info.txt
```

Contact support: support@yourcompany.com (include logs)

---

## Updating

### Checking for Updates

```bash
cd ~/Applications/csfrace-scrape
git fetch origin
git log HEAD..origin/master --oneline  # Shows new changes
```

### Update Procedure

```bash
# 1. Backup first!
./backup.sh

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

```bash
# Stop services
docker compose down

# Revert to previous version
git log --oneline  # Find previous commit hash
git checkout <previous-commit-hash>
git submodule update --init --recursive

# Restore backup (see Restore section)

# Start services
docker compose up -d
```

---

## Uninstallation

### Complete Removal

```bash
# 1. Backup first if you want to keep data!
./backup.sh

# 2. Stop and remove all containers
docker compose down -v  # WARNING: Removes all volumes!

# 3. Remove images
docker images 'csfrace-scrape*' -q | xargs docker rmi

# 4. Remove project directory
cd ..
rm -rf csfrace-scrape
```

### Keeping Data for Later

```bash
# Stop containers but keep volumes
docker compose down

# Remove project directory
cd ..
rm -rf csfrace-scrape

# Your data volumes remain
docker volume ls | grep csfrace-scrape

# To reinstall later: Follow installation steps, data will be restored
```

---

## Security Best Practices

1. **Change default passwords** immediately after installation
2. **Regular updates** - check weekly, apply patches immediately
3. **Network security** - don't expose database ports externally
4. **Backup encryption:**

```bash
# Encrypt backup with GPG
gpg -c ~/csfrace-backups/csfrace-backup-YYYY-MM-DD.tar.gz

# Decrypt backup
gpg ~/csfrace-backups/csfrace-backup-YYYY-MM-DD.tar.gz.gpg
```

---

## Appendix

### Docker Desktop Settings (macOS)

**Recommended settings:**
1. **Resources → Memory:** 6GB minimum, 8GB recommended
2. **Resources → CPUs:** 4 cores minimum
3. **Resources → Disk:** 50GB minimum
4. **General → Start Docker Desktop when you log in:** ✅ Enabled

### Useful Commands

```bash
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
- Windows Guide: `CLIENT_DEPLOYMENT_GUIDE.md`

**Contact:**
- Email: support@yourcompany.com
- GitHub Issues: https://github.com/zachatkinson/csfrace-scrape/issues

**Community:**
- Discussions: https://github.com/zachatkinson/csfrace-scrape/discussions

---

**Last Updated:** 2025-10-15
**Version:** 1.0.0
**Platform:** macOS / Linux
