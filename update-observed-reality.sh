#!/bin/bash

set -euo pipefail

source secrets.sh

mkdir -p data
SAVED_FILE="data/dns_records.json"
TMP_FILE=$(mktemp)

# Validate API token
echo "Validating API token..."
VERIFY_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CF_API_TOKEN")

if [ "$VERIFY_RESPONSE" -ne 200 ]; then
  echo "Error: Invalid API token or verification failed."
  exit 1
fi

echo "Fetching current DNS records..."
curl -s "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  | jq '.' > "$TMP_FILE"  # Always pretty print

# If no previous file, save and exit
if [ ! -f "$SAVED_FILE" ]; then
  mv "$TMP_FILE" "$SAVED_FILE"
  echo "Initial DNS snapshot saved to $SAVED_FILE"
fi

# Use git diff to compare
echo "Comparing with previous snapshot..."
diff_output=$(git diff --no-index --color "$SAVED_FILE" "$TMP_FILE" || true)

if [ -z "$diff_output" ]; then
  echo "No DNS changes detected."
  rm "$TMP_FILE"
else
  echo "DNS changes detected:"
  echo "$diff_output"

  read -rp "Save new snapshot? [y/N]: " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    mv "$TMP_FILE" "$SAVED_FILE"
    echo "Snapshot updated."
  else
    rm "$TMP_FILE"
    echo "Update canceled."
  fi
fi