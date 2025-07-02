#!/usr/bin/env bash

source secrets.sh

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)


cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    ORANGE='\033[0;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    YELLOW='\033[1;33m'
  else
    NOFORMAT=''
    RED=''
    GREEN=''
    ORANGE=''
    BLUE=''
    PURPLE=''
    CYAN=''
    YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1}
  msg "$msg"
  exit "$code"
}

setup_colors

set -x 
expected_gateway_ip="$HANGAR85_GATEWAY_IP"

# What's the default gateway?
default_gateway=$(ip route | grep default | awk '{print $3}')
if [ "$default_gateway" != "$expected_gateway_ip" ]; then
  die "Default gateway is $default_gateway, expected $expected_gateway_ip"
fi

gateway_ip="$default_gateway"

# Is port 8443 reachable?
if ! nc -z -w 1 $gateway_ip 8443; then
  die "Port 8443 is not reachable"
fi

valid_ssl=false

ssl_args=""
if ! $valid_ssl; then
  ssl_args="$ssl_args -k"
fi

# curl $ssl_args https://$gateway_ip:443/login | less

  # -H 'accept-language: en-US,en;q=0.9' \
  # -H 'priority: u=1, i' \
  # -H 'sec-ch-ua: "Chromium";v="136", "Google Chrome";v="136", "Not.A/Brand";v="99"' \
  # -H 'sec-ch-ua-mobile: ?0' \
  # -H 'sec-ch-ua-platform: "Linux"' \
  # -H 'sec-fetch-dest: empty' \
  # -H 'sec-fetch-mode: cors' \
  # -H 'sec-fetch-site: same-origin' \
  # -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36' \
curl $ssl_args "https://$gateway_ip/api/auth/login" \
  --data-raw "{\"username\":\"$UNIFI_USER\",\"password\":\"$UNIFI_PASS\",\"token\":\"\",\"rememberMe\":false}" \
  -H 'accept: */*' \
  -H 'content-type: application/json' \
  -H "origin: https://$gateway_ip" \
  | jq . | less
  