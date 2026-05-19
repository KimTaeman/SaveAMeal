#!/usr/bin/env bash
# Scan a file for common secret patterns. Accepts a file path as $1.
# Exits 1 if any pattern matches, 0 if clean. Used by CI and hooks.
set -euo pipefail

FILE="${1:-}"
[ -z "$FILE" ] && { echo "Usage: scan_secrets.sh <file>" >&2; exit 1; }
[ ! -f "$FILE" ] && exit 0

PATTERNS=(
  'AIza[0-9A-Za-z_-]{35}'               # Google / Firebase API key
  'ya29\.[0-9A-Za-z_-]+'                # Google OAuth token
  'sk_live_[0-9a-zA-Z]{24}'             # Stripe live secret key
  'BEGIN (RSA |EC )?PRIVATE KEY'         # PEM private key header
  'aws_access_key_id\s*[=:]\s*[A-Z0-9]{20}'
  'aws_secret_access_key\s*[=:]\s*[A-Za-z0-9/+]{40}'
)

FOUND=0
for pattern in "${PATTERNS[@]}"; do
  if grep -qEi "$pattern" "$FILE" 2>/dev/null; then
    echo "SECRET SCAN: pattern '$pattern' matched in $FILE" >&2
    FOUND=1
  fi
done

exit $FOUND
