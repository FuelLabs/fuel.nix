#!/usr/bin/env zsh
set -euo pipefail

# Based on https://github.com/cachix/cachix-action/blob/master/dist/main/push-paths.sh

pathsToPush=$(comm -13 <(sort /tmp/store-path-pre-build) <("$(dirname "$0")"/list-nix-store.sh))

echo "$pathsToPush" | cachix push "fuellabs"