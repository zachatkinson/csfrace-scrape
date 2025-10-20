# Apple Sign In with OAuth Setup Guide

## Overview
Apple Sign In (Sign in with Apple) is **already fully implemented** in both backend and frontend. This guide shows you how to get the credentials needed to enable it.

**Status:** ✅ Backend Implemented | ✅ Frontend Implemented | ⏳ Credentials Needed

## Prerequisites

1. **Apple Developer Account** ($99/year)
   - Enroll at: https://developer.apple.com/programs/enroll/
   - Must be verified before you can create App IDs and Services

2. **Domain Name**
   - Apple requires verification of your domain
   - Example: `csfrace.com`

3. **HTTPS**
   - All redirect URIs must use HTTPS (except `localhost` for development)

## Step-by-Step Setup

### Step 1: Create an App ID

1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Click the **"+"** button to create a new identifier
3. Select **"App IDs"** → Continue
4. Choose **"App"** → Continue
5. Fill in the details:
   - **Description**: `CSFrace Web Application`
   - **Bundle ID**: Select "Explicit" and enter: `com.csfrace.web`
     - This MUST be unique and reverse-domain format
   - **Capabilities**: Check ✅ **"Sign in with Apple"**
6. Click **Continue** → **Register**

### Step 2: Create a Services ID (This becomes your Client ID)

1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Click the **"+"** button again
3. Select **"Services IDs"** → Continue
4. Fill in the details:
   - **Description**: `CSFrace Sign In Service`
   - **Identifier**: `com.csfrace.web.signin`
     - **IMPORTANT**: This identifier **IS your Client ID** - save it!
   - Check ✅ **"Sign in with Apple"**
5. Click **Continue** → **Register**

### Step 3: Configure Sign in with Apple for Services ID

1. Find your newly created Services ID in the list
2. Click on it to open configuration
3. Check ✅ **"Sign in with Apple"** if not already checked
4. Click **Configure** next to "Sign in with Apple"
5. Configure domains and URLs:

   **Primary App ID**: Select `com.csfrace.web` (from Step 1)

   **Domains and Subdomains**:
   ```
   csfrace.com
   ```
   - Click **"+"** to add domain
   - Apple will verify domain ownership (see Step 4)

   **Return URLs** (Redirect URIs):
   ```
   https://csfrace.com/auth/oauth/apple/callback
   https://localhost:8000/auth/oauth/apple/callback (for development)
   ```
   - Click **"+"** to add each URL
   - These must match exactly what your backend uses

6. Click **Save** → **Continue** → **Save**

### Step 4: Verify Domain Ownership

Apple requires you to verify domain ownership by placing a file on your web server.

1. Click **Download** to get the verification file (e.g., `apple-developer-domain-association.txt`)
2. Upload it to your web server at:
   ```
   https://csfrace.com/.well-known/apple-developer-domain-association.txt
   ```
3. Verify it's accessible:
   ```bash
   curl https://csfrace.com/.well-known/apple-developer-domain-association.txt
   ```
4. Go back to Apple Developer portal and click **Verify**
5. If verification fails:
   - Ensure file is accessible publicly (no authentication required)
   - Check HTTPS certificate is valid
   - Ensure no redirects are happening
   - Wait a few minutes and try again

### Step 5: Create a Private Key (For Client Secret Generation)

Apple uses JWT (JSON Web Tokens) for the client secret, which requires a private key.

1. Go to: https://developer.apple.com/account/resources/authkeys/list
2. Click **"+"** to create a new key
3. Fill in the details:
   - **Key Name**: `CSFrace Sign In Key`
   - Check ✅ **"Sign in with Apple"**
4. Click **Configure** next to "Sign in with Apple"
5. Select your **Primary App ID**: `com.csfrace.web`
6. Click **Save** → **Continue** → **Register**
7. **CRITICAL**: Click **Download** to download the `.p8` file
   - **This is the ONLY time you can download this file!**
   - Filename format: `AuthKey_XXXXXXXXXX.p8`
   - The **Key ID** is shown (e.g., `XXXXXXXXXX`) - **save this!**
8. Also note your **Team ID**:
   - Found in the top right of the Apple Developer portal
   - Format: `YYYYYYYYYY` (10 characters)

### Step 6: Generate Client Secret (JWT)

Apple's "client secret" is actually a JWT that you generate using the private key.

