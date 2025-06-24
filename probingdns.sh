#!/bin/bash

source ../secrets.sh

RECORD_NAME="mihir.$ROOT_NAME"
RECORD_TYPE="A"
RECORD_IP="7.7.7.7"
TTL=1
PROXIED=false

curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "'"$RECORD_TYPE"'",
    "name": "'"$RECORD_NAME"'",
    "content": "'"$RECORD_IP"'",
    "ttl": '"$TTL"',
    "proxied": '"$PROXIED"'
  }' | jq