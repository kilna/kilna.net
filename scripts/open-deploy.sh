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

# Try to get the deployment URL with a timeout
TIMEOUT=60  # 60 seconds timeout
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
  # Get the first deployment URL from the list (most recent)
  # Look for URLs that end with .pages.dev to avoid partial matches
  # Get the deployment list and extract URLs, handling table formatting
  # Use a more flexible approach to find URLs that might be split across lines
  DEPLOYMENT_OUTPUT=$(wrangler pages deployment list --project-name="$PROJECT_NAME" 2>/dev/null)
  URL=$(echo "$DEPLOYMENT_OUTPUT" | grep -o 'https://[a-f0-9]\{8\}\.[^[:space:]]*\.pages\.dev' | head -1 || echo "")
  
  # If that doesn't work, try to reconstruct URLs from the table
  if [ -z "$URL" ]; then
    # Look for the hash part and project name separately
    HASH=$(echo "$DEPLOYMENT_OUTPUT" | grep -o 'https://[a-f0-9]\{8\}\.' | head -1 | sed 's|https://||' | sed 's|\.$||')
    if [ -n "$HASH" ]; then
      URL="https://${HASH}.${PROJECT_NAME}.pages.dev"
    fi
  fi
  
  if [ -n "$URL" ]; then
    echo
    echo "Deployment URL: $URL"
    
    # Get the deployment ID for tailing
    DEPLOYMENT_ID=$(echo "$DEPLOYMENT_OUTPUT" | grep -A 10 -B 10 "$URL" | grep -o '[a-f0-9]\{8\}' | head -1 || echo "")
    
    if [ -n "$DEPLOYMENT_ID" ]; then
      echo "Tailing build logs for deployment $DEPLOYMENT_ID..."
      
      # Start tailing the deployment logs in the background
      wrangler pages deployment tail --project-name="$PROJECT_NAME" --deployment-id="$DEPLOYMENT_ID" &
      TAIL_PID=$!
    else
      echo "Could not get deployment ID for tailing, proceeding without logs..."
    fi
    
    # Wait for deployment to be ready
    echo -n "Waiting for deployment to be ready."
    while curl -s "$URL" | grep -q "Nothing is here yet"; do
      echo -n "."
      sleep 1
    done
    
    # Stop tailing once deployment is ready
    if [ -n "$DEPLOYMENT_ID" ] && [ -n "$TAIL_PID" ]; then
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

echo
echo "Timeout reached. Deployment may still be processing."
echo "Check the Cloudflare Pages dashboard:"
echo "https://dash.cloudflare.com/046e8f301fab8b218d3f51110cc7034f/pages/view/$PROJECT_NAME"
