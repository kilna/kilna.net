#!/usr/bin/env bash

# Wait for git push to complete, then get deployment URL and open it
# Usage: git push | ./scripts/open-deployment.sh <project-name>

set -euo pipefail

PROJECT_NAME="${1:-}"

if [ -z "$PROJECT_NAME" ]; then
  echo "Usage: git push | $0 <project-name>"
  exit 1
fi

# Read all git push output and echo it
while IFS= read -r line; do
  echo "$line"
done

# After git push completes, get the deployment URL
echo "Waiting for Cloudflare Pages deployment..."
echo -n "Getting deployment URL."

while true; do
  # Get the first deployment URL from the list (most recent)
  # Look for URLs that end with .pages.dev to avoid partial matches
  URL=$(wrangler pages deployment list --project-name="$PROJECT_NAME" 2>/dev/null | grep -o 'https://[^[:space:]]*\.pages\.dev' | head -1 || echo "")
  if [ -z "$URL" ]; then
    echo -n "."
    sleep 3
  else
    echo
    echo "Deployment URL: $URL"
    echo -n "Waiting for deployment to be ready."
    while curl -s "$URL" | grep -q "Nothing is here yet"; do
      echo -n "."
      sleep 1
    done
    echo
    echo "Deployment ready! Opening $URL"
    open "$URL"
    break
  fi
done
