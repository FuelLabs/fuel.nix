#!/usr/bin/env bash

# Script: update_milestones.sh
# Description: Updates milestones.nix file with latest component hashes from GitHub releases
#
# Usage:
#   ./update_milestones.sh [options]
#
# Options:
#   --testnet-forc-wallet <tag|hash>   : Use specific forc-wallet tag/hash for testnet
#   --testnet-fuel-core <tag|hash>     : Use specific fuel-core tag/hash for testnet
#   --testnet-sway <tag|hash>          : Use specific sway tag/hash for testnet
#   --mainnet-forc-wallet <tag|hash>   : Use specific forc-wallet tag/hash for ignition/mainnet
#   --mainnet-fuel-core <tag|hash>     : Use specific fuel-core tag/hash for ignition/mainnet
#   --mainnet-sway <tag|hash>          : Use specific sway tag/hash for ignition/mainnet
#   --verbose                          : Enable verbose output
#   --help                             : Show this help message
#
# Example:
#   ./update_milestones.sh --testnet-forc-wallet v0.14.0 --mainnet-sway v0.45.0
#
# Exit codes:
#   0 - Success
#   1 - General error
#   2 - Missing required dependency
#   3 - GitHub API error

# Exit on any error
set -e

# Colors for terminal output
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
VERBOSE=false
MILESTONES_FILE="milestones.nix"
TESTNET_FORC_WALLET=""
TESTNET_FUEL_CORE=""
TESTNET_SWAY=""
MAINNET_FORC_WALLET=""
MAINNET_FUEL_CORE=""
MAINNET_SWAY=""

# Array to store summary information
declare -a TESTNET_SUMMARY
declare -a MAINNET_SUMMARY

# Function to print messages
log() {
  local level=$1
  local message=$2

  # If verbose is off, only print errors and warnings
  if [[ "$VERBOSE" == "false" && "$level" == "INFO" ]]; then
    return
  fi

  timestamp=$(date "+%Y-%m-%d %H:%M:%S")

  # Color errors in red
  if [[ "$level" == "ERROR" ]]; then
    echo -e "[$timestamp] [${RED}$level${NC}] $message" >&2
  else
    echo "[$timestamp] [$level] $message" >&2
  fi
}

# Function to print usage information
usage() {
  grep "^# " "$0" | cut -c 3- | grep -v "Exit codes:" | sed '/^$/q'
  exit 0
}

# Function to check required dependencies
check_dependencies() {
  local missing_deps=false

  if ! command -v jq &> /dev/null; then
    log "ERROR" "jq is required but not installed."
    missing_deps=true
  fi

  if ! command -v curl &> /dev/null; then
    log "ERROR" "curl is required but not installed."
    missing_deps=true
  fi

  if ! command -v sed &> /dev/null; then
    log "ERROR" "sed is required but not installed."
    missing_deps=true
  fi

  if [[ "$missing_deps" == "true" ]]; then
    exit 2
  fi
}

# Function to get commit hash from tag or use provided hash
get_commit_hash() {
  local repo=$1
  local tag_or_hash=$2

  log "INFO" "Getting commit hash for $repo using '$tag_or_hash'"

  # If it looks like a commit hash already, return it
  if [[ $tag_or_hash =~ ^[0-9a-f]{40}$ ]]; then
    log "INFO" "Input looks like a hash, using directly: $tag_or_hash"
    echo $tag_or_hash
    return 0
  fi

  # Remove 'v' prefix if present
  local tag=${tag_or_hash#v}

  # Try with v prefix first
  log "INFO" "Trying API call with v-prefix: v$tag"
  local response=$(curl -s "https://api.github.com/repos/FuelLabs/$repo/git/refs/tags/v$tag")

  if [[ $(echo $response | jq 'has("object")') == "false" ]]; then
    log "INFO" "Tag not found with v-prefix, trying without v: $tag"
    response=$(curl -s "https://api.github.com/repos/FuelLabs/$repo/git/refs/tags/$tag")
  fi

  if [[ $(echo $response | jq 'has("object")') == "false" ]]; then
    log "ERROR" "Failed to get tag info for $repo tag $tag_or_hash"
    echo "$response" | jq '.' >&2
    exit 3
  fi

  local object_type=$(echo $response | jq -r '.object.type')
  local sha=$(echo $response | jq -r '.object.sha')

  log "INFO" "Found object of type $object_type with SHA $sha"

  # If it's an annotated tag, we need to get the commit it points to
  if [[ "$object_type" == "tag" ]]; then
    log "INFO" "Annotated tag found, getting commit SHA"
    local tag_url=$(echo $response | jq -r '.object.url')
    local tag_response=$(curl -s "$tag_url")
    sha=$(echo $tag_response | jq -r '.object.sha')
    log "INFO" "Commit SHA from annotated tag: $sha"
  fi

  echo $sha
}

# Function to get the latest release tag and commit hash
get_latest_release() {
  local repo=$1

  log "INFO" "Getting latest release for $repo"
  local response=$(curl -s "https://api.github.com/repos/FuelLabs/$repo/releases/latest")

  if [[ $(echo $response | jq 'has("tag_name")') == "false" ]]; then
    log "ERROR" "Failed to get latest release for $repo"
    echo "$response" | jq '.' >&2
    exit 3
  fi

  local tag_name=$(echo $response | jq -r '.tag_name')
  log "INFO" "Latest release tag for $repo: $tag_name"

  local commit_hash=$(get_commit_hash $repo $tag_name)
  log "INFO" "Commit hash for $tag_name: $commit_hash"

  # Return both tag_name and commit_hash
  echo "$tag_name|$commit_hash"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --testnet-forc-wallet)
      TESTNET_FORC_WALLET="$2"
      shift 2
      ;;
    --testnet-fuel-core)
      TESTNET_FUEL_CORE="$2"
      shift 2
      ;;
    --testnet-sway)
      TESTNET_SWAY="$2"
      shift 2
      ;;
    --mainnet-forc-wallet)
      MAINNET_FORC_WALLET="$2"
      shift 2
      ;;
    --mainnet-fuel-core)
      MAINNET_FUEL_CORE="$2"
      shift 2
      ;;
    --mainnet-sway)
      MAINNET_SWAY="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --help)
      usage
      ;;
    *)
      log "ERROR" "Unknown option: $1"
      usage
      ;;
  esac
