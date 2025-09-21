#!/usr/bin/env bash

set -euo pipefail

CLOUDFLARE_ACCOUNT_ID=$(wrangler whoami | grep -o '[a-f0-9]\{32\}' | head -1)
open https://dash.cloudflare.com/$CLOUDFLARE_ACCOUNT_ID/pages/view/$CLOUDFLARE_PAGES_PROJECT
