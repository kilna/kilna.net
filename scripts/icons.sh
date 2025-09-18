#!/bin/bash

set -euo pipefail

FORCE=false
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--force)
      FORCE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [-f|--force]"
      exit 1
      ;;
  esac
done

if ! command -v yq >/dev/null 2>&1; then
  echo "Error: yq is not installed. Try: brew install yq"
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is not installed."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YAML_FILE="$SCRIPT_DIR/../icons.yaml"
OUT_DIR="$SCRIPT_DIR/../assets/icons"

mkdir -p "$OUT_DIR"

echo "Downloading icons from $YAML_FILE ..."
yq eval '. as $root | keys | .[] | . as $key | {"name": $key, "iconify": $root[$key]}' "$YAML_FILE" | \
while read -r line; do
  if [[ "$line" == name:* ]]; then
    name="${line#name: }"
  elif [[ "$line" == iconify:* ]]; then
    id="${line#iconify: }"
    if [[ "$id" =~ ^([^:]+):(.+)$ ]]; then
      collection="${BASH_REMATCH[1]}"
      icon="${BASH_REMATCH[2]}"
      url="https://api.iconify.design/${collection}/${icon}.svg"
      out="$OUT_DIR/${name}.svg"
      if [[ -f "$out" && "$FORCE" != true ]]; then
        echo "  ⏭  $name.svg exists (use -f to force)"
        continue
      fi
      echo "  ↓  $id -> $name.svg"
      if curl -s -f "$url" -o "$out"; then
        echo "  ✓  Saved $name.svg"
      else
        echo "  ✗  Failed $id"
        rm -f "$out"
      fi
    else
      echo "Invalid iconify id: $id"
    fi
  fi
done

echo "Done."

