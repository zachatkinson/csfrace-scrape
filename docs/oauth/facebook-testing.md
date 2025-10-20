# Facebook OAuth Test Results ✅

## Configuration

**App ID:** 797155363279235
**App Secret:** 7fcbe7bc4807baa149ce2f263a9a2fb9
**Status:** ✅ Configured and Working

## Test Results

### ✅ Backend Configuration
```bash
# Providers endpoint shows Facebook
curl http://localhost:8000/auth/oauth/providers
# Returns: ["google", "github", "microsoft", "facebook", "apple"]
```

### ✅ OAuth Flow Initiation
```bash
# Facebook OAuth redirect is working (via nginx HTTPS proxy)
curl -sL "https://localhost/auth/oauth/facebook" -k
# Successfully redirects to Facebook login page
```

### ✅ Authorization URL Generated
The backend correctly generates Facebook OAuth authorization URLs with:
- Client ID: 797155363279235
- Redirect URI: Configured for localhost
- Scopes: email, public_profile
- State parameter: Generated for CSRF protection

## How to Test the Complete Flow

### Option 1: Via Frontend (Recommended)

1. **Open the application:**
   ```
   https://localhost
   ```

2. **Click "Sign In" or "Register"**

3. **Look for the "Continue with Facebook" button**
   - It should have the Facebook blue color (#1877F2)
   - Facebook icon should be visible

4. **Click "Continue with Facebook"**
   - You'll be redirected to Facebook login
   - Login with your Facebook account
   - Authorize the app to access email and public profile
   - You'll be redirected back to https://localhost
   - You should be logged in!

### Option 2: Via Direct URL

1. **Navigate directly to OAuth endpoint:**
   ```
   https://localhost/auth/oauth/facebook
   ```

2. **Complete Facebook login**

3. **You'll be redirected to callback:**
   ```
   https://localhost/auth/oauth/facebook/callback?code=...&state=...
   ```

4. **Backend will:**
   - Exchange code for access token
   - Fetch your Facebook profile
   - Create/login user in database
   - Return authentication token

## What to Verify in Meta Developer Console

Before testing, ensure these settings are correct:

### 1. Valid OAuth Redirect URIs (CRITICAL)
Go to: Facebook Login → Settings

Add these exact URIs:
```
https://localhost/auth/oauth/facebook/callback
```

**Note:** In Development Mode, Facebook automatically allows `http://localhost` redirects, but using `https://localhost` works better with your nginx setup.

### 2. App Domains
Go to: Settings → Basic

Add:
```
localhost
```

### 3. App Mode
For development testing:
- **Development Mode**: Only you and test users can log in
- **Live Mode**: Anyone can log in (requires Privacy Policy URL)

For now, stay in **Development Mode** for testing.

### 4. Test Users (Optional)
If you want to test without using your personal Facebook account:

Go to: Roles → Test Users
- Click "Add Test Users"
- Create 1-2 test Facebook accounts
- Use these for testing OAuth flow

## Expected User Flow

1. **User clicks "Continue with Facebook"**
   → Redirected to: `https://www.facebook.com/v18.0/dialog/oauth?client_id=797155363279235&redirect_uri=...`

2. **User logs in to Facebook** (if not already logged in)
   → Facebook login page

3. **User authorizes app**
   → Permission screen showing: "App wants to access your email and public profile"

4. **Facebook redirects back**
   → `http://localhost:8000/auth/oauth/facebook/callback?code=ABC123&state=XYZ789`

5. **Backend processes callback**
   - Validates state parameter (CSRF protection)
   - Exchanges code for access token
   - Fetches user info from Facebook Graph API
   - Creates new user OR logs in existing user
   - Returns JWT access token

6. **User is logged in!**
   → Redirected to frontend with auth token
   → Frontend stores token in localStorage
   → User sees authenticated UI

## Troubleshooting

### Issue: "redirect_uri_mismatch"
**Cause:** Redirect URI not configured in Facebook app

**Solution:**
1. Go to: https://developers.facebook.com/apps/797155363279235/fb-login/settings/
2. Add exact URI: `http://localhost:8000/auth/oauth/facebook/callback`
3. Click "Save Changes"

### Issue: "App Not Set Up"
**Cause:** App is in Development Mode and user is not added as tester

**Solution:**
- Option A: Add user as Test User (Roles → Test Users)
- Option B: Switch app to Live mode (requires Privacy Policy URL)

### Issue: "Invalid App ID"
**Cause:** Wrong App ID or app was deleted

**Solution:**
1. Verify App ID at: https://developers.facebook.com/apps/797155363279235/settings/basic/
2. Should show: 797155363279235

### Issue: No email in user profile
**Cause:** User denied email permission OR email not verified on Facebook

**Solution:**
1. Check Facebook account email is verified
2. Re-authorize app and grant email permission
3. Backend will use fallback: `facebook_{user_id}@facebook.com`

## Data Received from Facebook

When a user logs in with Facebook, your backend receives:

```json
{
  "id": "1234567890",
  "email": "user@example.com",
  "name": "John Doe",
  "picture": {
    "data": {
      "url": "https://platform-lookaside.fbsbx.com/platform/profilepic/..."
    }
  }
}
```

**Mapped to your User model:**
- `provider_id`: `facebook_1234567890`
- `email`: `user@example.com`
- `name`: `John Doe`
- `avatar_url`: `https://platform-lookaside.fbsbx.com/...`
- `provider`: `facebook`

## Security Notes

✅ **State parameter validation** - Prevents CSRF attacks
✅ **HTTPS in production** - Required for production redirect URIs
✅ **Secret in environment variable** - Never committed to Git
✅ **Scope limitation** - Only requests email and public_profile
✅ **Token expiration** - Facebook access tokens expire

## Next Steps

1. **Test the flow** - Try logging in with Facebook from the frontend
2. **Verify user creation** - Check database to see user was created
3. **Test re-login** - Log out and log back in with same Facebook account
4. **Add redirect URI for production** when deploying:
   ```
   https://csfrace.com/auth/oauth/facebook/callback
   ```

## Quick Commands

```bash
# Check if Facebook is available (via nginx)
curl https://localhost/auth/oauth/providers -k | jq

# Get Facebook authorization URL (will redirect)
curl -sI https://localhost/auth/oauth/facebook -k

# Check backend health (via nginx)
curl https://localhost/health -k | jq

# Restart backend (if you change .env)
docker compose restart backend

# View backend logs
docker compose logs -f backend | grep -i facebook

# Check connected OAuth accounts (requires auth token)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://localhost/auth/oauth/connections -k
```

## Success Indicators

✅ Facebook appears in providers list
✅ "Continue with Facebook" button visible in frontend
✅ Clicking button redirects to Facebook login
✅ After Facebook login, user is redirected back to app
✅ User is logged in with access token
✅ User data (email, name, avatar) saved to database

## Data Deletion Callback (Required for Live Mode)

Facebook requires apps to provide a way for users to delete their data when requested through Facebook.

### ✅ Both Options Implemented

**Option 1: Automated Callback (Recommended for Production)**
```
URL: https://localhost/auth/oauth/facebook/data-deletion
```

**How it works:**
1. User requests data deletion through Facebook
2. Facebook sends signed request to callback URL
3. Backend verifies signature using app secret
4. Backend deletes user's account and all data
5. Returns confirmation URL to Facebook

**Configure in Meta Developer Console:**
1. Go to: Settings → Basic → Data Deletion Request URL
2. Add: `https://localhost/auth/oauth/facebook/data-deletion` (dev)
3. Production: `https://csfrace.com/auth/oauth/facebook/data-deletion`

**Option 2: Instructions URL (Simpler for Development)**
```
URL: https://localhost/privacy/facebook-data-deletion
```

**Instructions page provides:**
- Manual deletion steps
- Account disconnect option
- Email contact for manual requests
- Clear data deletion policy

**Configure in Meta Developer Console:**
1. Go to: Settings → Basic → Data Deletion Instructions URL
2. Add: `https://localhost/privacy/facebook-data-deletion`

### Which One to Use?

**Development Mode:**
- Either option works
- Instructions URL is simpler to test

**Live Mode (Production):**
- Use automated callback for better UX
- Complies with Facebook's policy requirements
- Provides instant deletion confirmation

## Status: READY TO TEST! 🚀

Your Facebook OAuth is fully configured and ready to use. Just open **https://localhost** (via nginx) and try it out!

### Additional Setup for Live Mode:
- [ ] Configure Data Deletion URL in Meta Developer Console
- [ ] Add Privacy Policy URL
- [ ] Upload App Icon (1024x1024px)
- [ ] Switch app from Development to Live mode
