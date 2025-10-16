#!/usr/bin/env python3
"""
Generate Apple OAuth Client Secret JWT

Apple requires a JWT signed with your private key (.p8 file) as the client secret.
This JWT must be regenerated every 6 months.

Apple Documentation:
https://developer.apple.com/documentation/sign_in_with_apple/generate_and_validate_tokens

Requirements:
    pip install pyjwt cryptography

Usage:
    python scripts/generate_apple_client_secret.py \
        --team-id YOUR_TEAM_ID \
        --key-id YOUR_KEY_ID \
        --client-id com.csfrace.webservice \
        --key-file path/to/AuthKey_ABC123.p8
"""

import argparse
import datetime
from pathlib import Path

import jwt


def generate_apple_client_secret(
    team_id: str,
    key_id: str,
    client_id: str,
    key_file_path: str,
    expiration_months: int = 6,
) -> str:
    """
    Generate Apple OAuth client secret JWT.

    Args:
        team_id: Your Apple Developer Team ID (10 characters, e.g., "XYZ987WXYZ")
        key_id: Your Sign in with Apple Key ID (10 characters, e.g., "ABC123DEFG")
        client_id: Your Service ID / Client ID (e.g., "com.csfrace.webservice")
        key_file_path: Path to your .p8 private key file
        expiration_months: How long the JWT should be valid (max 6 months per Apple)

    Returns:
        JWT string to use as OAUTH_APPLE_CLIENT_SECRET

    Raises:
        FileNotFoundError: If key file doesn't exist
        ValueError: If expiration exceeds 6 months
    """
    # Validate expiration (Apple allows max 6 months)
    if expiration_months > 6:
        raise ValueError("Apple allows maximum 6 months expiration for client secret")

    # Read the private key
    key_path = Path(key_file_path)
    if not key_path.exists():
        raise FileNotFoundError(f"Private key file not found: {key_file_path}")

    with open(key_path, "r", encoding="utf-8") as f:
        private_key = f.read()

    # Calculate timestamps
    now = datetime.datetime.now(datetime.UTC)
    expiration = now + datetime.timedelta(days=30 * expiration_months)

    # JWT headers (Apple requires ES256 algorithm)
    headers = {"kid": key_id, "alg": "ES256"}

    # JWT claims
    claims = {
        "iss": team_id,  # Issuer: Your Team ID
        "iat": int(now.timestamp()),  # Issued at
        "exp": int(expiration.timestamp()),  # Expiration (max 6 months)
        "aud": "https://appleid.apple.com",  # Audience: Apple's auth server
        "sub": client_id,  # Subject: Your Service ID (Client ID)
    }

    # Generate the JWT
    client_secret = jwt.encode(claims, private_key, algorithm="ES256", headers=headers)

    return client_secret


def main():
    parser = argparse.ArgumentParser(
        description="Generate Apple OAuth Client Secret JWT",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate with 6 months expiration (maximum)
  python scripts/generate_apple_client_secret.py \\
      --team-id XYZ987WXYZ \\
      --key-id ABC123DEFG \\
      --client-id com.csfrace.webservice \\
      --key-file ~/Downloads/AuthKey_ABC123.p8

  # Generate with 3 months expiration
  python scripts/generate_apple_client_secret.py \\
      --team-id XYZ987WXYZ \\
      --key-id ABC123DEFG \\
      --client-id com.csfrace.webservice \\
      --key-file ~/Downloads/AuthKey_ABC123.p8 \\
      --expiration-months 3

Where to find these values:
  Team ID:    https://developer.apple.com/account (top right corner)
  Key ID:     https://developer.apple.com/account/resources/authkeys/list
  Client ID:  https://developer.apple.com/account/resources/identifiers/list/serviceId
  Key File:   Downloaded when you created the key (AuthKey_XXXXXXXXXX.p8)
        """,
    )

    parser.add_argument(
        "--team-id",
        required=True,
        help="Your Apple Developer Team ID (10 characters)",
    )

    parser.add_argument(
        "--key-id",
        required=True,
        help="Your Sign in with Apple Key ID (10 characters)",
    )

    parser.add_argument(
        "--client-id",
        required=True,
        help="Your Service ID / Client ID (e.g., com.csfrace.webservice)",
    )

    parser.add_argument(
        "--key-file",
        required=True,
        help="Path to your .p8 private key file",
    )

    parser.add_argument(
        "--expiration-months",
        type=int,
        default=6,
        choices=range(1, 7),
        help="JWT expiration in months (1-6, default: 6)",
    )

    args = parser.parse_args()

    try:
        client_secret = generate_apple_client_secret(
            team_id=args.team_id,
            key_id=args.key_id,
            client_id=args.client_id,
            key_file_path=args.key_file,
            expiration_months=args.expiration_months,
        )

        print("\n" + "=" * 80)
        print("✅ Apple OAuth Client Secret Generated Successfully!")
        print("=" * 80)
        print("\nAdd this to your .env file:\n")
        print(f"OAUTH_APPLE_CLIENT_ID={args.client_id}")
        print(f"OAUTH_APPLE_CLIENT_SECRET={client_secret}")
        print("\n" + "=" * 80)
        print(f"⏰ This JWT expires in {args.expiration_months} months")
        print("   You'll need to regenerate it before expiration.")
        print("=" * 80 + "\n")

        # Calculate expiration date
        expiration = datetime.datetime.now(datetime.UTC) + datetime.timedelta(
            days=30 * args.expiration_months
        )
        print(f"📅 Expiration Date: {expiration.strftime('%Y-%m-%d %H:%M:%S UTC')}\n")

    except FileNotFoundError as e:
        print(f"\n❌ Error: {e}")
        print("   Make sure the .p8 key file path is correct.\n")
        return 1

    except ValueError as e:
        print(f"\n❌ Error: {e}\n")
        return 1

    except Exception as e:
        print(f"\n❌ Unexpected error: {e}\n")
        import traceback

        traceback.print_exc()
        return 1

    return 0


if __name__ == "__main__":
    exit(main())
