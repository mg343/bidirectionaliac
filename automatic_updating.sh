#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

echo "[INFO] Switching to observed-reality branch..."
git switch observed-reality

git pull

echo "[INFO] Running update-observed-reality.sh..."
yes y | ./update-observed-reality.sh

echo "[INFO] Checking for differences..."
if git diff --quiet; then
    exit 0
else
    echo "[INFO] Changes detected. Committing..."
    git add data/dns_records.json

    TIMESTAMP=$(date +"%H:%M %d/%m/%Y")
    git commit -m "$TIMESTAMP"
    echo "[INFO] Commit completed: $TIMESTAMP"
fi