# Facebook Login (Meta) OAuth Setup Guide

## Overview
Facebook Login is **already fully implemented** in both backend and frontend. This guide shows you how to get the App ID and App Secret in ~10 minutes.

**Status:** ✅ Backend Implemented | ✅ Frontend Implemented | ⏳ Credentials Needed

**Difficulty:** ⭐ Easy (much simpler than Apple!)

## Prerequisites

1. **Facebook Account** (free)
   - Any personal Facebook account works
   - No paid developer program required!

2. **Domain Name** (optional for development)
   - For production: your domain (e.g., `csfrace.com`)
   - For development: `localhost` works fine

3. **HTTPS** (only for production)
   - Development with `http://localhost` is allowed
   - Production requires HTTPS

## Step-by-Step Setup (10 minutes)

### Step 1: Create Meta for Developers Account

1. Go to: https://developers.facebook.com/
2. Click **"Get Started"** in the top right
3. Log in with your Facebook account
4. Complete the registration:
   - Accept developer terms
   - Verify your account (email/phone)
   - Register as a developer

### Step 2: Create a New App

1. Go to: https://developers.facebook.com/apps/
2. Click **"Create App"** button
3. Choose your use case:
   - Select **"Authenticate and request data from users with Facebook Login"**
   - Click **Next**

4. Select app type:
   - Choose **"Consumer"** (for general user login)
   - Click **Next**

5. Fill in app details:
   - **App name**: `CSFrace Web Application`
   - **App contact email**: `your-email@example.com`
   - **Business account** (optional): Skip or create
   - Click **Create app**

6. You may need to enter your Facebook password to confirm

### Step 3: Get Your App ID and App Secret

After creating the app, you'll see the app dashboard.

1. In the left sidebar, click **Settings** → **Basic**

2. Find your credentials:
   ```
   App ID: 123456789012345
   App Secret: [Click "Show" to reveal] → abc123def456...
   ```

3. **IMPORTANT**: Click **"Show"** next to App Secret and save both:
   - App ID (Client ID) - this is public
   - App Secret (Client Secret) - this is confidential!

4. Scroll down and fill in required fields:
   - **App Domains**: `csfrace.com` (production) or `localhost` (dev)
   - **Privacy Policy URL**: `https://csfrace.com/privacy`
   - **Terms of Service URL**: `https://csfrace.com/terms` (optional)
   - **App Icon**: Upload a logo (1024x1024 PNG recommended)

5. Click **"Save Changes"** at the bottom

### Step 4: Add Facebook Login Product

1. In the left sidebar, click **"+ Add Product"**
2. Find **"Facebook Login"** and click **"Set Up"**
3. Choose platform:
   - Select **"Web"** (we have a web application)
   - Click **Next**

4. Site URL Configuration:
   - **For Development**:
     ```
     Site URL: http://localhost:3000
     ```
   - **For Production**:
     ```
     Site URL: https://csfrace.com
     ```
   - Click **"Save"** → **"Continue"**

5. You can skip the quickstart wizard by clicking **"Settings"** in the left sidebar under **Facebook Login**

### Step 5: Configure OAuth Redirect URIs

1. In left sidebar: **Facebook Login** → **Settings**

2. Configure Valid OAuth Redirect URIs:
   ```
   Development:
   http://localhost:8000/auth/oauth/facebook/callback
   http://localhost:3000/auth/oauth/facebook/callback

   Production:
   https://csfrace.com/auth/oauth/facebook/callback
   https://api.csfrace.com/auth/oauth/facebook/callback
   ```

   - Add each URL on a new line
   - Click **"Save Changes"**

3. **Client OAuth Settings**:
   - ✅ Client OAuth Login: **Enabled**
   - ✅ Web OAuth Login: **Enabled**
   - ✅ Use Strict Mode for Redirect URIs: **Enabled** (recommended for security)

4. **Login from Devices**:
   - Leave default settings

### Step 6: Configure App Permissions (Data Access)

1. In left sidebar: **App Review** → **Permissions and Features**

