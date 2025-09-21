#!/usr/bin/env bash

set -euo pipefail

# Script to open Cloudflare Pages deployment dashboard
# Usage: ./scripts/cloudflare.sh [api]

PROJECT_NAME="kilna-net"
DASHBOARD_URL="https://dash.cloudflare.com/pages/view/kilna/${PROJECT_NAME}"

# Get current commit hash
COMMIT_HASH=$(git rev-parse HEAD)
echo "Current commit: ${COMMIT_HASH}"

if [ "${1:-}" = "api" ]; then
  echo "Attempting to find deployment URL via Cloudflare API..."
  
  if [ -z "${CLOUDFLARE_API_TOKEN:-}" ]; then
    echo "Error: CLOUDFLARE_API_TOKEN environment variable not set"
    echo "Set it with: export CLOUDFLARE_API_TOKEN=your_token_here"
    echo "Falling back to regular dashboard..."
    open "${DASHBOARD_URL}"
    exit 0
  fi
  
  if [ -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
    echo "Error: CLOUDFLARE_ACCOUNT_ID environment variable not set"
    echo "Set it with: export CLOUDFLARE_ACCOUNT_ID=your_account_id"
    echo "Falling back to regular dashboard..."
    open "${DASHBOARD_URL}"
    exit 0
  fi
  
  echo "Using Cloudflare API to find deployment..."
  
  # Try to find deployment by commit hash
  DEPLOYMENT_URL=$(curl -s -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    "https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/pages/projects/${PROJECT_NAME}/deployments" \
    | jq -r ".result[] | select(.deployment_trigger.metadata.commit_hash == \"${COMMIT_HASH}\") | .url" | head -1)
  
  if [ "${DEPLOYMENT_URL}" != "null" ] && [ -n "${DEPLOYMENT_URL}" ]; then
    echo "Found deployment URL: ${DEPLOYMENT_URL}"
    open "${DEPLOYMENT_URL}"
  else
    echo "Deployment not found via API, opening dashboard..."
    open "${DASHBOARD_URL}"
  fi
else
  echo "Opening Cloudflare Pages deployment dashboard..."
  echo "Look for commit ${COMMIT_HASH} in the deployments list"
  open "${DASHBOARD_URL}"
fi
