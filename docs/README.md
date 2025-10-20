# Documentation Index

Welcome to the CSFrace Scrape documentation! All documentation has been organized into categorized folders for easier navigation.

## 📚 Documentation Structure

### 🔧 [Installation Guides](./installation/)

Platform-specific installation instructions:

- **[Installation Overview](./installation/README.md)** - General installation guide
- **[macOS Setup](./installation/macos.md)** - Complete macOS installation with troubleshooting
- **[Windows Setup](./installation/windows.md)** - Windows multi-user installation with OAuth
- **[Windows Local Setup](./installation/windows-local.md)** - Windows single-user (no OAuth required)

### 🚀 [Deployment Guides](./deployment/)

Production deployment documentation:

- **[Deployment Overview](./deployment/README.md)** - Main deployment guide for production
- **[Unix Deployment](./deployment/unix.md)** - Unix/Linux-specific deployment instructions
- **[Architecture Overview](./deployment/architecture.md)** - System architecture and design decisions
- **[Production Checklist](./deployment/production-checklist.md)** - Pre-deployment verification checklist

### 🔐 [OAuth Setup](./oauth/)

OAuth provider configuration guides:

- **[OAuth Overview](./oauth/README.md)** - General OAuth setup guide
- **[Apple OAuth](./oauth/apple.md)** - Apple Sign-In setup
- **[Apple SSO](./oauth/apple-sso.md)** - Apple SSO configuration
- **[Facebook OAuth](./oauth/facebook.md)** - Facebook Login setup
- **[Facebook Testing](./oauth/facebook-testing.md)** - Facebook OAuth testing procedures

### 🛠️ [Development Notes](./development/)

Historical implementation summaries and development guides:

- **[Auth Refactor Summary](./development/auth-refactor-summary.md)** - Cookie-based auth implementation notes
- **[CI/CD Refactor Summary](./development/ci-cd-refactor-summary.md)** - CI/CD pipeline improvements
- **[SSE Refactor Plan](./development/sse-refactor-plan.md)** - Server-Sent Events refactoring
- **[Submodule Setup](./development/submodule-setup.md)** - Git submodule automation
- **[Submodule Best Practices](./development/submodule-best-practices.md)** - Submodule guidelines

---

## 🔍 Quick Links

**Just Getting Started?**
- [Installation Overview](./installation/README.md)
- [Windows Local Setup (Easiest)](./installation/windows-local.md)

**Deploying to Production?**
- [Production Deployment Guide](./deployment/README.md)
- [Production Checklist](./deployment/production-checklist.md)

**Setting Up OAuth?**
- [OAuth Setup Guide](./oauth/README.md)

**Contributing or Understanding Architecture?**
- [Development Notes](./development/)
- [Architecture Overview](./deployment/architecture.md)

---

## 📝 Note

This documentation structure was reorganized on 2025-01-20 to improve discoverability and reduce root-level clutter. All content has been preserved - just moved to more logical locations.

**Old File Locations → New Locations:**
- `INSTALLATION*.md` → `docs/installation/*.md`
- `*DEPLOYMENT*.md` → `docs/deployment/*.md`
- `*OAUTH*.md` → `docs/oauth/*.md`
- `*SUMMARY.md` → `docs/development/*.md`
