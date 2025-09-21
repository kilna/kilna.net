#!/usr/bin/env bash

# Wait for git push to complete, then get deployment URL and open it
# Usage: git push | ./scripts/open-deployment.sh
# Project name comes from CLOUDFLARE_PAGES_PROJECT environment variable

set -euo pipefail

# Check that required environment variables are set
if [ -z "${CLOUDFLARE_PAGES_PROJECT:-}" ]; then
  echo "Error: CLOUDFLARE_PAGES_PROJECT environment variable not set"
  echo "Make sure your .envrc file exports CLOUDFLARE_PAGES_PROJECT"
  exit 1
fi

# Function to get Cloudflare account ID using wrangler
get_cloudflare_account_id() {
  # Use wrangler whoami to get account information
  local whoami_output
  whoami_output=$(wrangler whoami 2>/dev/null || echo "")
  
  if [ -z "$whoami_output" ]; then
    echo "Error: Failed to get account information from wrangler" >&2
    echo "Make sure you're logged in with 'wrangler login'" >&2
    return 1
  fi
  
  # Extract account ID from wrangler output
  local account_id
  account_id=$(echo "$whoami_output" | grep -o '[a-f0-9]\{32\}' | head -1 || echo "")
  
  if [ -z "$account_id" ]; then
    echo "Error: Could not extract account ID from wrangler output" >&2
    echo "Wrangler output: $whoami_output" >&2
    return 1
  fi
  
  echo "$account_id"
}

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
  DEPLOYMENT_OUTPUT=$(wrangler pages deployment list --project-name="$CLOUDFLARE_PAGES_PROJECT" 2>/dev/null)
  URL=$(echo "$DEPLOYMENT_OUTPUT" | grep -o 'https://[a-f0-9]\{8\}\.[^[:space:]]*\.pages\.dev' | head -1 || echo "")
  
  # If that doesn't work, try to reconstruct URLs from the table
  if [ -z "$URL" ]; then
    # Look for the hash part and project name separately
    HASH=$(echo "$DEPLOYMENT_OUTPUT" | grep -o 'https://[a-f0-9]\{8\}\.' | head -1 | sed 's|https://||' | sed 's|\.$||')
    if [ -n "$HASH" ]; then
      URL="https://${HASH}.${CLOUDFLARE_PAGES_PROJECT}.pages.dev"
    fi
  fi
  
  if [ -n "$URL" ]; then
    echo
    echo "Deployment URL: $URL"
    
    # Get deployment ID using Cloudflare API
    echo "Getting deployment ID from Cloudflare API..."
    URL_HASH=$(echo "$URL" | grep -o '[a-f0-9]\{8\}' | head -1)
    
    if [ -n "$URL_HASH" ]; then
      # Get account ID dynamically from API token
      echo "Fetching account ID from API token..."
      CLOUDFLARE_ACCOUNT_ID=$(get_cloudflare_account_id)
      
      if [ -n "$CLOUDFLARE_ACCOUNT_ID" ]; then
        # Use Cloudflare API to get deployment details
        DEPLOYMENT_RESPONSE=$(curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
          "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/pages/projects/$CLOUDFLARE_PAGES_PROJECT/deployments" 2>/dev/null || echo "")
      
        if [ -n "$DEPLOYMENT_RESPONSE" ]; then
          # Extract deployment ID for the matching URL hash
          DEPLOYMENT_ID=$(echo "$DEPLOYMENT_RESPONSE" | grep -o "\"id\":\"[^\"]*$URL_HASH[^\"]*\"" | head -1 | sed 's/"id":"\([^"]*\)"/\1/')
          
          if [ -n "$DEPLOYMENT_ID" ]; then
            echo "Tailing build logs for deployment $DEPLOYMENT_ID..."
            
            # Start tailing the deployment logs in the background
            wrangler pages deployment tail --project-name="$CLOUDFLARE_PAGES_PROJECT" --deployment-id="$DEPLOYMENT_ID" &
            TAIL_PID=$!
          else
            echo "Could not find deployment ID for URL hash $URL_HASH"
          fi
        else
          echo "Could not fetch deployment data from API (check CLOUDFLARE_API_TOKEN)"
        fi
      else
        echo "Failed to get account ID from wrangler"
      fi
    else
      echo "Missing URL hash"
    fi
    
    # Wait for deployment to be ready
    echo -n "Waiting for deployment to be ready."
    while curl -s "$URL" | grep -q "Nothing is here yet"; do
      echo -n "."
      sleep 1
    done
    
    # Stop tailing once deployment is ready
    if [ -n "$TAIL_PID" ]; then
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

