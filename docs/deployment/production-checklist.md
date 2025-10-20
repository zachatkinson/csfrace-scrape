# Production Readiness Checklist
## CSFrace Scrape - Client Deployment

> Use this checklist before deploying to clients to ensure production quality

---

## Pre-Deployment Checklist

### 1. Security ✅❌

- [ ] **Secrets Management**
  - [ ] All default passwords changed in `.env`
  - [ ] `SECRET_KEY` generated with `openssl rand -hex 32`
  - [ ] `POSTGRES_PASSWORD` is strong (24+ characters)
  - [ ] `GRAFANA_ADMIN_PASSWORD` changed from default
  - [ ] OAuth secrets properly configured (if used)
  - [ ] No secrets committed to git (check `.gitignore`)

- [ ] **SSL/TLS**
  - [ ] SSL certificates generated (`nginx/ssl/certificate.crt`, `nginx/ssl/private.key`)
  - [ ] Certificate valid for 365+ days
  - [ ] HTTPS enforced (port 443 configured)
  - [ ] HTTP redirects to HTTPS (in nginx.conf)

- [ ] **Network Security**
  - [ ] Only necessary ports exposed (80, 443, optionally 3001 for monitoring)
  - [ ] PostgreSQL port (5432) NOT exposed externally
  - [ ] Redis port (6379) NOT exposed externally
  - [ ] Docker network configured (`csfrace-network` isolated)
  - [ ] Firewall rules configured if remote access needed

- [ ] **Authentication**
  - [ ] OAuth providers tested (if enabled)
  - [ ] WebAuthn/passkey registration tested
  - [ ] Account lockout working (after failed attempts)
  - [ ] Token expiration configured (`ACCESS_TOKEN_EXPIRE_MINUTES`)
  - [ ] CORS origins properly set (`CORS_ORIGINS`)

- [ ] **Input Validation**
  - [ ] Backend API validates all inputs
  - [ ] Frontend sanitizes user inputs
  - [ ] File upload validation working
  - [ ] XSS protection enabled

### 2. Data Persistence ✅❌

- [ ] **Docker Volumes**
  - [ ] `postgres-data` volume exists and mounted
  - [ ] `redis-data` volume exists and mounted
  - [ ] `prometheus-data` volume exists and mounted
  - [ ] `grafana-data` volume exists and mounted
  - [ ] Volumes persist after `docker compose down`

- [ ] **Database**
  - [ ] PostgreSQL migrations run successfully
  - [ ] Database initialization script exists (`scripts/init-db.sql`)
  - [ ] Database performance tuning applied (see `docker-compose.yml` postgres command)
  - [ ] Database backup script tested (`backup.sh`)
  - [ ] Restore procedure documented

- [ ] **Backup Strategy**
  - [ ] Automated backup script exists (`scripts/backup.sh`)
  - [ ] Backup schedule configured (cron job or Task Scheduler)
  - [ ] Backup retention policy defined (e.g., keep last 30 days)
  - [ ] Backup encryption enabled (optional but recommended)
  - [ ] Restore procedure tested successfully

### 3. Performance ✅❌

- [ ] **Resource Limits**
  - [ ] Memory limits configured for all services
  - [ ] CPU limits configured for all services
  - [ ] Disk space sufficient (20GB+ free)
  - [ ] Resource reservation set (minimum guaranteed resources)

- [ ] **Optimization**
  - [ ] Backend concurrent requests tuned (`SCRAPER_CONCURRENT_REQUESTS`)
  - [ ] Redis maxmemory configured (`REDIS_MAXMEMORY`)
  - [ ] PostgreSQL shared_buffers tuned (256MB default)
  - [ ] Frontend production build verified (`NODE_ENV=production`)

- [ ] **Monitoring**
  - [ ] Prometheus metrics collection working
  - [ ] Grafana dashboards configured
  - [ ] Health check endpoints responding (`/health/`)
  - [ ] Performance metrics visible in Grafana

