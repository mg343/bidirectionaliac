#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

# Load Cloudflare credentials
source secrets.sh

# Handle restore mode
if [[ "${1:-}" == "-r" && -n "${2:-}" ]]; then
  RESTORE_COMMIT_MSG="$2"

  # Basic format check: HH:MM MM/DD/YYYY
  if [[ ! "$RESTORE_COMMIT_MSG" =~ ^[0-9]{2}:[0-9]{2}\ [0-9]{2}/[0-9]{2}/[0-9]{4}$ ]]; then
    echo "[WARN] Improper -r formatting (HH:MM MM/DD/YYYY), running main.sh normally."
  else
    echo "[INFO] Attempting to restore snapshot from commit: '$RESTORE_COMMIT_MSG'"
    git switch observed-reality
    git pull

    COMMIT_HASH=$(git log --pretty=format:"%H %s" | awk -v msg="$RESTORE_COMMIT_MSG" '
      substr($0, 42, 16) == msg { print $1; exit }
    ')

    if [[ -z "$COMMIT_HASH" ]]; then
      echo "[ERROR] No commit found with commit header: '$RESTORE_COMMIT_MSG'"
      exit 1
    fi

    echo "[INFO] Found commit: $COMMIT_HASH. Restoring file..."
    git show "$COMMIT_HASH:data/dns_records.json" > data/dns_records.json

    git add data/dns_records.json
    git commit -m "$(date +"%H:%M %m/%d/%Y"): Restoring $RESTORE_COMMIT_MSG"
    echo "[INFO] File restored and committed."
    exit 0
  fi
fi


# Switch to target branch
echo "[INFO] Switching to observed-reality branch..."
git switch observed-reality
git pull

# File paths
SAVED_FILE="data/dns_records.json"
TMP_FILE=$(mktemp)

# Validate token (fail early if invalid)
echo "[INFO] Validating API token..."
http_code=$(curl -s -o /dev/null -w "%{http_code}" \
  "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CF_API_TOKEN")

if [[ "$http_code" -ne 200 ]]; then
  echo "[INFO] API token invalid, exiting."
  exit 1
fi

# Fetch latest DNS records
echo "[INFO] Fetching current DNS records..."
mkdir -p data
curl -s "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  | jq '.' > "$TMP_FILE"

# First-time save if file doesn't exist
if [[ ! -f "$SAVED_FILE" ]]; then
  echo "[INFO] Initial snapshot, committing and exiting."
  mv "$TMP_FILE" "$SAVED_FILE"
  git add "$SAVED_FILE"
  git commit -m "$(date +"%H:%M %m/%d/%Y"): Initial snapshot"
  exit 0
fi

# Compare current with new, and update if changed
if ! diff -q "$SAVED_FILE" "$TMP_FILE" >/dev/null; then
  echo "[INFO] Change detected, committing and exiting."
  mv "$TMP_FILE" "$SAVED_FILE"
  git add "$SAVED_FILE"
  git commit -m "$(date +"%H:%M %m/%d/%Y"): Changes synced"
  rm -f "$TMP_FILE"
  exit 0
fi

echo "[INFO] No changes made, exiting."
exit 0