**Option A: Use Python Script** (Recommended for our stack)

Create `scripts/generate_apple_secret.py`:

```python
#!/usr/bin/env python3
"""Generate Apple Sign In Client Secret (JWT).

This JWT must be regenerated every 6 months (Apple's maximum lifetime).
"""

import jwt
import time
from pathlib import Path

# CONFIGURATION - Replace with your values
TEAM_ID = "YYYYYYYYYY"  # Your Apple Developer Team ID
CLIENT_ID = "com.csfrace.web.signin"  # Your Services ID
KEY_ID = "XXXXXXXXXX"  # From the downloaded .p8 key filename
KEY_FILE = "AuthKey_XXXXXXXXXX.p8"  # Path to your downloaded .p8 file

# Read the private key
with open(KEY_FILE, 'r') as f:
    private_key = f.read()

# Generate JWT (valid for 6 months - Apple's maximum)
headers = {
    "kid": KEY_ID,
    "alg": "ES256"
}

payload = {
    "iss": TEAM_ID,
    "iat": int(time.time()),
    "exp": int(time.time()) + 15777000,  # 6 months (Apple's max: 15777000 seconds)
    "aud": "https://appleid.apple.com",
    "sub": CLIENT_ID
}

# Generate the client secret
client_secret = jwt.encode(
    payload,
    private_key,
    algorithm="ES256",
    headers=headers
)

print("=" * 80)
print("Apple Sign In Client Secret (JWT)")
print("=" * 80)
print(f"\nClient ID (Services ID):")
print(f"  {CLIENT_ID}")
print(f"\nClient Secret (JWT - valid for 6 months):")
print(f"  {client_secret}")
print(f"\nExpires: {time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(payload['exp']))}")
print("\n⚠️  IMPORTANT:")
print("  - This secret expires in 6 months - set a reminder to regenerate!")
print("  - Store this secret securely (environment variable or secrets manager)")
print("  - Never commit this to version control!")
print("=" * 80)
```

**Install dependencies**:
```bash
pip install pyjwt cryptography
```

**Run the script**:
```bash
python scripts/generate_apple_secret.py
```

**Option B: Use Online JWT Generator**

1. Go to: https://jwt.io/
2. Set algorithm to **ES256**
3. Header:
   ```json
   {
     "kid": "XXXXXXXXXX",
     "alg": "ES256"
   }
   ```
4. Payload:
   ```json
   {
     "iss": "YYYYYYYYYY",
     "iat": 1735689600,
     "exp": 1751467200,
     "aud": "https://appleid.apple.com",
     "sub": "com.csfrace.web.signin"
   }
   ```
   - `iat`: Current Unix timestamp
   - `exp`: Current timestamp + 15777000 (6 months)
   - Use: https://www.unixtimestamp.com/ for conversion
5. Paste your `.p8` file contents into the private key field
6. Copy the generated JWT - this is your **Client Secret**

### Step 7: Configure Environment Variables

Add to your `.env` file or Docker environment:

```bash
# Apple OAuth Configuration
OAUTH_APPLE_CLIENT_ID=com.csfrace.web.signin
OAUTH_APPLE_CLIENT_SECRET=eyJhbGciOiJFUzI1NiIsImtpZCI6IlhYWFhYWFhYWFgifQ.eyJpc3MiOiJZWVlZWVlZWVlWSIsImlhdCI6MTczNTY4OTYwMCwiZXhwIjoxNzUxNDY3MjAwLCJhdWQiOiJodHRwczovL2FwcGxlaWQuYXBwbGUuY29tIiwic3ViIjoiY29tLmNzZnJhY2Uud2ViLnNpZ25pbiJ9.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Update the redirect URI base (production)
OAUTH_REDIRECT_URI_BASE=https://csfrace.com
```

### Step 8: Test in Development

1. Start your Docker stack:
   ```bash
   docker compose up -d
   ```

2. Verify Apple is listed in available providers:
   ```bash
   curl http://localhost:8000/auth/oauth/providers
   ```
   Should include `"apple"` in the list.

3. Open frontend: http://localhost:3000
4. Click "Sign In" → "Continue with Apple"
5. You'll be redirected to Apple's sign-in page
6. After authenticating, you'll be redirected back to your app

## Important Notes

### Security Best Practices