done

# Check if required dependencies are installed
check_dependencies

# Main execution
log "INFO" "Starting update of $MILESTONES_FILE"

# Verify that milestones file exists
if [ ! -f "$MILESTONES_FILE" ]; then
  log "ERROR" "File $MILESTONES_FILE not found"
  exit 1
fi

# Define repos to update
REPOS=("forc-wallet" "fuel-core" "sway")

# Create a temp file for processing
TEMP_FILE=$(mktemp)
cp "$MILESTONES_FILE" "$TEMP_FILE"

# Function to update a component hash in the milestones file
update_component_hash() {
  local environment=$1
  local component=$2
  local hash=$3
  local file="$TEMP_FILE"
  local temp_file2=$(mktemp)

  log "INFO" "Updating $component in $environment to $hash"

  awk -v env="$environment" -v comp="$component" -v hash="$hash" '
  BEGIN { in_env = 0; }
  /^  '${environment}' = \{/ { in_env = 1; print; next; }
  /^  \};/ { in_env = 0; print; next; }

  in_env && $1 == comp && $2 == "=" { 
    printf "    %s = \"%s\";\n", comp, hash;
  }
  !(in_env && $1 == comp && $2 == "=") { print; }
  ' "$file" > "$temp_file2"

  mv "$temp_file2" "$file"
}

# Update testnet components
log "INFO" "Updating testnet components"
for repo in "${REPOS[@]}"; do
  input_value_var="TESTNET_${repo^^}"
  input_value_var="${input_value_var//-/_}"
  input_value="${!input_value_var}"

  if [[ -n "$input_value" ]]; then
    tag_name="$input_value"
    log "INFO" "Using provided input for testnet $repo: $tag_name"
    commit_hash=$(get_commit_hash "$repo" "$input_value")
  else
    log "INFO" "No input provided for testnet $repo, getting latest release"
    release_info=$(get_latest_release "$repo")
    tag_name=$(echo "$release_info" | cut -d'|' -f1)
    commit_hash=$(echo "$release_info" | cut -d'|' -f2)
  fi

  log "INFO" "Updating $repo for testnet: $tag_name -> $commit_hash"
  update_component_hash "testnet" "$repo" "$commit_hash"

  TESTNET_SUMMARY+=("\`$repo\`: $tag_name")
done

# Update ignition and mainnet components
log "INFO" "Updating ignition and mainnet components"
for repo in "${REPOS[@]}"; do
  input_value_var="MAINNET_${repo^^}"
  input_value_var="${input_value_var//-/_}"
  input_value="${!input_value_var}"

  if [[ -n "$input_value" ]]; then
    tag_name="$input_value"
    log "INFO" "Using provided input for mainnet $repo: $tag_name"
    commit_hash=$(get_commit_hash "$repo" "$input_value")
  else
    log "INFO" "No input provided for mainnet $repo, getting latest release"
    release_info=$(get_latest_release "$repo")
    tag_name=$(echo "$release_info" | cut -d'|' -f1)
    commit_hash=$(echo "$release_info" | cut -d'|' -f2)
  fi

  log "INFO" "Updating $repo for ignition/mainnet: $tag_name -> $commit_hash"
  update_component_hash "ignition" "$repo" "$commit_hash"
  update_component_hash "mainnet" "$repo" "$commit_hash"

  MAINNET_SUMMARY+=("\`$repo\`: $tag_name")
done

# Write the updated content back to the file
cp "$TEMP_FILE" "$MILESTONES_FILE"
rm "$TEMP_FILE"
log "INFO" "Updated $MILESTONES_FILE successfully"

# Create PR description for the workflow to use
PR_DESCRIPTION=$(cat << EOF
Bump testnet, ignition and mainnet channels.

Testnet:
$(printf "%s\n" "${TESTNET_SUMMARY[@]}")

Ignition & Mainnet:
$(printf "%s\n" "${MAINNET_SUMMARY[@]}")
EOF
)

# Output the PR description
log "INFO" "PR description generated"
if [[ -n "${GITHUB_ENV}" ]]; then
  log "INFO" "Writing PR description to GITHUB_ENV"
  echo "PR_DESCRIPTION<<EOF" >> $GITHUB_ENV
  echo "$PR_DESCRIPTION" >> $GITHUB_ENV
  echo "EOF" >> $GITHUB_ENV
else
  log "INFO" "GITHUB_ENV not detected, printing PR description to stdout"
  echo "---------- PR DESCRIPTION ----------"
  echo "$PR_DESCRIPTION"
  echo "-----------------------------------"
fi

log "INFO" "Script completed successfully"
exit 0