2. Request these permissions (all are auto-approved for development):
   - ✅ **email** - Get user's email address
   - ✅ **public_profile** - Get user's name and profile picture

   These are the only permissions we need and they're automatically granted!

### Step 7: Make App Live (Production Only)

**For Development**: Skip this - you can test with any Facebook account in "Development Mode"

**For Production**:
1. Complete all required fields in **Settings** → **Basic**
2. Add **Privacy Policy URL** (required by Meta)
3. Upload **App Icon** (1024x1024px minimum)
4. In top bar, toggle switch from **"Development"** to **"Live"**
5. Confirm the switch to go live

⚠️ **Note**: In Development Mode, only you and added test users/developers can log in. In Live Mode, anyone can log in.

### Step 8: Configure Environment Variables

Add to your `.env` file:

```bash
# Facebook OAuth Configuration
OAUTH_FACEBOOK_CLIENT_ID=123456789012345
OAUTH_FACEBOOK_CLIENT_SECRET=abc123def456ghi789jkl012mno345pqr678

# Update redirect URI base (if different from default)
OAUTH_REDIRECT_URI_BASE=http://localhost:8000  # Development
# OAUTH_REDIRECT_URI_BASE=https://csfrace.com  # Production
```

Or update your `docker-compose.yml`:

```yaml
backend:
  environment:
    - OAUTH_FACEBOOK_CLIENT_ID=123456789012345
    - OAUTH_FACEBOOK_CLIENT_SECRET=abc123def456...
```

### Step 9: Test in Development

1. Restart your Docker stack:
   ```bash
   docker compose down
   docker compose up -d
   ```

2. Verify Facebook is listed:
   ```bash
   curl http://localhost:8000/auth/oauth/providers
   # Should include "facebook"
   ```

3. Open frontend: http://localhost:3000
4. Click **"Sign In"** → **"Continue with Facebook"**
5. You'll be redirected to Facebook login
6. Authorize the app
7. You'll be redirected back to your app and logged in!

## Important Notes

### Development Mode Testing

In **Development Mode**, only these users can log in:
- App admins (you)
- App developers (added in Roles)
- Test users (created in Roles → Test Users)

To add test users:
1. Go to **Roles** → **Test Users**
2. Click **"Add Test Users"**
3. Create test Facebook accounts for testing

### Security Best Practices

1. **Never commit credentials**:
   ```bash
   # Add to .gitignore
   .env
   .env.local
   .env.production
   ```

2. **Use environment variables**:
   - Development: `.env` file
   - Production: Docker secrets / AWS Secrets Manager

3. **Rotate secrets periodically**:
   - You can regenerate App Secret in Settings → Basic
   - Click "Reset App Secret"
   - Update your environment variables

4. **Monitor usage**:
   - Check **Analytics** dashboard for login stats
   - Review **App Review** for any policy violations

### Facebook-Specific Behaviors

1. **Email Permission**:
   - User can deny email access
   - Always check if email is provided in response
   - Have a fallback (ask user to provide email)

2. **Profile Picture**:
   - Facebook provides `picture.data.url`
   - Backend fetches large profile picture automatically
   - URL expires after ~2 hours (cache it in your DB)

3. **Account Deletion**:
   - Facebook requires you to provide a data deletion callback
   - Add this in **Settings** → **Basic** → **Data Deletion Request URL**
   - Example: `https://csfrace.com/auth/facebook/delete-data`

4. **Business Verification** (optional):
   - Required for apps with >10,000 users
   - Required for certain advanced permissions
   - Not needed for basic login

### Troubleshooting

**Error: "redirect_uri_mismatch"**
- Redirect URI not added to Valid OAuth Redirect URIs
- Exact match required (including http vs https, trailing slash)
- Solution: Double-check Settings → Facebook Login → Valid OAuth Redirect URIs

**Error: "App Not Set Up: This app is still in development mode"**
- App is in Development Mode
- User is not added as test user/developer
- Solution: Add user as Test User or switch app to Live mode

**Error: "Invalid App ID"**
- Wrong App ID in environment variable
- App was deleted or suspended
- Solution: Verify App ID in Settings → Basic