### 4. Reliability ✅❌

- [ ] **Health Checks**
  - [ ] Backend health check passing
  - [ ] Frontend health check passing
  - [ ] PostgreSQL health check passing
  - [ ] Redis health check passing
  - [ ] Nginx health check configured
  - [ ] Grafana health check passing

- [ ] **Restart Policies**
  - [ ] All services configured with `restart: unless-stopped`
  - [ ] Services restart automatically after crash
  - [ ] Services restart after Docker Desktop restart
  - [ ] Services restart after system reboot

- [ ] **Error Handling**
  - [ ] Backend returns proper error codes (4xx, 5xx)
  - [ ] Frontend displays user-friendly error messages
  - [ ] Database connection errors handled gracefully
  - [ ] Redis connection errors handled gracefully

- [ ] **Logging**
  - [ ] All services logging to stdout/stderr
  - [ ] Log levels configured (`LOG_LEVEL=INFO` for production)
  - [ ] Logs accessible via `docker compose logs`
  - [ ] Log rotation configured (Docker handles this)

### 5. Documentation ✅❌

- [ ] **User Documentation**
  - [ ] CLIENT_DEPLOYMENT_GUIDE.md (Windows) complete and accurate
  - [ ] CLIENT_DEPLOYMENT_GUIDE_UNIX.md (macOS/Linux) complete and accurate
  - [ ] Installation steps tested on clean system (Windows, macOS, Linux)
  - [ ] Troubleshooting section comprehensive
  - [ ] Backup/restore procedures documented

- [ ] **Configuration Documentation**
  - [ ] `.env.example` file up to date
  - [ ] All environment variables documented
  - [ ] OAuth setup guides complete (if applicable)
  - [ ] SSL certificate generation documented

- [ ] **Operational Documentation**
  - [ ] Daily usage procedures documented
  - [ ] Update procedures documented
  - [ ] Rollback procedures documented
  - [ ] Support contact information provided

### 6. Testing ✅❌

- [ ] **Functional Testing**
  - [ ] User registration working
  - [ ] User login working
  - [ ] OAuth login working (if enabled)
  - [ ] WebAuthn/passkey working (if enabled)
  - [ ] Main application features working
  - [ ] File uploads working
  - [ ] Content scraping working

- [ ] **Integration Testing**
  - [ ] Backend-frontend communication working
  - [ ] Backend-database communication working
  - [ ] Backend-Redis communication working
  - [ ] Nginx reverse proxy working
  - [ ] HTTPS certificate accepted

- [ ] **Performance Testing**
  - [ ] Application loads within 3 seconds
  - [ ] API responses within 2 seconds
  - [ ] Concurrent user testing passed
  - [ ] Large file upload tested
  - [ ] Memory usage stable over time

- [ ] **Edge Case Testing**
  - [ ] Network disconnection handled
  - [ ] Database connection loss recovered
  - [ ] Redis connection loss recovered
  - [ ] Disk space exhaustion handled
  - [ ] Invalid input rejected

### 7. Compliance ✅❌

- [ ] **Privacy**
  - [ ] Privacy policy provided (if collecting personal data)
  - [ ] User data deletion working (GDPR compliance)
  - [ ] OAuth consent screens configured
  - [ ] Data retention policy defined

- [ ] **Security**
  - [ ] Security.txt file present (optional)
  - [ ] Vulnerability scanning passed
  - [ ] Dependency updates applied
  - [ ] Security audit completed

- [ ] **Legal**
  - [ ] License file present
  - [ ] Terms of Service provided (if applicable)
  - [ ] Copyright notices present
  - [ ] Third-party licenses documented

---

## Post-Deployment Checklist

### Immediate (Day 1)

- [ ] All services started successfully
- [ ] Health checks passing for all services
- [ ] Client can access application via HTTPS
- [ ] SSL certificate accepted (or warning acknowledged)
- [ ] First user account registered successfully
- [ ] Basic functionality tested