1. **Never commit credentials to Git**:
   ```bash
   # Add to .gitignore
   AuthKey_*.p8
   .env
   .env.local
   ```

2. **Store secrets securely**:
   - Use environment variables (development)
   - Use Docker secrets (production)
   - Use AWS Secrets Manager / Azure Key Vault (cloud)

3. **Regenerate client secret every 6 months**:
   - Set calendar reminder for JWT expiration
   - Apple's maximum is 6 months (15,777,000 seconds)
   - Generate new JWT before expiration

4. **Rotate keys annually**:
   - Create new private key in Apple Developer portal
   - Generate new JWT with new key
   - Update environment variables
   - Revoke old key after transition period

### Apple-Specific Behaviors

1. **Email Privacy**:
   - Users can hide their real email
   - Apple provides a private relay: `user@privaterelay.appleid.com`
   - Your app receives forwarded emails
   - Handle this gracefully in your user model

2. **Name Sharing**:
   - Name is only provided on first sign-in
   - Subsequent logins won't include name
   - Cache user's name in your database

3. **No Avatar**:
   - Apple doesn't provide profile pictures
   - Use initials or default avatar

4. **Form POST Response**:
   - Apple uses `response_mode=form_post` (not query params)
   - Backend already handles this correctly

### Troubleshooting

**Error: "invalid_client"**
- Client Secret (JWT) is expired → Generate new JWT
- Client ID doesn't match Services ID → Check `OAUTH_APPLE_CLIENT_ID`
- Wrong Team ID in JWT → Verify Team ID in payload

**Error: "invalid_grant"**
- Authorization code already used → Codes are single-use
- Code expired → Codes expire after 5 minutes
- Redirect URI mismatch → Check exact match in configuration

**Error: "unauthorized_client"**
- Redirect URI not configured → Add to Services ID configuration
- Domain not verified → Complete domain verification (Step 4)

**Can't verify domain**:
- File not accessible at `/.well-known/apple-developer-domain-association.txt`
- HTTPS certificate invalid
- Redirect from HTTP to HTTPS breaks verification
- File contains BOM or extra whitespace

## Production Deployment Checklist

- [ ] Apple Developer account verified ($99/year)
- [ ] App ID created with Sign in with Apple capability
- [ ] Services ID created (this is your Client ID)
- [ ] Domain verified with `.well-known` file
- [ ] Production redirect URI configured: `https://csfrace.com/auth/oauth/apple/callback`
- [ ] Private key (`.p8`) downloaded and stored securely
- [ ] Client Secret (JWT) generated with 6-month expiration
- [ ] Environment variables configured in production
- [ ] Calendar reminder set for JWT renewal (6 months)
- [ ] Tested in production environment
- [ ] Email handling tested (including private relay addresses)
- [ ] Error handling verified for Apple-specific cases

## Quick Reference

```bash
# Environment Variables Needed
OAUTH_APPLE_CLIENT_ID=com.csfrace.web.signin
OAUTH_APPLE_CLIENT_SECRET=<your-generated-jwt>

# Backend Endpoints (already implemented)
GET  /auth/oauth/providers          # Lists "apple" as available
GET  /auth/oauth/login/apple        # Initiates Apple OAuth flow
POST /auth/oauth/apple/callback     # Handles Apple redirect
GET  /auth/oauth/connections        # Shows linked Apple account

# Test Commands
curl http://localhost:8000/auth/oauth/providers
curl http://localhost:8000/auth/oauth/login/apple
```

## Resources

- [Apple Sign In Documentation](https://developer.apple.com/documentation/sign_in_with_apple)
- [Apple Sign In REST API](https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api)
- [Generating Client Secrets](https://developer.apple.com/documentation/sign_in_with_apple/generate_and_validate_tokens)
- [PyJWT Documentation](https://pyjwt.readthedocs.io/)

## Summary

**What's Already Done:**
✅ Backend AppleOAuthProvider fully implemented
✅ Frontend Apple sign-in button with icon
✅ Apple listed in available OAuth providers
✅ Callback routes configured
✅ JWT-based authentication handling

**What You Need to Do:**
1. Create Apple Developer account ($99/year)
2. Create App ID + Services ID in Apple Developer portal
3. Verify domain ownership
4. Generate private key and create JWT for client secret
5. Add credentials to environment variables
6. Test the flow!

Total setup time: ~30-45 minutes (first time)
