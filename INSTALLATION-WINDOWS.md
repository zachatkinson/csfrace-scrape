# CSFrace Scrape - Windows Installation Guide

Complete installation guide for Windows 10/11.

## Running PowerShell Scripts on Windows

All PowerShell scripts in this project are unsigned. Before running any `.ps1` script, you need to unblock it.

### Available PowerShell Scripts

**IMPORTANT**: All scripts should be run as Administrator (right-click PowerShell → "Run as Administrator")

| Script | Purpose | Requires Admin |
|--------|---------|----------------|
| `.\scripts\install.ps1` | Automated installation | **Yes** - Adds SSL certificates to system trust store |
| `.\scripts\uninstall.ps1` | Automated uninstallation | No - But recommended for cleanup |
| `.\create-https-cert.ps1` | Generate SSL certificates | **Yes** - Adds to system trust store (optional - install does this) |
| `.\scripts\remove-localhost-cert.ps1` | Remove SSL certificate | **Yes** - Removes from system trust store |

### Unblocking Scripts

```powershell
# Unblock a specific script (recommended)
Unblock-File -Path .\scripts\install.ps1

# Or unblock all scripts at once
Get-ChildItem -Path .\scripts -Filter "*.ps1" | Unblock-File
Get-ChildItem -Path . -Filter "*.ps1" | Unblock-File
```

**Alternative**: Set execution policy for current session (temporary):
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

