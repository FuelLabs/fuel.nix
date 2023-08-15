#!/usr/bin/env zsh
set -euo pipefail

# Borrowed from https://github.com/cachix/cachix-action/blob/master/dist/main/push-paths.sh

cachix=$1 cachixArgs=${2:--j8} cache=$3 pathsToPush=$4 pushFilter=$5

if [[ $pathsToPush == "" ]]; then
    pathsToPush=$(comm -13 <(sort /tmp/store-path-pre-build) <("$(dirname "$0")"/list-nix-store.sh))

    if [[ $pushFilter != "" ]]; then
        pathsToPush=$(echo "$pathsToPush" | grep -vEe "$pushFilter")
    fi
fi

echo "$pathsToPush" | "$cachix" push $cachixArgs "$cache"