#!/usr/bin/env bash

# Wait for git push to complete, then get deployment URL and open it
# Usage: git push | ./scripts/open-deployment.sh
# Project name comes from CLOUDFLARE_PAGES_PROJECT environment variable

set -euo pipefail

# Unset API token to ensure we use OAuth authentication
unset CLOUDFLARE_API_TOKEN

# Initialize TAIL_PID variable
TAIL_PID=""

# Check that required environment variables are set
if [ -z "${CLOUDFLARE_PAGES_PROJECT:-}" ]; then
  echo "Error: CLOUDFLARE_PAGES_PROJECT environment variable not set"
  echo "Make sure your .envrc file exports CLOUDFLARE_PAGES_PROJECT"
  exit 1
fi


# Read all git push output and echo it
while IFS= read -r line; do
  echo "$line"
done

# After git push completes, get the deployment URL
echo "Waiting for Cloudflare Pages deployment..."
echo "Debug: Starting deployment URL detection..."
echo -n "Getting deployment URL."

# Try to get the deployment URL with a timeout
TIMEOUT=60  # 60 seconds timeout
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
  # Try to get the deployment URL using wrangler
  DEPLOYMENT_OUTPUT=$(wrangler pages deployment list --project-name="$CLOUDFLARE_PAGES_PROJECT" 2>/dev/null || echo "")
  URL=$(echo "$DEPLOYMENT_OUTPUT" | grep -o 'https://[a-f0-9]\{8\}\.[^[:space:]]*\.pages\.dev' | head -1 || echo "")
  
  # If wrangler fails, try a fallback approach
  if [ -z "$URL" ]; then
    # Try to construct URL from the most recent commit hash
    COMMIT_HASH=$(git rev-parse --short HEAD)
    if [ -n "$COMMIT_HASH" ]; then
      # Generate a potential URL (this is a guess, but might work)
      URL="https://${COMMIT_HASH}.${CLOUDFLARE_PAGES_PROJECT}.pages.dev"
      # Test if this URL is accessible
      if ! curl -s --head "$URL" | grep -q "200 OK"; then
        URL=""
      fi
    fi
  fi
  
  if [ -n "$URL" ]; then
    echo
    echo "Deployment URL: $URL"
    
    # Get deployment ID and start log tailing (required)
    echo "Getting deployment details from wrangler..."
    URL_HASH=$(echo "$URL" | grep -o '[a-f0-9]\{8\}' | head -1)
    
    if [ -z "$URL_HASH" ]; then
      echo "Error: Could not extract URL hash from deployment URL: $URL" >&2
      exit 1
    fi
    
    # Get deployment ID from wrangler output
    # Wrangler outputs a table format, we need to extract the ID from the first column
    # Skip the header lines and find the row with our URL hash
    DEPLOYMENT_ID=$(wrangler pages deployment list --project-name="$CLOUDFLARE_PAGES_PROJECT" 2>/dev/null | \
      grep -A 1000 "│ Id" | \
      grep "$URL_HASH" | \
      head -1 | \
      sed 's/│/ /g' | \
      awk '{print $1}' | \
      sed 's/[[:space:]]*//g' || echo "")
    
    echo "Debug: URL hash: '$URL_HASH', Deployment ID: '$DEPLOYMENT_ID'"
    
    if [ -z "$DEPLOYMENT_ID" ]; then
      echo "Error: Could not find deployment ID for URL hash $URL_HASH" >&2
      echo "Available deployments:" >&2
      wrangler pages deployment list --project-name="$CLOUDFLARE_PAGES_PROJECT" >&2
      exit 1
    fi
    
    echo "Tailing build logs for deployment $DEPLOYMENT_ID..."
    
    # Start tailing the deployment logs in the background
    wrangler pages deployment tail --project-name="$CLOUDFLARE_PAGES_PROJECT" "$DEPLOYMENT_ID" &
    TAIL_PID=$!
    
    # Wait for deployment to be ready
    echo -n "Waiting for deployment to be ready."
    while curl -s "$URL" | grep -q "Nothing is here yet"; do
      echo -n "."
      sleep 1
    done
    
    # Stop tailing once deployment is ready
    if [ -n "${TAIL_PID:-}" ] && [ "$TAIL_PID" != "" ]; then
      kill $TAIL_PID 2>/dev/null || true
      wait $TAIL_PID 2>/dev/null || true
    fi
    
    echo
    echo "Deployment ready! Opening $URL"
    open "$URL"
    exit 0
  fi
  
  echo -n "."
  sleep 3
  ELAPSED=$((ELAPSED + 3))
done