See the [Permission Issues & Script Execution](#permission-issues--script-execution) section for more options.

## Prerequisites

### Required Software

1. **PowerShell 7 or higher**
   - Download: [Installing PowerShell on Windows](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5)
   - **Quick install**: `winget install Microsoft.PowerShell`
   - **Note**: Windows comes with PowerShell 5.1 by default - you need to upgrade to PowerShell 7+

2. **Docker Desktop for Windows**
   - Download: [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
   - **Minimum version**: Docker 24.0+, Docker Compose 2.20+
   - Requires **WSL 2** (Windows Subsystem for Linux 2)

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

1. **Download the project**:
   - Visit https://github.com/zachatkinson/csfrace-scrape
   - Click the green **Code** button
   - Select **Download ZIP**
   - Save to your **Desktop**

2. **Extract the files**:
   - Right-click the downloaded ZIP file on your Desktop
   - Select **Extract All...**
   - Click **Extract** (it will create a folder on your Desktop)

3. **Run the installer as Administrator**:

   **IMPORTANT**: The installer requires Administrator privileges to add SSL certificates to your system's trust store.

   - Open PowerShell as Administrator:
     - Press `Win + X` and select **Windows PowerShell (Admin)** or **Terminal (Admin)**
     - Or: Right-click the PowerShell icon and select **Run as Administrator**

   - Navigate to the extracted folder:
     ```powershell
     cd "$env:USERPROFILE\Desktop\csfrace-scrape-master"
     ```

   - Unblock and run the installer:
     ```powershell
     # Unblock the script (required for unsigned scripts)
     Unblock-File -Path .\scripts\install.ps1

     # Run the installer
     .\scripts\install.ps1
     ```

The automated script will:
1. ✅ Clean up any existing containers and volumes
2. ✅ Create fresh environment configuration
3. ✅ Generate HTTPS certificates (using native PowerShell)
4. ✅ Build Docker images (5-10 minutes)
5. ✅ Start all services
6. ✅ Run health checks
7. ✅ Verify everything works

**That's it!** The script handles everything automatically, including HTTPS setup using native PowerShell certificate generation.

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

### Step 2: Download Project Files

1. Visit https://github.com/zachatkinson/csfrace-scrape
2. Click the green **Code** button
3. Select **Download ZIP**
4. Save to your **Desktop** (or preferred location)
5. Extract the ZIP file:
   - Right-click the downloaded ZIP file
   - Select **Extract All...**
   - Click **Extract** (creates `csfrace-scrape-master` folder)
6. Open PowerShell in the extracted folder:
   - Open the `csfrace-scrape-master` folder
   - Hold **Shift** and right-click inside the folder
   - Select **Open PowerShell window here**

**Note:** To update the project later, download the latest ZIP file from GitHub and replace the old folder.

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

### Step 6: Setup HTTPS (Optional)

**Note**: If you used the automated installer (Quick Start), HTTPS certificates were already created. This step is only needed if you're doing a manual installation or want to regenerate certificates.

For secure local development and OAuth support:

```powershell
# Unblock the script (required for unsigned scripts)
Unblock-File -Path .\create-https-cert.ps1

# Generate self-signed SSL certificates
.\create-https-cert.ps1

# Restart nginx to load new certificates
docker compose restart nginx
```

The script will:
- Check if valid certificates already exist (reuses them if found)
- Generate SSL certificates for localhost if needed
- Add certificate to Windows Trusted Root store
- Enable HTTPS access at https://localhost

**Important Notes:**
- **Script Execution**: You may need to run `Unblock-File -Path .\create-https-cert.ps1` before running the script (see Permission Issues section)
- Certificates are **shared across projects** and persist after uninstall
- Existing valid certificates are automatically reused
- Certificates expire after 365 days (script will notify you)
- You may need to run PowerShell as Administrator for certificate installation
- To remove the certificate from your system: Run `Unblock-File -Path .\scripts\remove-localhost-cert.ps1` then `.\scripts\remove-localhost-cert.ps1`

### Step 7: Verify Installation

```powershell
# Check service health
docker compose ps

# Test backend API via HTTPS (recommended)
Invoke-RestMethod -Uri https://localhost/health -SkipCertificateCheck

# Or via HTTP (direct backend access)
Invoke-RestMethod -Uri http://localhost:8000/health/

# Open frontend in browser (via nginx)
start https://localhost
```

## Service URLs

Once installed, access the application at:

| Service | URL | Description |
|---------|-----|-------------|
| **Frontend (HTTPS)** | https://localhost | Main web interface (recommended) |
| **Frontend (HTTP)** | http://localhost:3000 | Direct access without nginx |
| **Backend API (HTTPS)** | https://localhost/api | REST API via nginx (recommended) |
| **Backend API (HTTP)** | http://localhost:8000 | Direct backend access without nginx |
| **API Documentation (HTTPS)** | https://localhost/docs | Interactive API docs via nginx (recommended) |
| **API Documentation (HTTP)** | http://localhost:8000/docs | Direct access without nginx |
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

### Performance Tips

For better performance on Windows:

1. **Docker Desktop → Settings → Resources**:
   - **CPUs**: 4+ cores recommended
   - **Memory**: 8GB+ recommended
   - **Disk**: 60GB+ recommended

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

### Permission Issues & Script Execution

If you get errors running PowerShell scripts (e.g., "cannot be loaded because running scripts is disabled"):

**Method 1 - Unblock Downloaded Scripts (Recommended)**:
```powershell
# Unblock specific script files
Unblock-File -Path .\scripts\install.ps1
Unblock-File -Path .\create-https-cert.ps1

# Or unblock all PowerShell scripts in the folder
Get-ChildItem -Path . -Recurse -Filter "*.ps1" | Unblock-File

# Then run the script normally
.\scripts\install.ps1
```

**Method 2 - Temporary Execution Policy Bypass**:
```powershell
# Bypass execution policy for current session only (safest)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Then run the script
.\scripts\install.ps1
```

**Method 3 - Set User-Level Execution Policy**:
```powershell
# Set execution policy for current user (persists across sessions)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then run the script
.\scripts\install.ps1
```

**Method 4 - Run PowerShell as Administrator** (if above methods fail):
```powershell
# Right-click PowerShell icon → Run as Administrator
# Navigate to project folder
cd "$env:USERPROFILE\Desktop\csfrace-scrape-master"

# Set execution policy and run
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\scripts\install.ps1
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

### Download Latest Version

1. **Stop the current services**:
   ```powershell
   docker compose down
   ```

2. **Download the latest version**:
   - Visit https://github.com/zachatkinson/csfrace-scrape
   - Click the green **Code** button
   - Select **Download ZIP**
   - Save to your Desktop

3. **Replace the old files**:
   - Extract the new ZIP file
   - Delete or rename the old `csfrace-scrape-master` folder
   - Move the new folder to your Desktop

4. **Rebuild and restart**:
   - Open PowerShell in the new folder
   - Run:
     ```powershell
     docker compose build
     docker compose up -d
     ```

## Uninstalling

### Automated Uninstall (Recommended)

```powershell
# Unblock the script (required for unsigned scripts)
Unblock-File -Path .\scripts\uninstall.ps1

# Run the uninstall script
.\scripts\uninstall.ps1
```

The script will:
- Stop all Docker containers
- Remove Docker images and build cache
- Ask if you want to delete data volumes (optional)
- Ask if you want to delete output files (optional)
- Remove SSL certificate files
- Preserve Windows certificate store entries (shared across projects)

**Note**: The script preserves `.env`, source code, and shared certificates by default.

### Manual Complete Removal

If you prefer to manually remove everything:

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

# Remove SSL certificate files
Remove-Item -Recurse -Force nginx\ssl

# Remove SSL certificate from Windows store (optional)
Unblock-File -Path .\scripts\remove-localhost-cert.ps1
.\scripts\remove-localhost-cert.ps1

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
2. **Review API**: Browse https://localhost/docs
3. **Explore Frontend**: Open https://localhost
4. **Monitor Performance**: Check Grafana at http://localhost:3001

---

**Need help?** Check the logs first: `docker compose logs -f`
