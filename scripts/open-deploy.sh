#!/usr/bin/env bash

# Get deployment URL and open it after git push
# Usage: ./scripts/open-deploy.sh

set -euo pipefail

# Get the current git commit hash
COMMIT_HASH=$(git rev-parse HEAD)
echo "Looking for deployment with commit: ${COMMIT_HASH:0:7}"

# Get project name from wrangler.toml (first occurrence only)
PROJECT_NAME=$(grep '^name = ' "$(dirname "$0")/../wrangler.toml" | head -1 | sed 's/name = "\(.*\)"/\1/')
echo "Debug: Using project name: $PROJECT_NAME"

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
    wrangler pages deployment list --project-name="$PROJECT_NAME" 2>&1 | head -10
  fi

  # Look for deployment with matching commit hash
  URL=$(
    wrangler pages deployment list --project-name="$PROJECT_NAME" 2>/dev/null \
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
      wrangler pages deployment list --project-name="$PROJECT_NAME" 2>/dev/null \
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
