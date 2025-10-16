# Apple OAuth Setup Guide (Sign in with Apple)

Complete guide for configuring Apple OAuth for both development and production.

## Prerequisites

- ✅ Apple Developer Account ($99/year)
- ✅ Access to https://developer.apple.com/account

## Why Apple OAuth is Different

Apple uses **JWT-based client secrets** instead of static secrets:
- **Your App's JWT Secret**: Signs tokens for your users (never shared)
- **Apple OAuth Client Secret**: Authenticates your app to Apple (generated from Apple's private key)

These are completely separate and serve different purposes!

## ⚠️ IMPORTANT: Apple SSO is Production-Only

**Apple does NOT support localhost callbacks** for Sign in with Apple. While other OAuth providers (Google, Facebook, Microsoft, GitHub) work seamlessly with `localhost` during development, Apple requires:

- **Real domain name** (not localhost)
- **Valid SSL certificate** (self-signed certs require complex workarounds)
- **Domain registered** in Apple Developer Portal

### Recommended Approach:

1. **Local Development**: Skip Apple SSO entirely. Use the other 4 OAuth providers for testing authentication flows.
2. **Production/Staging**: Configure Apple SSO only when deploying to a real domain with HTTPS.

### Alternative (Advanced):
If you need Apple SSO locally, you must:
- Create a custom local domain (e.g., `local-apple.yourdomain.com`)
- Add it to `/etc/hosts` pointing to `127.0.0.1`
- Generate self-signed SSL certificates
- Configure nginx to use the custom domain and certificates
- Register the custom domain in Apple Developer Portal

**This is complex and not recommended.** It's easier to add Apple SSO when deploying to production.

---

## Step 1: Create an App ID

1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Click **"+"** → Select **"App IDs"** → Continue
3. Select **"App"** → Continue
4. Configure:
   ```
   Description: CSFrace Application
   Bundle ID: com.csfrace.app
   ```
5. Under **Capabilities**, enable:
   - ✅ **Sign in with Apple**
6. Click **Continue** → **Register**

**Save this:**
- ✅ Bundle ID: `com.csfrace.app`

---

## Step 2: Create a Service ID (Your Client ID)

This is what you'll use as `OAUTH_APPLE_CLIENT_ID`.

1. Go to: https://developer.apple.com/account/resources/identifiers/list/serviceId
2. Click **"+"** → Select **"Services IDs"** → Continue
3. Configure:
   ```
   Description: CSFrace Web Service
   Identifier: com.csfrace.webservice
   ```
   ⚠️ **This identifier becomes your OAUTH_APPLE_CLIENT_ID!**

4. Enable **"Sign in with Apple"**
5. Click **Configure** button next to "Sign in with Apple"

### Configure Web Authentication:

**Primary App ID:**
- Select: `com.csfrace.app` (from Step 1)

**Domains and Subdomains:**
- Development: `localhost`
- Production: `csfrace.com` (or your production domain)

**Return URLs:**
- Development: `https://localhost/auth/oauth/apple/callback`
- Production: `https://csfrace.com/auth/oauth/apple/callback`

⚠️ **Important:** Apple requires HTTPS, even for localhost!

6. Click **Done** → **Continue** → **Register**

**Save this:**
- ✅ Service ID: `com.csfrace.webservice`

---

## Step 3: Create a Private Key

This key generates your OAuth client secret JWT.

1. Go to: https://developer.apple.com/account/resources/authkeys/list
2. Click **"+"**
3. Configure:
   ```
   Key Name: CSFrace Sign in with Apple Key
   ```
4. Enable **"Sign in with Apple"**
5. Click **Configure** → Select `com.csfrace.app`
6. Click **Continue** → **Register**

7. **Download the .p8 file immediately!**
   ```
   Filename: AuthKey_ABC123DEFG.p8
   ```
   ⚠️ **You can only download this ONCE!** Save it securely.

8. **Note the Key ID** (shown after creation):
   ```
   Example: ABC123DEFG
   ```

**Save these:**
- ✅ Key ID: `ABC123DEFG` (10 characters)
- ✅ Private Key File: `AuthKey_ABC123DEFG.p8`

---

## Step 4: Get Your Team ID

1. Go to: https://developer.apple.com/account
2. Look in the top-right corner under your name
3. Find **"Team ID"**:
   ```
   Example: XYZ987WXYZ
   ```

**Save this:**
- ✅ Team ID: `XYZ987WXYZ` (10 characters)

---

## Step 5: Generate the Client Secret

Now use the script to generate your Apple OAuth client secret JWT.

### Install Dependencies:

```bash
cd /Users/zach/Web\ Projects/csfrace-scrape

# Install PyJWT with cryptography support
pip install pyjwt cryptography
```

### Generate the JWT:

```bash
python scripts/generate_apple_client_secret.py \
    --team-id XYZ987WXYZ \
    --key-id ABC123DEFG \
    --client-id com.csfrace.webservice \
    --key-file ~/Downloads/AuthKey_ABC123DEFG.p8 \
    --expiration-months 6
```

**Replace with your actual values:**
- `XYZ987WXYZ` → Your Team ID
- `ABC123DEFG` → Your Key ID
- `com.csfrace.webservice` → Your Service ID
- `~/Downloads/AuthKey_ABC123DEFG.p8` → Path to your .p8 file

### Output:

The script will output something like:

```bash
================================================================================
✅ Apple OAuth Client Secret Generated Successfully!
================================================================================

Add this to your .env file:

OAUTH_APPLE_CLIENT_ID=com.csfrace.webservice
OAUTH_APPLE_CLIENT_SECRET=eyJhbGciOiJFUzI1NiIsImtpZCI6IkFCQzEyM0RFRkcifQ.eyJpc3MiOiJYWVo5ODdXWFlaIiwiaWF0IjoxNzU5ODg3MDAwLCJleHAiOjE3NzU0MzkwMDAsImF1ZCI6Imh0dHBzOi8vYXBwbGVpZC5hcHBsZS5jb20iLCJzdWIiOiJjb20uY3NmcmFjZS53ZWJzZXJ2aWNlIn0.signature_here

================================================================================
⏰ This JWT expires in 6 months
   You'll need to regenerate it before expiration.
================================================================================

📅 Expiration Date: 2025-04-08 01:30:00 UTC
```

---

## Step 6: Update Environment Variables

### Development (.env and backend/.env):

```bash
# Apple OAuth Configuration
OAUTH_APPLE_CLIENT_ID=com.csfrace.webservice
OAUTH_APPLE_CLIENT_SECRET=eyJhbGciOiJFUzI1NiIsImtpZCI6IkFCQzEyM0RFRkcifQ...
```

### Production:

When deploying to production, generate a separate JWT (optional but recommended) or use the same one. Update your production environment variables accordingly.

---

## Step 7: Restart Backend

```bash
docker compose restart backend
```

---

## Step 8: Test Apple OAuth

### Via Frontend:

1. Open: https://localhost
2. Click **"Continue with Apple"**
3. Login with your Apple ID
4. Approve the permissions
5. You should be redirected back to: `https://localhost/?auth=success&is_new_user=false`

### Via Direct URL:

```bash
# Initiate OAuth flow
open https://localhost/auth/oauth/apple

# Check providers list
curl -s https://localhost/auth/oauth/providers -k | jq
```

---

## Important Notes

### JWT Expiration
- ⏰ Apple OAuth client secret JWTs expire every **6 months maximum**
- 📅 Set a calendar reminder to regenerate before expiration
- 🔄 Regenerate using the same script with the same parameters

### Production Deployment
When deploying to production:

1. **Update Return URLs in Apple Developer Console:**
   - Add: `https://csfrace.com/auth/oauth/apple/callback`
   - Keep localhost URL for development

2. **Update Domain:**
   - Add: `csfrace.com` to "Domains and Subdomains"

3. **Optional: Generate separate production JWT:**
   ```bash
   # Same command, just save separately
   python scripts/generate_apple_client_secret.py \
       --team-id XYZ987WXYZ \
       --key-id ABC123DEFG \
       --client-id com.csfrace.webservice \
       --key-file ~/AuthKey_ABC123DEFG.p8 \
       --expiration-months 6
   ```

### Security Best Practices

1. **Never commit the .p8 file to git!**
   ```bash
   # Already in .gitignore:
   *.p8
   AuthKey_*.p8
   ```

2. **Store the .p8 file securely:**
   - Use a password manager
   - Use encrypted storage
   - Keep backups in secure locations

3. **Rotate the client secret regularly:**
   - Set reminders for regeneration
   - Update both development and production
   - Test after regeneration

---

## Troubleshooting

### Error: "invalid_client"
- ✅ Verify Service ID matches OAUTH_APPLE_CLIENT_ID
- ✅ Verify client secret JWT hasn't expired
- ✅ Regenerate the client secret

### Error: "invalid_request - redirect_uri"
- ✅ Check return URL is exactly: `https://localhost/auth/oauth/apple/callback`
- ✅ Verify the return URL is configured in Apple Developer Console
- ✅ Make sure URL uses HTTPS (even for localhost)

### Error: "invalid_grant"
- ✅ Verify Team ID is correct
- ✅ Verify Key ID is correct
- ✅ Verify the .p8 file matches the Key ID

### User doesn't receive email from Apple
- Apple sometimes doesn't share the user's email
- Backend will generate a placeholder: `apple_{user_id}@users.csfrace.local`
- User can update their email in profile settings later

---

## Checklist

Before testing, verify:

- [ ] App ID created with Sign in with Apple capability
- [ ] Service ID created and configured
- [ ] Private key (.p8) downloaded and saved securely
- [ ] Team ID noted
- [ ] Key ID noted
- [ ] Return URLs configured in Apple Developer Console
- [ ] Client secret JWT generated using script
- [ ] Environment variables updated in .env and backend/.env
- [ ] Backend restarted
- [ ] Calendar reminder set for JWT expiration (6 months)

---

## Resources

- Apple Developer: https://developer.apple.com/account
- Sign in with Apple Docs: https://developer.apple.com/sign-in-with-apple/
- JWT Generation: https://developer.apple.com/documentation/sign_in_with_apple/generate_and_validate_tokens
- App IDs: https://developer.apple.com/account/resources/identifiers/list
- Service IDs: https://developer.apple.com/account/resources/identifiers/list/serviceId
- Keys: https://developer.apple.com/account/resources/authkeys/list

---

## Next Steps

Once Apple OAuth is working:

1. ✅ Test with your Apple ID
2. ✅ Verify account linking works
3. ✅ Check database for linked Apple account
4. ✅ Test sign-out and sign-in again
5. ✅ Set calendar reminder for JWT renewal (5.5 months)
