#!/usr/bin/env bash

set -eo pipefail

while IFS= read -r spec; do
  # Skip empty lines and comments (lines starting with # or containing only whitespace)
  spec=$(echo "$spec" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')  # trim whitespace
  [[ -z "$spec" || "$spec" =~ ^# ]] && continue
  
  # Remove inline comments (everything after # that's not at the start of line)
  spec=$(echo "$spec" | sed 's/[[:space:]]*#.*$//')
  [[ -z "$spec" ]] && continue
  
  tool=$(echo "$spec" | cut -d' ' -f1)
  version=$(echo "$spec" | cut -d' ' -f2)
  plugin=$(echo "$spec" | cut -d' ' -f3)
  
  # Add plugin if it doesn't exist
  if ! asdf plugin list | grep -q "^$plugin$"; then
    echo "Adding asdf plugin: $plugin"
    asdf plugin add $plugin || {
      echo "Warning: Failed to add plugin $plugin, continuing..."
      continue
    }
  fi
  
  # Install version if not already installed
  if ! asdf list $tool 2>/dev/null | grep -q $version; then
    echo "Installing $tool version $version"
    asdf install $tool $version || {
      echo "Warning: Failed to install $tool $version, continuing..."
      continue
    }
  fi
done < .tool-plugins
