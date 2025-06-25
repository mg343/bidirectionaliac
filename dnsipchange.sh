#!/bin/bash

source ../secrets.sh
	     
#curl "https://api.cloudflare.com/client/v4/user/tokens/verify" \
#  -H "Authorization: Bearer $CF_API_TOKEN" | jq

#curl "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
#   -H "Authorization: Bearer $CF_API_TOKEN" | jq

#curl "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORD_NAME" \
#   -H "Authorization: Bearer $CF_API_TOKEN" | jq -r '.result[0]'
RECORD_DATA=$(curl -s "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORD_NAME" \
   -H "Authorization: Bearer $CF_API_TOKEN" | jq -r '.result[0]')

CURRENT_IP=$(echo "$RECORD_DATA" | jq -r '.content')
RECORD_ID=$(echo "$RECORD_DATA" | jq -r '.id')
NEW_IP="3.3.3.3"

curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
   -H "Authorization: Bearer $CF_API_TOKEN" \
   -H "Content-Type: application/json" \
   --data "{\"type\":\"A\",\"name\":\"$RECORD_NAME\",\"content\":\"$NEW_IP\",\"ttl\":1}" | jq > /dev/null

RECORD_DATA=$(curl -s "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORD_NAME" \
   -H "Authorization: Bearer $CF_API_TOKEN" | jq -r '.result[0]')

echo "$RECORD_DATA" | jq -r \
  --arg old_ip "$CURRENT_IP" \
  '"Record Name: \(.name)\nOld IP: \($old_ip)\nNew IP: \(.content)"'