**Error: "Invalid Client Secret"**
- Wrong App Secret in environment variable
- App Secret was regenerated but not updated
- Solution: Verify App Secret (click "Show" in Settings → Basic)

**Can't see "Continue with Facebook" button**
- Facebook not enabled in frontend
- Check browser console for errors
- Verify OAuth providers endpoint returns "facebook"

**Facebook login works but no email received**
- User denied email permission during login
- Email not verified on Facebook account
- Solution: Request email explicitly, handle missing email gracefully

## App Review & Permissions

For **basic login** (email + public_profile), you don't need App Review! These are auto-approved.

If you need additional permissions (like `user_birthday`, `user_photos`, etc.):

1. Go to **App Review** → **Permissions and Features**
2. Find the permission you need
3. Click **"Request"**
4. Fill out the questionnaire explaining why you need it
5. Provide screencast demo of your app using the permission
6. Submit for review (typically takes 2-7 days)

## Production Deployment Checklist

- [ ] Meta for Developers account created (free)
- [ ] App created in Facebook Developer Console
- [ ] App ID and App Secret saved
- [ ] Facebook Login product added
- [ ] Valid OAuth Redirect URIs configured for production domain
- [ ] Privacy Policy URL added (required for Live mode)
- [ ] App icon uploaded
- [ ] App switched from Development to Live mode
- [ ] Environment variables configured in production
- [ ] Tested login flow in production
- [ ] Data deletion callback implemented (required by Facebook)
- [ ] App monitoring enabled (Analytics dashboard)

## Quick Reference

```bash
# Environment Variables
OAUTH_FACEBOOK_CLIENT_ID=123456789012345
OAUTH_FACEBOOK_CLIENT_SECRET=abc123def456...

# Backend Endpoints (already implemented)
GET  /auth/oauth/providers             # Lists "facebook"
GET  /auth/oauth/login/facebook        # Initiates Facebook OAuth
GET  /auth/oauth/facebook/callback     # Handles Facebook redirect
GET  /auth/oauth/connections           # Shows linked Facebook account

# Test Commands
curl http://localhost:8000/auth/oauth/providers
curl "http://localhost:8000/auth/oauth/login/facebook?redirect_uri=http://localhost:3000"
```

## Comparison: Facebook vs Apple

| Feature | Facebook | Apple |
|---------|----------|-------|
| **Setup Time** | ~10 minutes ⭐ | ~30-45 minutes |
| **Cost** | Free ✅ | $99/year |
| **Complexity** | Very simple | Complex (JWT, keys, domain verification) |
| **Client Secret** | Static string | Generated JWT (expires every 6 months) |
| **Domain Verification** | Not required | Required (`.well-known` file) |
| **Email Privacy** | Optional | Private relay supported |
| **Profile Picture** | Provided | Not provided |
| **Development Testing** | Easy (test users) | Requires production setup |

**Recommendation**: Start with Facebook/Google/GitHub (simple), add Apple later when you need it.

## Resources

- [Meta for Developers](https://developers.facebook.com/)
- [Facebook Login Documentation](https://developers.facebook.com/docs/facebook-login/web)
- [Facebook Login Best Practices](https://developers.facebook.com/docs/facebook-login/security/)
- [Facebook Platform Policy](https://developers.facebook.com/policy/)
- [Graph API Explorer](https://developers.facebook.com/tools/explorer/) - Test API calls

## Summary

**What's Already Done:**
✅ Backend FacebookOAuthProvider fully implemented
✅ Frontend Facebook sign-in button with icon
✅ Facebook listed in available OAuth providers
✅ Callback routes configured
✅ Profile picture fetching

**What You Need to Do:**
1. Create Meta for Developers account (free, instant)
2. Create app in Facebook Developer Console (~5 minutes)
3. Get App ID and App Secret (instant)
4. Configure redirect URIs (~2 minutes)
5. Add credentials to environment variables (~1 minute)
6. Test the flow! (~2 minutes)

**Total setup time: ~10 minutes** (vs 30-45 for Apple)

**Best part:** No paid account, no JWT generation, no private keys, no domain verification files! 🎉
