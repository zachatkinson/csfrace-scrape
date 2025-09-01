## 🔄 Pull Request Summary

### Component
<!-- Check the primary component affected -->
- [ ] 🐳 Docker Compose orchestration
- [ ] 🔧 Environment/configuration management  
- [ ] 📊 Monitoring setup (Prometheus/Grafana)
- [ ] 🔗 Service networking/integration
- [ ] 📚 Documentation updates
- [ ] 🚀 Deployment/CI-CD workflows
- [ ] 📦 Submodule updates
- [ ] 🛠️ Development tooling

### Changes Made
<!-- Provide a clear description of what changes were made -->

**Summary:**


**Key Changes:**
- 
- 
- 

### 🧪 Testing

<!-- Check all that apply -->
- [ ] ✅ All services start successfully with `docker-compose up -d`
- [ ] 🔍 Service health checks pass
- [ ] 🌐 Frontend can communicate with backend
- [ ] 💾 Database connections work properly  
- [ ] 🗄️ Redis cache is accessible
- [ ] 📊 Monitoring dashboards load correctly
- [ ] 🔄 Integration tests pass
- [ ] 📝 Documentation is accurate and complete

### 🔗 Related Issues
<!-- Link to related issues -->
Closes #
Related to #

### 🚀 Deployment Notes
<!-- Any special deployment considerations -->

**Breaking Changes:**
- [ ] No breaking changes
- [ ] ⚠️ Requires environment variable updates (document below)
- [ ] ⚠️ Requires database migration (document below)
- [ ] ⚠️ Requires manual deployment steps (document below)

**Environment Updates Needed:**
```bash
# Add any new environment variables required
```

**Deployment Steps:**
1. 
2. 
3. 

### 📋 Checklist

<!-- Ensure all items are checked before requesting review -->
#### Code Quality
- [ ] Code follows wrapper CLAUDE.md standards
- [ ] All configuration is externalized to environment variables
- [ ] No hardcoded values in Docker Compose files
- [ ] Proper service dependencies and health checks implemented
- [ ] Resource limits and restart policies configured

#### Documentation  
- [ ] README.md updated if architecture changed
- [ ] .env.example updated with new variables
- [ ] CLAUDE.md updated if standards changed
- [ ] Inline comments added for complex configurations

#### Testing
- [ ] Services start and stop cleanly
- [ ] All health checks pass
- [ ] Integration between services works
- [ ] Monitoring endpoints are accessible
- [ ] No regression in existing functionality

#### Security
- [ ] No secrets committed to repository
- [ ] Environment variables properly templated
- [ ] Service communication uses internal networking
- [ ] Exposed ports are intentional and documented

#### Git
- [ ] Submodule references are updated correctly
- [ ] Commit messages follow conventional format
- [ ] No large files committed
- [ ] Branch is up to date with main

### 🎯 Reviewer Focus Areas
<!-- Help reviewers focus on the most important aspects -->

**Please pay special attention to:**
- 
- 
- 

**Testing Instructions:**
```bash
# Specific commands for reviewers to test this PR
git checkout feature-branch
docker-compose down -v
docker-compose up -d
# Additional testing steps...
```

### 📸 Screenshots/Demos
<!-- If applicable, add screenshots or demo links -->

---

<!-- For maintainers -->
/cc @zachatkinson