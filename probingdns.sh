#!/bin/bash

source secrets.sh

RECORD_NAME="mihir2.$ROOT_NAME"
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


echo "Waiting for DNS propagation..."
sleep 3

RESOLVED_IP=$(dig +short "$RECORD_NAME")


#deleting
if [[ "$RESOLVED_IP" == "$RECORD_IP" ]]; then
  echo "Record resolved correctly: $RESOLVED_IP, deleting..."

  RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=$RECORD_TYPE&name=$RECORD_NAME" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

  if [[ -n "$RECORD_ID" && "$RECORD_ID" != "null" ]]; then
    DELETE_RESPONSE=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json")

    echo "$DELETE_RESPONSE" | jq
    echo "Record deleted."
  else
    echo "Failed to retrieve record ID."
  fi
else
  echo "DNS record did not resolve as expected (got '$RESOLVED_IP'). Skipping delete."
fi