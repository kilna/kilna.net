#!/usr/bin/env bash

# Wait for git push to complete, then get deployment URL and open it
# Usage: git push | ./scripts/open-deploy.sh

set -euo pipefail

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
  # Debug: show what we're looking for
  if [ $ELAPSED -eq 0 ]; then
    echo
    echo "Debug: Looking for commit hash: $COMMIT_HASH"
    echo "Debug: Testing wrangler authentication..."
    wrangler whoami
    echo "Debug: Wrangler deployment list output:"
    (cd "$(dirname "$0")/.." && wrangler pages deployment list) 2>&1 | head -10
  fi
  
  # Look for deployment with matching commit hash
  # Ensure we're in the project directory where wrangler.toml exists
  URL=$(
    (cd "$(dirname "$0")/.." && wrangler pages deployment list) 2>/dev/null \
      | grep "$COMMIT_HASH" \
      | grep -o 'https://[a-f0-9]\{8\}\.[^[:space:]]*\.pages\.dev' \
      | head -1 \
      || echo ""
  )
  
  # If we can't find the specific commit, try the most recent deployment
  if [ -z "$URL" ] && [ $ELAPSED -gt 10 ]; then
    echo
    echo "Could not find deployment for commit $COMMIT_HASH, trying most recent..."
    URL=$(
      (cd "$(dirname "$0")/.." && wrangler pages deployment list) 2>/dev/null \
        | grep -o 'https://[a-f0-9]\{8\}\.[^[:space:]]*\.pages\.dev' \
        | head -1 \
        || echo ""
    )
  fi
  
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
