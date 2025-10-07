#!/usr/bin/env python3
"""Generate Apple Sign In Client Secret (JWT).

This JWT must be regenerated every 6 months (Apple's maximum lifetime).

Usage:
    python scripts/generate_apple_secret.py

Requirements:
    pip install pyjwt cryptography

Apple Documentation:
    https://developer.apple.com/documentation/sign_in_with_apple/generate_and_validate_tokens
"""

import argparse
import sys
import time
from pathlib import Path

try:
    import jwt
except ImportError:
    print("❌ Error: PyJWT library not installed")
    print("Install it with: pip install pyjwt cryptography")
    sys.exit(1)


def generate_apple_client_secret(
    team_id: str,
    client_id: str,
    key_id: str,
    key_file: str,
    validity_months: int = 6
) -> str:
    """Generate Apple Sign In Client Secret JWT.

    Args:
        team_id: Your Apple Developer Team ID (10 characters)
        client_id: Your Services ID (e.g., com.example.signin)
        key_id: Key ID from the .p8 filename
        key_file: Path to the .p8 private key file
        validity_months: JWT validity in months (max 6)

    Returns:
        JWT client secret string

    Raises:
        FileNotFoundError: If key file doesn't exist
        ValueError: If validity exceeds 6 months
    """
    # Validate validity period (Apple's max is 6 months)
    max_seconds = 15777000  # 6 months in seconds
    validity_seconds = validity_months * 30 * 24 * 60 * 60

    if validity_seconds > max_seconds:
        raise ValueError("Validity cannot exceed 6 months (Apple's maximum)")

    # Read the private key
    key_path = Path(key_file)
    if not key_path.exists():
        raise FileNotFoundError(f"Private key file not found: {key_file}")

    with open(key_path, 'r') as f:
        private_key = f.read()

    # JWT headers
    headers = {
        "kid": key_id,
        "alg": "ES256"  # Apple requires ES256 algorithm
    }

    # JWT payload
    current_time = int(time.time())
    payload = {
        "iss": team_id,
        "iat": current_time,
        "exp": current_time + validity_seconds,
        "aud": "https://appleid.apple.com",
        "sub": client_id
    }

    # Generate the client secret
    client_secret = jwt.encode(
        payload,
        private_key,
        algorithm="ES256",
        headers=headers
    )

    return client_secret, payload['exp']


def main():
    """Main function with interactive prompts."""
    parser = argparse.ArgumentParser(
        description="Generate Apple Sign In Client Secret (JWT)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Interactive mode (recommended for first use)
    python scripts/generate_apple_secret.py

    # Non-interactive mode
    python scripts/generate_apple_secret.py \\
        --team-id YYYYYYYYYY \\
        --client-id com.csfrace.web.signin \\
        --key-id XXXXXXXXXX \\
        --key-file AuthKey_XXXXXXXXXX.p8

Note:
    The generated JWT is valid for 6 months (Apple's maximum).
    Set a calendar reminder to regenerate before expiration!
        """
    )

    parser.add_argument(
        "--team-id",
        help="Apple Developer Team ID (10 characters, found in top-right of developer portal)"
    )
    parser.add_argument(
        "--client-id",
        help="Services ID / Client ID (e.g., com.csfrace.web.signin)"
    )
    parser.add_argument(
        "--key-id",
        help="Key ID from the .p8 filename (e.g., XXXXXXXXXX)"
    )
    parser.add_argument(
        "--key-file",
        help="Path to the .p8 private key file"
    )
    parser.add_argument(
        "--validity-months",
        type=int,
        default=6,
        help="JWT validity in months (default: 6, maximum: 6)"
    )

    args = parser.parse_args()

    print("=" * 80)
    print("Apple Sign In Client Secret Generator")
    print("=" * 80)
    print()

    # Interactive prompts if arguments not provided
    team_id = args.team_id
    if not team_id:
        print("📋 Find your Team ID:")
        print("   → Go to: https://developer.apple.com/account")
        print("   → Look in the top-right corner (10 character code)")
        print()
        team_id = input("Enter your Team ID: ").strip()

    client_id = args.client_id
    if not client_id:
        print()
        print("🆔 Your Client ID is your Services ID:")
        print("   → Go to: https://developer.apple.com/account/resources/identifiers/list")
        print("   → Select 'Services IDs'")
        print("   → Copy the Identifier (e.g., com.csfrace.web.signin)")
        print()
        client_id = input("Enter your Client ID (Services ID): ").strip()

    key_id = args.key_id
    if not key_id:
        print()
        print("🔑 Your Key ID is in the filename of your .p8 file:")
        print("   → Filename format: AuthKey_XXXXXXXXXX.p8")
        print("   → The Key ID is the XXXXXXXXXX part")
        print()
        key_id = input("Enter your Key ID: ").strip()

    key_file = args.key_file
    if not key_file:
        print()
        print("📄 Path to your private key (.p8 file):")
        print("   → Downloaded from: https://developer.apple.com/account/resources/authkeys/list")
        print()
        key_file = input("Enter path to .p8 file (e.g., AuthKey_XXXXXXXXXX.p8): ").strip()

    # Validate inputs
    if not all([team_id, client_id, key_id, key_file]):
        print("\n❌ Error: All fields are required!")
        sys.exit(1)

    try:
        # Generate the client secret
        print()
        print("⏳ Generating JWT client secret...")
        client_secret, expiration = generate_apple_client_secret(
            team_id=team_id,
            client_id=client_id,
            key_id=key_id,
            key_file=key_file,
            validity_months=args.validity_months
        )

        # Display results
        print()
        print("=" * 80)
        print("✅ SUCCESS - Apple Sign In Credentials Generated")
        print("=" * 80)
        print()
        print(f"Client ID (Services ID):")
        print(f"  {client_id}")
        print()
        print(f"Client Secret (JWT - valid for {args.validity_months} months):")
        print(f"  {client_secret}")
        print()
        print(f"Expires: {time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime(expiration))}")
        print()
        print("📝 Add these to your .env file:")
        print("-" * 80)
        print(f"OAUTH_APPLE_CLIENT_ID={client_id}")
        print(f"OAUTH_APPLE_CLIENT_SECRET={client_secret}")
        print("-" * 80)
        print()
        print("⚠️  IMPORTANT REMINDERS:")
        print("  ✓ This secret expires in {args.validity_months} months - set a calendar reminder!")
        print(f"    Reminder date: {time.strftime('%Y-%m-%d', time.gmtime(expiration - 7*24*60*60))}")
        print("  ✓ Store this secret securely (environment variables or secrets manager)")
        print("  ✓ Never commit this to version control!")
        print("  ✓ Restart your backend after updating .env file")
        print()
        print("🔐 Security Best Practices:")
        print("  • Add *.p8 to .gitignore")
        print("  • Add .env to .gitignore")
        print("  • Use Docker secrets in production")
        print("  • Rotate keys annually")
        print()
        print("🧪 Test your configuration:")
        print("  curl http://localhost:8000/auth/oauth/providers")
        print("  # Should include 'apple' in the list")
        print()
        print("=" * 80)

    except FileNotFoundError as e:
        print(f"\n❌ Error: {e}")
        print("Make sure the .p8 file path is correct and the file exists.")
        sys.exit(1)
    except ValueError as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        print("Please check your inputs and try again.")
        sys.exit(1)


if __name__ == "__main__":
    main()
