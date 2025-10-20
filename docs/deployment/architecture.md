# Deployment Architecture - CSFrace Scrape

## Overview
This document defines the separation of concerns between individual repositories (frontend/backend) and the orchestrator repository.

## Architecture Principles

### 1. Individual Repositories (Frontend/Backend)
**Responsibility:** Build, Test, Version, Publish Artifacts

**Workflows:**
- ✅ **CI (`ci.yml`)**: Build, test, lint, security scans, quality gates
- ✅ **Release (`release.yml`)**: Semantic versioning, Docker image publishing, changelog generation
- ❌ **NO Deployment**: Never deploy to any environment
- ❌ **NO Monitoring Gates**: Don't implement health checks or rollbacks

**What They Produce:**
- Versioned Docker images pushed to `ghcr.io/zachatkinson/csfrace-scrape-back:vX.Y.Z`
- Versioned Docker images pushed to `ghcr.io/zachatkinson/csfrace-scrape-front:vX.Y.Z`
- Git tags (e.g., `v5.15.0`, `v1.1.1`)
- GitHub releases with changelogs
- Notifications to orchestrator when new versions are published

### 2. Orchestrator Repository (csfrace-scrape)
**Responsibility:** Integration Testing, Deployment Coordination, Monitoring

**Workflows:**
- ✅ **Integration Tests (`integration.yml`)**: Cross-service API contract validation, E2E tests
- ✅ **Deployment (`deployment.yml`)**: Pull versioned images, deploy to environments
- ✅ **Monitoring Gates (`monitoring-gates.yml`)**: Health checks across all services, auto-rollback
- ✅ **Submodule Sync (`update-submodules.yml`)**: Keep git submodules up to date

**What It Does:**
- Pulls pre-built Docker images from individual repos
- Coordinates multi-service deployments
- Runs integration tests before deployment
- Monitors all services together
- Performs atomic rollbacks if any service fails

## Current vs Target State

### Current Problems

**Backend** (csfrace-scrape-back):
- ❌ Has `deploy.yml` - shouldn't deploy itself
- ❌ Has `monitoring-gates.yml` - orchestrator should monitor

**Frontend** (csfrace-scrape-front):
- ✅ No deployment workflows (correct!)
- ✅ Only CI + Release (correct!)

**Orchestrator** (csfrace-scrape):
- ⚠️ Has deployment workflow but may be building images (should pull pre-built)
- ⚠️ May need better version coordination

### Target Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Developer Workflow                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
         ┌──────────────────┐  ┌──────────────────┐
         │  Backend Repo    │  │  Frontend Repo   │
         │  (Individual)    │  │  (Individual)    │
         └──────────────────┘  └──────────────────┘
                    │                   │
         ┌──────────┼──────────┬────────┼──────────┐
         │          │          │        │          │
         ▼          ▼          ▼        ▼          ▼
      ┌────┐    ┌────┐    ┌────┐   ┌────┐    ┌────┐
      │ CI │    │Test│    │Lint│   │ CI │    │Test│
      └────┘    └────┘    └────┘   └────┘    └────┘
         │          │          │        │          │
         └──────────┴──────────┘        └──────────┘
                    │                        │
                    ▼                        ▼
         ┌──────────────────┐    ┌──────────────────┐
         │ Semantic Release │    │ Semantic Release │
         │   + Docker Push  │    │   + Docker Push  │
         └──────────────────┘    └──────────────────┘
                    │                        │
                    │ v5.15.0                │ v1.1.1
                    │ Published              │ Published
                    │                        │
         ┌──────────┴────────────────────────┴──────────┐
         │          Notify Orchestrator                  │
         │      (repository_dispatch event)              │
         └───────────────────┬───────────────────────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │  Orchestrator Repo   │
                  │   (Coordination)     │
                  └──────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
         ┌────────┐    ┌────────┐    ┌────────┐
         │Integration│ │Deploy  │    │Monitor │
         │  Tests   │ │Coordin │    │& Health│
         └────────┘    └────────┘    └────────┘
              │              │              │
              └──────────────┼──────────────┘
                             │
                   Pull Images & Deploy
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
         ┌────────┐    ┌────────┐    ┌────────┐
         │Staging │    │Production│   │Rollback│
         │  Env   │    │   Env    │   │ if Fail│
         └────────┘    └────────┘    └────────┘
```

## Workflow Details

### Individual Repository: `release.yml`

```yaml
name: Semantic Release & Publish

on:
  workflow_run:
    workflows: ["CI"]
    types: [completed]
    branches: [master]

jobs:
  release:
    steps:
      - Semantic versioning (tag, changelog)
      - Build Docker image
      - Push to ghcr.io with version tags
      - Create GitHub release
      - Notify orchestrator via repository_dispatch
```

**Key Points:**
- Only runs on `master` after CI passes
- Publishes immutable versioned artifacts
- Notifies orchestrator of new version
- Does NOT deploy anywhere

### Orchestrator: `deployment.yml`

```yaml
name: Coordinated Deployment

on:
  repository_dispatch:
    types: [backend-updated, frontend-updated]
  workflow_dispatch:
    inputs:
      backend_version: {required: true}
      frontend_version: {required: true}
      environment: {choices: [staging, production]}

