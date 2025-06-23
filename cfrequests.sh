#!/bin/bash

source ../secrets.sh
	     
#curl "https://api.cloudflare.com/client/v4/user/tokens/verify" \
#  -H "Authorization: Bearer $CF_API_TOKEN" | jq

#curl "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
#   -H "Authorization: Bearer $CF_API_TOKEN" | jq

curl "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORD_NAME" \
   -H "Authorization: Bearer $CF_API_TOKEN" | jq -r '.result[0]'
RECORD_DATA=$(curl -s "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORD_NAME" \
   -H "Authorization: Bearer $CF_API_TOKEN" | jq -r '.result[0]')

RECORD_ID=$(echo "$RECORD_DATA" | jq -r '.id')
CURRENT_IP=$(echo "$RECORD_DATA" | jq -r '.content')

NEW_IP="2.2.2.2"

echo "Updating $RECORD_NAME from $CURRENT_IP to $NEW_IP"

curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
   -H "Authorization: Bearer $CF_API_TOKEN" \
   -H "Content-Type: application/json" \
   --data "{\"type\":\"A\",\"name\":\"$RECORD_NAME\",\"content\":\"$NEW_IP\",\"ttl\":1}" | jq

echo "DNS record updated successfully"