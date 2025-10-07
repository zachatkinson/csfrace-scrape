# OAuth SSO Setup Guide - Complete Overview

## Overview

All **5 major OAuth providers** are **fully implemented** in your backend and frontend:

- ✅ Google
- ✅ GitHub
- ✅ Microsoft
- ✅ Facebook/Meta
- ✅ Apple

**What's missing:** Just the API credentials! This guide helps you choose which providers to enable and in what order.

## Quick Status Check

Test which providers are available:
```bash
curl http://localhost:8000/auth/oauth/providers
```

Should return:
```json
["google", "github", "microsoft", "facebook", "apple"]
```

## Recommended Setup Order

### 1. **START HERE:** Google OAuth (⭐ Easiest)
- **Difficulty:** ⭐ Very Easy
- **Setup Time:** ~5-10 minutes
- **Cost:** Free
- **Why first:** Most users have Google accounts, simplest setup

**Setup Steps:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create project → Enable "Google+ API"
3. Create OAuth 2.0 Client ID
4. Add redirect URIs
5. Get Client ID + Client Secret
6. Done!

**Environment Variables:**
```bash
OAUTH_GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
OAUTH_GOOGLE_CLIENT_SECRET=your-client-secret
```

**Documentation:** Coming soon (or use Google's official docs)

---

### 2. GitHub OAuth (⭐ Easy)
- **Difficulty:** ⭐ Very Easy
- **Setup Time:** ~5-10 minutes
- **Cost:** Free
- **Why second:** Developer-friendly users, extremely simple setup

**Setup Steps:**
1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. "New OAuth App"
3. Add app details + redirect URI
4. Get Client ID + Client Secret
5. Done!

**Environment Variables:**
```bash
OAUTH_GITHUB_CLIENT_ID=your-github-client-id
OAUTH_GITHUB_CLIENT_SECRET=your-github-client-secret
```

**Documentation:** Coming soon (or use GitHub's official docs)

---

### 3. Facebook/Meta OAuth (⭐⭐ Moderate)
- **Difficulty:** ⭐⭐ Easy-Moderate
- **Setup Time:** ~10-15 minutes
- **Cost:** Free
- **Why third:** Large user base, reasonable setup complexity

**Setup Steps:** See [`FACEBOOK_SSO_SETUP.md`](./FACEBOOK_SSO_SETUP.md)

**Environment Variables:**
```bash
OAUTH_FACEBOOK_CLIENT_ID=123456789012345
OAUTH_FACEBOOK_CLIENT_SECRET=abc123def456...
```

---

### 4. Microsoft OAuth (⭐⭐⭐ Moderate)
- **Difficulty:** ⭐⭐⭐ Moderate
- **Setup Time:** ~15-20 minutes
- **Cost:** Free
- **Why fourth:** Enterprise users, Azure AD integration possible

**Setup Steps:**
1. Go to [Azure Portal](https://portal.azure.com/)
2. "Azure Active Directory" → "App registrations"
3. "New registration"
4. Configure redirect URIs
5. Create client secret
6. Get Application (client) ID + Secret
7. Done!

**Environment Variables:**
```bash
OAUTH_MICROSOFT_CLIENT_ID=your-application-id
OAUTH_MICROSOFT_CLIENT_SECRET=your-client-secret
```

**Documentation:** Coming soon (or use Microsoft's official docs)

---

### 5. **LAST:** Apple Sign In (⭐⭐⭐⭐⭐ Complex)
- **Difficulty:** ⭐⭐⭐⭐⭐ Advanced
- **Setup Time:** ~30-45 minutes
- **Cost:** $99/year (Apple Developer Program)
- **Why last:** Most complex, requires payment, JWT generation

**Setup Steps:** See [`APPLE_SSO_SETUP.md`](./APPLE_SSO_SETUP.md)

**Requirements:**
- Apple Developer account ($99/year)
- Domain ownership verification
- Private key generation
- JWT creation (6-month expiration)

**Environment Variables:**
```bash
OAUTH_APPLE_CLIENT_ID=com.csfrace.web.signin
OAUTH_APPLE_CLIENT_SECRET=generated-jwt-token
```

---

## Provider Comparison Matrix

| Provider | Difficulty | Setup Time | Cost | User Base | Email Privacy | Avatar | Development Testing |
|----------|-----------|------------|------|-----------|---------------|--------|-------------------|
| **Google** | ⭐ | 5-10 min | Free | ⭐⭐⭐⭐⭐ Massive | Standard | ✅ | Easy |
| **GitHub** | ⭐ | 5-10 min | Free | ⭐⭐⭐ Developers | Standard | ✅ | Easy |
| **Facebook** | ⭐⭐ | 10-15 min | Free | ⭐⭐⭐⭐⭐ Massive | Optional | ✅ | Easy (test users) |
| **Microsoft** | ⭐⭐⭐ | 15-20 min | Free | ⭐⭐⭐⭐ Enterprise | Standard | ✅ | Moderate |
| **Apple** | ⭐⭐⭐⭐⭐ | 30-45 min | $99/year | ⭐⭐⭐⭐ iOS users | Private relay | ❌ | Difficult |

## Environment Configuration

### Development (.env file)

```bash
# OAuth2 Redirect URI Base (development)
OAUTH_REDIRECT_URI_BASE=http://localhost:8000

# Google OAuth (recommended: set up first)
OAUTH_GOOGLE_CLIENT_ID=
OAUTH_GOOGLE_CLIENT_SECRET=

# GitHub OAuth (recommended: set up second)
OAUTH_GITHUB_CLIENT_ID=
OAUTH_GITHUB_CLIENT_SECRET=

# Facebook OAuth (recommended: set up third)
OAUTH_FACEBOOK_CLIENT_ID=
OAUTH_FACEBOOK_CLIENT_SECRET=

# Microsoft OAuth (optional: set up fourth)
OAUTH_MICROSOFT_CLIENT_ID=
OAUTH_MICROSOFT_CLIENT_SECRET=

# Apple OAuth (optional: set up last, requires $99/year)
OAUTH_APPLE_CLIENT_ID=
OAUTH_APPLE_CLIENT_SECRET=
```

### Production (docker-compose.yml)

```yaml
backend:
  environment:
    # OAuth2 Configuration
    - OAUTH_REDIRECT_URI_BASE=https://csfrace.com

    # Provider credentials (from secrets manager)
    - OAUTH_GOOGLE_CLIENT_ID=${OAUTH_GOOGLE_CLIENT_ID}
    - OAUTH_GOOGLE_CLIENT_SECRET=${OAUTH_GOOGLE_CLIENT_SECRET}
    - OAUTH_GITHUB_CLIENT_ID=${OAUTH_GITHUB_CLIENT_ID}
    - OAUTH_GITHUB_CLIENT_SECRET=${OAUTH_GITHUB_CLIENT_SECRET}
    - OAUTH_FACEBOOK_CLIENT_ID=${OAUTH_FACEBOOK_CLIENT_ID}
    - OAUTH_FACEBOOK_CLIENT_SECRET=${OAUTH_FACEBOOK_CLIENT_SECRET}
    - OAUTH_MICROSOFT_CLIENT_ID=${OAUTH_MICROSOFT_CLIENT_ID}
    - OAUTH_MICROSOFT_CLIENT_SECRET=${OAUTH_MICROSOFT_CLIENT_SECRET}
    - OAUTH_APPLE_CLIENT_ID=${OAUTH_APPLE_CLIENT_ID}
    - OAUTH_APPLE_CLIENT_SECRET=${OAUTH_APPLE_CLIENT_SECRET}
```

## Testing OAuth Providers

### 1. Verify Provider Availability

```bash
# Check which providers are configured (backend)
curl http://localhost:8000/auth/oauth/providers

# Expected output: All 5 providers
["google", "github", "microsoft", "facebook", "apple"]
```

### 2. Test OAuth Flow

1. Open frontend: http://localhost:3000
2. Click **"Sign In"**
3. You should see OAuth buttons for all providers
4. Click any provider button
5. You'll be redirected to provider's login page
6. After authenticating, you'll be redirected back and logged in

### 3. Verify Connected Accounts

```bash
# Get your access token from browser localStorage
TOKEN="your-access-token"

# Check connected OAuth accounts
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/auth/oauth/connections
```

### 4. Test Provider-Specific Flow

```bash
# Initiate OAuth for specific provider
curl "http://localhost:8000/auth/oauth/login/google?redirect_uri=http://localhost:3000"

# Returns authorization URL - open in browser
{
  "provider": "google",
  "authorization_url": "https://accounts.google.com/o/oauth2/v2/auth?...",
  "state": "random-state-token"
}
```

## Minimum Viable Setup

**For MVP/Testing** (Setup time: ~10-15 minutes):
1. ✅ Google OAuth
2. ✅ GitHub OAuth

**For Beta/Production** (Setup time: ~30-40 minutes):
1. ✅ Google OAuth
2. ✅ GitHub OAuth
3. ✅ Facebook OAuth
4. ⏳ Microsoft OAuth (optional)
5. ⏳ Apple OAuth (if you have iOS users and $99/year)

## Common Issues & Solutions

### Provider Not Showing in Frontend

**Symptom:** Button missing from login page

**Solution:**
1. Check backend providers endpoint:
   ```bash
   curl http://localhost:8000/auth/oauth/providers
   ```
2. If provider is missing from list, credentials are not configured
3. Add `OAUTH_<PROVIDER>_CLIENT_ID` and `OAUTH_<PROVIDER>_CLIENT_SECRET` to environment
4. Restart backend: `docker compose restart backend`

### OAuth Redirect URI Mismatch

**Symptom:** Error after clicking OAuth button: "redirect_uri_mismatch" or "invalid_redirect_uri"

**Solution:**
1. Check exact redirect URI in provider's developer console
2. Must match exactly: `http://localhost:8000/auth/oauth/<provider>/callback`
3. Include protocol (http/https), port, and trailing path
4. For production: use `https://` and your production domain

### Invalid Client ID/Secret

**Symptom:** Error: "invalid_client" or "unauthorized_client"

**Solution:**
1. Verify Client ID and Secret are correct (copy-paste from provider console)
2. Check for extra spaces or quotes in environment variables
3. Regenerate secret in provider console if necessary
4. Update environment variables and restart backend

### Email Not Provided by Provider

**Symptom:** User authenticated but has no email in your database

**Solution:**
1. Request email scope (should already be included)
2. Check if user denied email permission during login
3. Fallback: prompt user to provide email after OAuth login
4. Some providers (Apple) use private relay addresses

## Security Best Practices

### 1. Environment Variables

**❌ Never do this:**
```bash
# .env file committed to Git
OAUTH_GOOGLE_CLIENT_SECRET=actual-secret-here
```

**✅ Do this:**
```bash
# .env.example (committed to Git)
OAUTH_GOOGLE_CLIENT_ID=
OAUTH_GOOGLE_CLIENT_SECRET=

# .gitignore
.env
.env.local
.env.production
```

### 2. Secrets Rotation

- **Google/GitHub/Microsoft:** Rotate annually
- **Facebook:** Rotate every 6-12 months
- **Apple:** Must regenerate JWT every 6 months (Apple's limit)

### 3. Redirect URI Validation

- Use strict redirect URI matching in provider console
- Whitelist only necessary domains
- Development: `http://localhost:8000`
- Production: `https://csfrace.com` only

### 4. State Parameter

- All OAuth flows use state parameter (prevents CSRF)
- Backend automatically generates and validates state
- Don't disable or override this!

### 5. HTTPS in Production

- **MANDATORY** for all providers except localhost
- Use Let's Encrypt for free SSL certificates
- Configure HSTS headers for additional security

## Production Deployment Checklist

- [ ] At least 2 OAuth providers configured (recommended: Google + GitHub minimum)
- [ ] All client IDs and secrets stored in secrets manager (not .env files)
- [ ] Redirect URIs configured for production domain (https://)
- [ ] Provider apps switched from development to production mode
- [ ] HTTPS enabled with valid SSL certificate
- [ ] CORS origins configured to allow production frontend
- [ ] OAuth state validation enabled (default in backend)
- [ ] Calendar reminders set for secret rotation
- [ ] Monitoring enabled for OAuth login errors
- [ ] Fallback authentication method (email/password, passkeys) enabled

## Backend Implementation Details

All OAuth providers are implemented using:
- **Base Class:** `BaseOAuthProvider` (DRY principle)
- **Provider Classes:** `GoogleOAuthProvider`, `GitHubOAuthProvider`, etc.
- **Registry Pattern:** `OAuthProviderRegistry` (Open/Closed principle)
- **Dependency Injection:** `OAuthService` (SOLID principles)

**Code locations:**
- Providers: `backend/src/auth/oauth_service.py`
- Constants: `backend/src/constants/auth.py`
- Routes: `backend/src/auth/router.py`

**Available Endpoints:**
```
GET  /auth/oauth/providers                    # List all providers
GET  /auth/oauth/login/{provider}             # Initiate OAuth flow
GET  /auth/oauth/{provider}/callback          # OAuth callback
GET  /auth/oauth/connections                  # List user's connections
DELETE /auth/oauth/disconnect/{provider}      # Disconnect provider
```

## Frontend Implementation Details

OAuth UI is implemented using:
- **Provider Registry:** `OAuthProviderRegistry.ts` (registry pattern)
- **Components:** `OAuthButton.tsx`, `OAuthProviderList.tsx`
- **Icons:** `OAuthProviderIcons.tsx` (factory pattern)
- **Context:** `AuthContext.tsx` (state management)

**Code locations:**
- Registry: `frontend/src/components/auth/oauth/OAuthProviderRegistry.ts`
- Components: `frontend/src/components/auth/oauth/`
- Types: `frontend/src/types/oauth.ts`

## Next Steps

1. **Choose your providers** based on your user base:
   - Consumer app → Google, Facebook, Apple
   - Developer tool → GitHub, Google, Microsoft
   - Enterprise → Microsoft, Google, GitHub

2. **Set up credentials** following provider-specific guides

3. **Test locally** with development environment

4. **Deploy to production** with proper secrets management

5. **Monitor usage** and add more providers as needed

## Resources

### Provider Documentation
- [Google OAuth](https://developers.google.com/identity/protocols/oauth2)
- [GitHub OAuth](https://docs.github.com/en/developers/apps/building-oauth-apps)
- [Facebook Login](https://developers.facebook.com/docs/facebook-login)
- [Microsoft OAuth](https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow)
- [Apple Sign In](https://developer.apple.com/documentation/sign_in_with_apple)

### Internal Documentation
- [Facebook Setup Guide](./FACEBOOK_SSO_SETUP.md) ⭐ Start here!
- [Apple Setup Guide](./APPLE_SSO_SETUP.md) - Advanced
- Backend Implementation: `backend/CLAUDE.md`
- Frontend Implementation: `frontend/CLAUDE.md`

## Summary

**Your OAuth implementation is 100% complete!**

✅ All 5 providers fully implemented
✅ Backend routes working
✅ Frontend UI ready
✅ Security best practices applied

**All you need:** API credentials from each provider (10-45 minutes per provider)

**Recommended path:**
1. Google (5-10 min) → 2. GitHub (5-10 min) → 3. Facebook (10-15 min) → 4. Microsoft (15-20 min) → 5. Apple (30-45 min + $99/year)

**Start with Facebook:** See [`FACEBOOK_SSO_SETUP.md`](./FACEBOOK_SSO_SETUP.md) for the detailed guide! 🚀
