#!/bin/bash

source secrets.sh

SITE_ID=$(curl -k -X GET "https://$CONTROLLER_IP/proxy/network/integration/v1/sites" -H "X-API-KEY: $UN_API_KEY" -H 'Accept: application/json' | jq -r '.data[0].id')

# curl -k -X GET "https://$CONTROLLER_IP/proxy/network/integration/v1/sites/$SITE_ID/clients?limit=100" \
#   -H "X-API-KEY: $UN_API_KEY" -H 'Accept: application/json' | jq '.data[] | select(.name | test("simchair"))'


# curl -k -X GET "https://$CONTROLLER_IP/proxy/network/integration/v1/sites" \
#   -H "X-API-KEY: $UN_API_KEY" -H 'Accept: application/json' 2>/dev/null | jq

curl -k -X GET "https://$unifi.ui.com/api" \
  -I -H "X-API-KEY: $UN_API_KEY" -H 'Accept: application/json' 2>/dev/null