jobs:
  deploy-staging:
    steps:
      - Pull backend:${{ backend_version }} from registry
      - Pull frontend:${{ frontend_version }} from registry
      - Update docker-compose.yml with versions
      - Deploy to staging
      - Run integration tests
      - Health check all services
      - If success, ready for production

  deploy-production:
    needs: [deploy-staging]
    environment: production  # Manual approval required
    steps:
      - Pull same backend/frontend versions
      - Deploy to production
      - Health check all services
      - Monitor for 5 minutes
      - Auto-rollback if errors detected
```

**Key Points:**
- Pulls pre-built images (never builds)
- Coordinates multi-service deployment
- Runs integration tests BEFORE production
- Requires manual approval for production
- Atomic rollback if any service fails

## Migration Plan

### Phase 1: Backend Cleanup ✅
- [x] Verify backend `release.yml` publishes Docker images
- [x] Verify backend `release.yml` notifies orchestrator
- [ ] **Move** `backend/deploy.yml` → `orchestrator/deploy.yml`
- [ ] **Move** `backend/monitoring-gates.yml` → `orchestrator/monitoring.yml`
- [ ] **Deprecate** backend deployment workflows

### Phase 2: Frontend Alignment ✅
- [x] Verify frontend `release.yml` publishes Docker images
- [ ] Add orchestrator notification to frontend `release.yml`
- [x] Confirm NO deployment workflows in frontend

### Phase 3: Orchestrator Enhancement 🔄
- [ ] Update `deployment.yml` to pull images (not build)
- [ ] Add version coordination logic
- [ ] Implement health monitoring from backend
- [ ] Add atomic rollback capability
- [ ] Create manual approval gate for production

### Phase 4: Testing & Validation
- [ ] Test orchestrator deployment to staging
- [ ] Test integration tests run before deployment
- [ ] Test manual production approval
- [ ] Test rollback scenarios
- [ ] Document deployment procedures

### Phase 5: Cutover
- [ ] Archive backend `deploy.yml` (mark deprecated)
- [ ] Archive backend `monitoring-gates.yml`
- [ ] Update READMEs with new deployment flow
- [ ] Train team on new process

## Deployment Commands

### Development
```bash
# Individual repos publish automatically on merge to master
# No manual deployment commands needed
```

### Staging (Automatic)
```bash
# Triggered automatically when:
# 1. Backend releases new version → orchestrator deploys backend:vX.Y.Z
# 2. Frontend releases new version → orchestrator deploys frontend:vX.Y.Z
# 3. Both services pass integration tests → auto-deploy to staging
```

### Production (Manual)
```bash
# Via GitHub UI:
# 1. Go to csfrace-scrape repository
# 2. Actions → Coordinated Deployment → Run workflow
# 3. Select versions:
#    - backend_version: v5.15.0
#    - frontend_version: v1.1.1
#    - environment: production
# 4. Approve deployment (requires 2 reviewers)
# 5. Monitor health checks
```

### Rollback
```bash
# Automatic rollback triggers:
# - Health endpoint returns non-200 status
# - Error rate exceeds 1%
# - Response time exceeds 2 seconds
# - Any service fails to start

# Manual rollback:
gh workflow run deployment.yml \
  -f backend_version=v5.14.0 \
  -f frontend_version=v1.0.0 \
  -f environment=production
```

## Version Compatibility Matrix

The orchestrator maintains a compatibility matrix to ensure safe deployments:

```yaml
# .github/compatibility.yml
versions:
  - backend: v5.15.0
    frontend: v1.1.1
    tested: true
    production: true

  - backend: v5.14.0
    frontend: v1.0.0
    tested: true
    production: true
```

## Benefits of This Architecture

1. **Independent Development Velocity**
   - Backend and frontend can release independently
   - No waiting for the other service to be ready

2. **Safe Coordinated Deployments**
   - Integration tests ensure services work together
   - Manual approval prevents accidental production deployments
   - Atomic rollback prevents partial failures

3. **Immutable Artifacts**
   - Docker images are versioned and immutable
   - Can always rollback to any previous version
   - Clear audit trail of what's deployed where

4. **Single Source of Truth**
   - Orchestrator docker-compose.yml shows production state
   - Easy to see which versions are deployed
   - No confusion about "what's in production"

5. **Better Monitoring**
   - Orchestrator monitors all services together
   - Detects integration failures, not just individual failures
   - Auto-rollback based on cross-service health

## Security Considerations

1. **Image Provenance**: All images must have signed attestations
2. **Access Control**: Production deployments require manual approval
3. **Secrets Management**: Secrets only in orchestrator environments
4. **Network Isolation**: Services communicate via internal network
5. **Audit Logging**: All deployments logged and traceable

## Questions & Decisions

### Q: What if backend v5.15.0 is incompatible with frontend v1.0.0?
**A:** Integration tests will fail, preventing deployment. The compatibility matrix tracks tested combinations.

### Q: Can we deploy backend without frontend?
**A:** Yes, via manual workflow dispatch with explicit versions. But integration tests must pass.

### Q: What happens if staging deployment fails?
**A:** Production deployment is blocked. Fix the issue and re-run.

### Q: How do we handle database migrations?
**A:** Backend includes migrations in Docker image. Orchestrator runs migrations before starting services.

## Next Steps

1. **Review this architecture** with team
2. **Implement Phase 1** (Backend cleanup)
3. **Implement Phase 2** (Frontend alignment)
4. **Test in staging** before production cutover
5. **Update documentation** and training materials
