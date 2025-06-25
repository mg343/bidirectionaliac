#!/bin/bash

source secrets.sh

TMP_FILE=$(mktemp)

#verify token works
VERIFY_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CF_API_TOKEN")

if [ "$VERIFY_RESPONSE" -ne 200 ]; then
  echo "Error: Invalid API token or verification failed."
  exit 1
fi

#grab active dns records
curl -s "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -o "$TMP_FILE"

#check for exisitng config
SAVED_FILE="../dns_records.json"
if [ ! -f "$SAVED_FILE" ]; then
  mv "$TMP_FILE" "$SAVED_FILE"
  echo "No previous file found. DNS records saved to dns_records.json"
  exit 0
fi

#compare active and existing
declare -A old_records
declare -A new_records

while IFS= read -r line; do
  key=$(echo "$line" | jq -r '.name')
  old_records["$key"]="$line"
done < <(jq -c '.result[] | {name, content, type, ttl, proxied}' "$SAVED_FILE")

while IFS= read -r line; do
  key=$(echo "$line" | jq -r '.name')
  new_records["$key"]="$line"
done < <(jq -c '.result[] | {name, content, type, ttl, proxied}' "$TMP_FILE")

#output formatting
changes=0
PAD_WIDTH=60

#if records exist in both
for name in "${!old_records[@]}"; do
  if [[ -v new_records["$name"] ]]; then
    if [[ "${old_records[$name]}" == "${new_records[$name]}" ]]; then
      printf "%-${PAD_WIDTH}s%s\n" "$name" "--"
    else
      printf "%-${PAD_WIDTH}s%s\n" "$name" "!!"
      for field in content type ttl proxied; do
        old_value=$(echo "${old_records[$name]}" | jq -r ".${field}")
        new_value=$(echo "${new_records[$name]}" | jq -r ".${field}")
        if [[ "$old_value" != "$new_value" ]]; then
          printf "\t%-12s: %s -> %s\n" "$field" "$old_value" "$new_value"
        fi
      done
      changes=1
    fi
  else
    #if records were removed
    printf "%-${PAD_WIDTH}s%s\n" "$name" "XX"
    changes=1
  fi
done

#if records were added
for name in "${!new_records[@]}"; do
  if [[ ! -v old_records["$name"] ]]; then
    printf "%-${PAD_WIDTH}s%s\n" "$name" "++"
    changes=1
  fi
done

echo ""

#save or cancel
if [[ $changes -eq 0 ]]; then
  echo "No Changes Made"
  rm "$TMP_FILE"
else
  echo "Changes detected. Overwrite existing dns_records.json? [y/N]"
  read -r answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    mv "$TMP_FILE" "$SAVED_FILE"
    echo "DNS records updated and saved to dns_records.json"
  else
    rm "$TMP_FILE"
    echo "Cancelled. Existing dns_records.json kept unchanged."
  fi
fi