#!/bin/bash

source ../cloudflare-token-secret.sh

curl "https://api.cloudflare.com/client/v4/user/tokens/verify" \
	     -H "Authorization: Bearer $CF_API_TOKEN"