### Short-term (Week 1)

- [ ] Daily backups running successfully
- [ ] No critical errors in logs
- [ ] Performance metrics stable
- [ ] Client trained on basic operations
- [ ] Support channel established

### Long-term (Month 1)

- [ ] Weekly backups verified
- [ ] Performance tuning completed (if needed)
- [ ] User feedback collected
- [ ] Issues resolved
- [ ] Update schedule established

---

## Critical Issues - Do Not Deploy If:

🚨 **BLOCKER:** Any of these issues will cause deployment failure

- [ ] Docker Desktop not installed or not running
- [ ] Insufficient system resources (< 4GB RAM, < 10GB disk)
- [ ] Default passwords not changed
- [ ] SSL certificates not generated
- [ ] Database migrations failing
- [ ] Health checks failing
- [ ] Critical security vulnerabilities unpatched

---

## Launch Day Procedure

### 1. Pre-Launch (1 hour before)

```bash
# Final system check
docker --version
docker compose version
docker system df  # Check disk space

# Final configuration review
cat .env | grep -E "PASSWORD|SECRET_KEY"  # Verify changed

# Final build and test
docker compose down
docker compose build --no-cache
docker compose up -d
docker compose ps  # All healthy?
docker compose logs  # Any errors?
```

### 2. Launch

```bash
# Start services
docker compose up -d

# Monitor startup
docker compose logs -f

# Wait for healthy status (60 seconds)
watch -n 5 'docker compose ps'

# Test endpoints
curl -k https://localhost/health/
curl -k https://localhost/api/docs
```

### 3. Post-Launch (first 30 minutes)

```bash
# Monitor logs continuously
docker compose logs -f

# Watch resource usage
docker stats

# Check for errors
docker compose logs | grep -i error

# Verify backups
ls -lah ~/csfrace-backups/
```

### 4. Client Handoff

- [ ] Walk through application with client
- [ ] Demonstrate basic features
- [ ] Show backup location and restore procedure
- [ ] Provide support contact information
- [ ] Schedule follow-up check-in (1 week)

---

## Rollback Plan

If deployment fails, follow this rollback procedure:

```bash
# 1. Stop services
docker compose down

# 2. Revert to previous version
git log --oneline  # Find previous commit
git checkout <previous-commit-hash>
git submodule update --init --recursive

# 3. Restore backup
tar -xzf ~/csfrace-backups/backup-YYYY-MM-DD.tar.gz
# (follow restore procedure in CLIENT_DEPLOYMENT_GUIDE.md)

# 4. Start services
docker compose up -d

# 5. Verify
docker compose ps
curl -k https://localhost/health/
```

---

## Support Escalation

### Level 1: Client Self-Service

- CLIENT_DEPLOYMENT_GUIDE.md
- Docker compose logs
- Basic troubleshooting steps

### Level 2: Email Support

- Collect logs: `docker compose logs > logs.txt`
- Collect system info: `docker system df > system-info.txt`
- Email: support@yourcompany.com

### Level 3: Emergency Support

- Critical system down
- Data loss
- Security incident
- Contact: emergency-support@yourcompany.com

---

## Continuous Improvement

### Weekly Tasks

- [ ] Review logs for errors
- [ ] Check disk space usage
- [ ] Verify backups completed
- [ ] Monitor performance metrics

### Monthly Tasks

- [ ] Apply security updates
- [ ] Review and optimize performance
- [ ] Test backup restore
- [ ] Update documentation

### Quarterly Tasks

- [ ] Major version updates
- [ ] Security audit
- [ ] Performance review
- [ ] Client satisfaction survey

---

**Deployment Approved By:**

- [ ] Technical Lead: _________________ Date: _______
- [ ] Security Lead: _________________ Date: _______
- [ ] Product Owner: _________________ Date: _______

**Deployment Date:** _______________________

**Client Name:** _______________________

**Deployed By:** _______________________

**Notes:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
