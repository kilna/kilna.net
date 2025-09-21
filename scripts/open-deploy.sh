#!/usr/bin/env bash

# Wait for git push to complete, then get deployment URL and open it
# Usage: git push | ./scripts/open-deploy.sh

set -euo pipefail

# Check required environment variable
if [ -z "${CLOUDFLARE_PAGES_PROJECT:-}" ]; then
  echo "Error: CLOUDFLARE_PAGES_PROJECT environment variable not set" >&2
  exit 1
fi

# Read and echo git push output
while IFS= read -r line; do
  echo "$line"
done

# Get the current git commit hash
COMMIT_HASH=$(git rev-parse HEAD)
echo "Looking for deployment with commit: ${COMMIT_HASH:0:7}"

echo -n "Getting deployment URL."
TIMEOUT=60
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  # Look for deployment with matching commit hash
  URL=$(
    wrangler pages deployment list --project-name="$CLOUDFLARE_PAGES_PROJECT" 2>/dev/null \
      | grep "$COMMIT_HASH" \
      | grep -o 'https://[a-f0-9]\{8\}\.[^[:space:]]*\.pages\.dev' \
      | head -1 \
      || echo ""
  )
  [ -n "$URL" ] && break
  echo -n "."
  sleep 1
  ELAPSED=$((ELAPSED + 1))
done
if [ -z "$URL" ]; then
  echo "Error: Deployment URL not found within $TIMEOUT seconds" >&2
  exit 1
fi

echo
echo -n "Waiting for deployment to be ready."
TIMEOUT=60
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  if curl -s "$URL" | grep -qv "Nothing is here yet"; then
    exec open "$URL"
  fi
  echo -n "."
  sleep 1
  ELAPSED=$((ELAPSED + 1))
done

echo
echo "Error: Deployment URL not ready within $TIMEOUT seconds" >&2
exit 1
