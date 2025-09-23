# Submodule Update Best Practices

## The Problem

When using Git submodules in an umbrella repository pattern, merge conflicts can occur when the submodule has diverged from its upstream repository. This commonly happens when:

1. The submodule has local commits not yet pushed to origin
2. The umbrella repository's submodule reference points to an older commit
3. Database migrations or lock files create merge conflicts
4. Multiple developers are working on different features simultaneously

## The Solution: Force-Update Strategy

### Core Principle

**Submodules in an umbrella repository should always track their upstream repositories exactly.** The umbrella repository should never contain local modifications to submodules - all changes should flow through the individual repositories.

### Implementation Strategies

#### 1. **Force-Update (RECOMMENDED)**

Always reset the submodule to match the upstream repository exactly:

```bash
cd backend
git fetch origin
git reset --hard origin/master
cd ..
git add backend
git commit -m "chore: update backend submodule to latest"
```

**Pros:**
- ✅ Never fails due to conflicts
- ✅ Ensures submodules match their repositories exactly
- ✅ Simple and predictable
- ✅ Works with automated workflows

**Cons:**
- ⚠️ Discards any local changes (but this should never happen in proper workflow)

#### 2. **Fast-Forward with Fallback**

Try fast-forward first, fallback to force-update if it fails:

```bash
cd backend
git fetch origin
if git merge --ff-only origin/master; then
  echo "Fast-forward successful"
else
  echo "Fast-forward failed, force updating..."
  git reset --hard origin/master
fi
```

**Pros:**
- ✅ Preserves clean history when possible
- ✅ Still guarantees success via fallback
- ✅ More informative about repository state

#### 3. **Merge Strategy (NOT RECOMMENDED)**

Attempt to merge changes:

```bash
git submodule update --remote --merge backend
```

**Cons:**
- ❌ Can fail with merge conflicts
- ❌ Creates merge commits in submodules
- ❌ Complicates history
- ❌ Not suitable for automation

## Workflow Configuration

### Updated Workflow Implementation

We've updated the umbrella repository with two workflows:

1. **`update-submodules.yml`**: Basic workflow with force-update fallback
2. **`advanced-submodule-sync.yml`**: Advanced workflow with multiple strategies

### Key Features

#### Automatic Conflict Resolution

```yaml
# Try fast-forward first
if git merge --ff-only origin/$DEFAULT_BRANCH 2>/dev/null; then
  echo "✅ Fast-forward merge successful"
else
  # Force update if fast-forward fails
  git reset --hard origin/$DEFAULT_BRANCH
  echo "✅ Force updated to latest commit"
fi
```

#### Version Tracking

The workflow now tracks and reports version tags:

```bash
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$LATEST_TAG" ]; then
  echo "BACKEND_VERSION=$LATEST_TAG" >> $GITHUB_ENV
fi
```

#### Conflict Reporting

The workflow reports when conflicts were resolved:

```yaml
${{ env.BACKEND_HAD_CONFLICTS == 'true' && '⚠️ Resolved conflicts via force update' || '' }}
```

## Best Practices

### 1. **Never Commit Directly to Submodules in Umbrella Repo**

❌ **Wrong:**
```bash
cd csfrace-scrape/backend
# Making changes directly
git add .
git commit -m "fix: something"
```

✅ **Correct:**
```bash
cd csfrace-scrape-back  # Work in the actual repository
git add .
git commit -m "fix: something"
git push origin master
# Let automation update the umbrella repository
```

### 2. **Use Repository Dispatch for Automation**

Configure backend/frontend repositories to notify the umbrella repository:

```yaml
# In backend/.github/workflows/release.yml
- name: Update Umbrella Repository
  uses: peter-evans/repository-dispatch@v3
  with:
    token: ${{ secrets.UMBRELLA_REPO_TOKEN }}
    repository: zachatkinson/csfrace-scrape
    event-type: backend-released
```

### 3. **Always Create PRs for Submodule Updates**

This ensures:
- Code review opportunity
- CI/CD validation
- Audit trail
- Rollback capability

### 4. **Use Semantic Versioning**

Tag releases in backend/frontend repositories:
```bash
git tag -a v1.2.3 -m "Release version 1.2.3"
git push origin v1.2.3
```

The umbrella repository can then track specific versions.

### 5. **Monitor Update Failures**

Set up notifications for failed updates:

```yaml
- name: Notify on Failure
  if: failure()
  run: |
    echo "⚠️ Submodule update failed!"
    # Send notification to Slack/Discord/Email
```

## Troubleshooting

### Manual Conflict Resolution

If automated updates fail repeatedly:

```bash
# 1. Clone the umbrella repository
git clone --recursive https://github.com/zachatkinson/csfrace-scrape.git
cd csfrace-scrape

# 2. Force update all submodules
git submodule foreach 'git fetch origin && git reset --hard origin/master'

# 3. Commit the updates
git add .
git commit -m "chore: force sync all submodules to upstream"
git push origin master
```

### Fixing Detached HEAD

If a submodule is in detached HEAD state:

```bash
cd backend
git checkout master
git pull origin master
cd ..
git add backend
git commit -m "chore: fix backend submodule detached HEAD"
```

### Resetting to Clean State

Complete reset of all submodules:

```bash
# Remove all submodules
git submodule deinit -f .
rm -rf .git/modules/*
git submodule update --init --recursive
```

## Configuration Checklist

- [ ] Backend repository has `UMBRELLA_REPO_TOKEN` secret configured
- [ ] Frontend repository has `UMBRELLA_REPO_TOKEN` secret configured
- [ ] Umbrella repository has `SUBMODULE_UPDATE_TOKEN` secret configured
- [ ] Repository dispatch events configured in backend/frontend release workflows
- [ ] Auto-merge enabled for submodule update PRs
- [ ] Branch protection rules allow automated updates
- [ ] Monitoring/notifications configured for failures

## Summary

The key to avoiding submodule conflicts is to **treat submodules as read-only references** in the umbrella repository. Always make changes in the actual repositories and let automation handle the synchronization. The force-update strategy ensures that the umbrella repository always reflects the true state of the backend and frontend repositories without manual intervention.