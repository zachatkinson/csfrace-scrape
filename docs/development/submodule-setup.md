# Submodule Automation Setup Guide

This guide explains how to set up GitHub tokens and secrets for the automated submodule update system.

## 🔐 Required GitHub Tokens

You need to create **2 Fine-Grained Personal Access Tokens** with specific permissions for better security:

### 1. Submodule Update Token (for umbrella repo)
**Purpose:** Allows the umbrella repo to update submodule references and create PRs

**Repository Access:** `zachatkinson/csfrace-scrape` only

**Permissions needed:**
- `Contents` (Read and Write) - Update submodule references
- `Metadata` (Read) - Access repository metadata
- `Pull requests` (Write) - Create and manage PRs
- `Actions` (Write) - Trigger workflows

### 2. Repository Dispatch Token (for backend/frontend repos)
**Purpose:** Allows backend/frontend repos to trigger workflows in the umbrella repo

**Repository Access:** `zachatkinson/csfrace-scrape` only

**Permissions needed:**
- `Metadata` (Read) - Access repository metadata  
- `Actions` (Write) - Trigger repository dispatch events

## 📝 Step-by-Step Setup

### Step 1: Create Fine-Grained Personal Access Tokens

1. Go to [GitHub Settings > Developer settings > Personal access tokens > Fine-grained tokens](https://github.com/settings/personal-access-tokens/new)

2. Create **Token 1 - Submodule Update Token**:
   - Name: `Submodule Update Token - csfrace-scrape`
   - Expiration: 90 days (recommended for security)
   - Resource owner: `zachatkinson`
   - Selected repositories: ✅ `zachatkinson/csfrace-scrape` ONLY
   - Repository permissions:
     - ✅ Contents: Read and write
     - ✅ Metadata: Read  
     - ✅ Pull requests: Write
     - ✅ Actions: Write
   - Click "Generate token"
   - **Copy and save this token securely**

3. Create **Token 2 - Repository Dispatch Token**:
   - Name: `Repository Dispatch Token - csfrace-scrape`
   - Expiration: 90 days (recommended for security)
   - Resource owner: `zachatkinson`
   - Selected repositories: ✅ `zachatkinson/csfrace-scrape` ONLY
   - Repository permissions:
     - ✅ Metadata: Read
     - ✅ Actions: Write
   - Click "Generate token"
   - **Copy and save this token securely**

### Alternative: Classic Tokens (If Fine-Grained Doesn't Work)

If you encounter compatibility issues with fine-grained tokens:

1. Go to [GitHub Settings > Developer settings > Personal access tokens > Tokens (classic)](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Use the same naming and permissions as described above
4. Scopes: ✅ `repo`, ✅ `workflow`

### Step 2: Add Secrets to Repositories

#### For Umbrella Repo (`zachatkinson/csfrace-scrape`)

1. Go to repository Settings > Secrets and variables > Actions
2. Click "New repository secret"
3. Add secret:
   - Name: `SUBMODULE_UPDATE_TOKEN`
   - Value: [Paste Token 1 from Step 1]
   - Click "Add secret"

#### For Backend Repo (`zachatkinson/csfrace-scrape-back`)

1. Go to repository Settings > Secrets and variables > Actions
2. Click "New repository secret" 
3. Add secret:
   - Name: `UMBRELLA_REPO_TOKEN`
   - Value: [Paste Token 2 from Step 1]
   - Click "Add secret"

#### For Frontend Repo (`zachatkinson/csfrace-scrape-front`)

1. Go to repository Settings > Secrets and variables > Actions
2. Click "New repository secret"
3. Add secret:
   - Name: `UMBRELLA_REPO_TOKEN` 
   - Value: [Paste Token 2 from Step 1 - same as backend]
   - Click "Add secret"

## 🔒 Security Best Practices

### Token Security
- **Use fine-grained tokens** - Repository-specific access is more secure
- **Store tokens securely** - Never commit them to code  
- **Use minimum required permissions** - Only the permissions listed above
- **Set short expiration dates** - 90 days maximum recommended
- **Rotate tokens regularly** - Update when they expire
- **Monitor token usage** - Review access logs periodically

### Repository Settings
- **Enable branch protection** on master/main branches
- **Require PR reviews** for production changes
- **Enable security alerts** for dependencies
- **Use environment-specific secrets** for different deployment stages

## 🚀 How the Automation Works

### Workflow Trigger Chain

1. **Developer pushes to backend/frontend**
   ```
   git push origin feature-branch
   ```

2. **Backend/Frontend CI runs**
   - Tests pass
   - Code is merged to master

3. **Repository dispatch trigger fires**
   - Sends webhook to umbrella repo
   - Includes commit info and metadata

4. **Umbrella repo receives dispatch**
   - Updates submodule references
   - Runs integration tests
   - Creates PR with changes

5. **Auto-merge (if tests pass)**
   - PR merges automatically
   - Umbrella repo is updated
   - Ready for deployment

### Manual Override

You can also manually trigger updates:

```bash
# Via GitHub UI
# Go to Actions > Update Submodules > Run workflow

# Via GitHub CLI
gh workflow run update-submodules.yml -f submodule=backend
gh workflow run update-submodules.yml -f submodule=frontend  
gh workflow run update-submodules.yml -f submodule=both
```

## 🧪 Testing the Setup

### Test Backend Trigger
1. Make a small change in backend repo
2. Push to master branch
3. Check umbrella repo Actions tab
4. Verify workflow triggered and PR created

### Test Frontend Trigger  
1. Make a small change in frontend repo
2. Push to master branch
3. Check umbrella repo Actions tab
4. Verify workflow triggered and PR created

### Test Manual Trigger
1. Go to umbrella repo > Actions > Update Submodules
2. Click "Run workflow" 
3. Select "both" and run
4. Verify workflow runs and creates PR if changes exist

## 🔧 Troubleshooting

### Common Issues

**"Resource not accessible by integration" error**
- Check token permissions include `repo` and `workflow`
- Verify token hasn't expired
- Ensure secret name matches workflow file

**"Repository dispatch not triggering"**
- Verify `UMBRELLA_REPO_TOKEN` is set in backend/frontend repos
- Check repository name in workflow file is correct
- Ensure token has access to umbrella repo

**"Submodule update fails"**
- Check `SUBMODULE_UPDATE_TOKEN` permissions
- Verify submodules are properly initialized
- Check for branch protection rules blocking auto-commits

**"Integration tests fail"**
- Verify docker-compose files are valid
- Check .env.example has all required variables
- Ensure test database/services can start

### Debug Steps

1. **Check workflow logs** in Actions tab
2. **Verify token expiration** dates
3. **Test tokens manually** with GitHub CLI
4. **Check repository settings** and permissions
5. **Validate workflow file syntax** with GitHub Actions validator

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review GitHub Actions logs for specific errors
3. Verify all tokens and secrets are correctly configured
4. Test individual components (tokens, workflows, permissions)

---

**Security Note:** Keep your Personal Access Tokens secure and never share them. If a token is compromised, regenerate it immediately and update all repository secrets.