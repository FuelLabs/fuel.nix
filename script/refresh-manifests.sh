# Refresh the set of manifests within the given `manifests` directory.
#
# The `fuel.nix` flake uses the manifests in the `manifests` directory to
# construct the pinned `src` for each of its packages.

# Find the flake directory root.
FLAKE_ROOT_DIR="$PWD"
while [[ ! -f "$FLAKE_ROOT_DIR/flake.nix" && $FLAKE_ROOT_DIR != / ]] ; do
    FLAKE_ROOT_DIR="${FLAKE_ROOT_DIR%/*}"
done
if [[ $FLAKE_ROOT_DIR == / ]] ; then
    echo "Unable to find flake root directory"
fi
echo "Flake root directory: $FLAKE_ROOT_DIR"

# The directory storing all output package manifests.
MANIFESTS_DIR="$FLAKE_ROOT_DIR/manifests"
echo "Manifests directory: $MANIFESTS_DIR"

# The set of fuel repositories.
declare -A fuel_repos=(
    [forc]="https://github.com/fuellabs/forc"
    [forc-wallet-legacy]="https://github.com/fuellabs/forc-wallet"
    [fuel-core]="https://github.com/fuellabs/fuel-core"
    [sway]="https://github.com/fuellabs/sway"
    [sway-vim]="https://github.com/fuellabs/sway.vim"
)

# The set of packages.
declare -A pkg_forc=(
    [name]="forc"
    [repo]="${fuel_repos[sway]}"
)
# forc-client migrated to forc monorepo at 0.71.0; legacy repo (sway) for older versions.
declare -A pkg_forc_client=(
    [name]="forc-client"
    [repo]="${fuel_repos[forc]}"
    [legacy_repo]="${fuel_repos[sway]}"
    [legacy_before]="0.71.0"
)
# forc-crypto migrated to forc monorepo at 0.71.0; legacy repo (sway) for older versions.
declare -A pkg_forc_crypto=(
    [name]="forc-crypto"
    [repo]="${fuel_repos[forc]}"
    [legacy_repo]="${fuel_repos[sway]}"
    [legacy_before]="0.71.0"
)
declare -A pkg_forc_debug=(
    [name]="forc-debug"
    [repo]="${fuel_repos[sway]}"
)
# forc-node migrated to forc monorepo at 0.71.0; legacy repo (sway) for older versions.
declare -A pkg_forc_node=(
    [name]="forc-node"
    [repo]="${fuel_repos[forc]}"
    [legacy_repo]="${fuel_repos[sway]}"
    [legacy_before]="0.71.0"
)
declare -A pkg_forc_doc=(
    [name]="forc-doc"
    [repo]="${fuel_repos[sway]}"
)
declare -A pkg_forc_fmt=(
    [name]="forc-fmt"
    [repo]="${fuel_repos[sway]}"
)
declare -A pkg_forc_lsp=(
    [name]="forc-lsp"
    [repo]="${fuel_repos[sway]}"
)
declare -A pkg_forc_tx=(
    [name]="forc-tx"
    [repo]="${fuel_repos[sway]}"
)
declare -A pkg_forc_migrate=(
    [name]="forc-migrate"
    [repo]="${fuel_repos[sway]}"
)
declare -A pkg_forc_publish=(
    [name]="forc-publish"
    [repo]="${fuel_repos[sway]}"
)
# forc-wallet migrated to forc monorepo at 0.16.0; legacy repo for older versions.
declare -A pkg_forc_wallet=(
    [name]="forc-wallet"
    [repo]="${fuel_repos[forc]}"
    [legacy_repo]="${fuel_repos[forc-wallet-legacy]}"
    [legacy_before]="0.16.0"
)
declare -A pkg_fuel_core=(
    [name]="fuel-core"
    [repo]="${fuel_repos[fuel-core]}"
)
declare -A pkg_fuel_core_client=(
    [name]="fuel-core-client"
    [repo]="${fuel_repos[fuel-core]}"
)

# Create a temporary directory for cloning repositories.
# Make sure it exists, and make sure we clean up on exit.
WORK_DIR=`mktemp -d`
if [[ ! "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
    echo "Failed to create temporary directory"
    exit 1
fi
echo "Created temporary work directory: $WORK_DIR"
function cleanup {
    rm -rf "$WORK_DIR"
    echo "Cleaned up temporary work directory"
}
trap cleanup EXIT

# Writes a manifest to a temp dir, formats it, and copies it to `manifests/`.
function write_manifest {
    local pkg_name=$1
    local pkg_repo=$2
    local pkg_version=$3
    local pkg_version_date=$4
    local pkg_git_rev=$5
    local pkg_version_hash=$6
    local pkg_manifest_name=$7

    local pkg_manifest_path="$MANIFESTS_DIR/$pkg_manifest_name.nix"
    echo "Creating manifest for $pkg_manifest_name at $pkg_manifest_path"

    # Write the nix attrset.
    local tmp_manifest_path="$WORK_DIR/$pkg_manifest_name.nix"
    local pkg_manifest_nix="\
        {
          pname = \"$pkg_name\";
          version = \"$pkg_version\";
          date = \"$pkg_version_date\";
          url = \"$pkg_repo\";
          rev = \"$pkg_git_rev\";
          sha256 = \"$pkg_version_hash\";
        }
    ";
    echo "$pkg_manifest_nix" > "$tmp_manifest_path"

    # Use nix to format and check the generated manifest is valid.
    nix fmt "$tmp_manifest_path" 2> "/dev/null"
    if [[ $? != 0 ]]; then
        echo "Failed to format generated manifest:"
        nix fmt "$tmp_manifest_path"
        exit 1
    fi

    mkdir -p "$MANIFESTS_DIR"
    cp $tmp_manifest_path $pkg_manifest_path

}

# Refresh published manifests from a repo. Args: pkg_ref, repo_url, tag_prefix, [max_version]
# If max_version is set, only versions < max_version are included.
function refresh_published_from_repo {
    local -n rpkg=$1
    local repo_url=$2
    local tag_prefix=$3
    local max_version=${4:-}

    local pkg_repo_suffix="${repo_url##*/}"
    local pkg_repo_dir="$WORK_DIR/$pkg_repo_suffix"
    echo "Refreshing published manifests for ${rpkg[name]} from $pkg_repo_suffix"
    if [ ! -d "$pkg_repo_dir" ]; then
        git clone "$repo_url" "$pkg_repo_dir"
    fi
    local pkg_git_branch="$(cd $pkg_repo_dir && git branch --show-current)"
    pkg_git_tags=($(cd "$pkg_repo_dir" && git tag --list "${tag_prefix}*"))
    echo "Found ${#pkg_git_tags[@]} matching tags"
    for pkg_git_tag in "${pkg_git_tags[@]}"; do
        pkg_version="${pkg_git_tag#"$tag_prefix"}"
        if [[ $(semver validate "$pkg_version") != "valid" ]]; then
            continue
        fi
        # Skip if version >= max_version (used for legacy repos).
        if [[ -n "$max_version" && $(semver compare "$pkg_version" "$max_version") -ge 0 ]]; then
            continue
        fi

        (cd $pkg_repo_dir && git checkout -q "$pkg_git_tag")
        local pkg_git_rev=$(git -C $pkg_repo_dir rev-parse HEAD)
        local pkg_version_date="$(cd $pkg_repo_dir && git show -s --format=%ci $pkg_git_rev | cut -d ' ' -f1)"
        mv "$pkg_repo_dir/.git" "$WORK_DIR"
        local pkg_version_hash=$(nix hash path "$pkg_repo_dir")
        mv "$WORK_DIR/.git" $pkg_repo_dir

        write_manifest "${rpkg[name]}" "$repo_url" "$pkg_version" "$pkg_version_date" "$pkg_git_rev" "$pkg_version_hash" "${rpkg[name]}-$pkg_version"
    done
    (cd $pkg_repo_dir && git checkout -q "$pkg_git_branch")
}

# Refresh the set of published manifests for the given package.
function refresh_published {
    local -n pkg=$1
    if [[ -n "${pkg[legacy_repo]:-}" ]]; then
        refresh_published_from_repo pkg "${pkg[legacy_repo]}" "v" "${pkg[legacy_before]}"
        refresh_published_from_repo pkg "${pkg[repo]}" "${pkg[name]}-"
    else
        refresh_published_from_repo pkg "${pkg[repo]}" "v"
    fi
}

# Refresh nightly manifests from a repo. Args: pkg_ref, repo_url, tag_prefix, start_date, end_date
function refresh_nightlies_from_repo {
    local -n npkg=$1
    local repo_url=$2
    local tag_prefix=$3
    local start_date=$4
    local end_date=$5

    local pkg_repo_suffix="${repo_url##*/}"
    local pkg_repo_dir="$WORK_DIR/$pkg_repo_suffix"
    echo "Refreshing nightly manifests for ${npkg[name]} from $pkg_repo_suffix ($start_date to $end_date)"
    if [ ! -d "$pkg_repo_dir" ]; then
        git clone "$repo_url" "$pkg_repo_dir"
    fi
    local pkg_git_branch="$(cd $pkg_repo_dir && git branch --show-current)"
    local last_git_rev=""
    local date_nightly="$start_date"
    local tag_pattern="(tag: $tag_prefix"
    local tag_prefix_full=" (tag: $tag_prefix"
    while [[ "$date_nightly" < "$end_date" || "$date_nightly" == "$end_date" ]]; do
        local pkg_git_rev=$(cd $pkg_repo_dir && git log --before="$date_nightly 00:00:00 +0000" --pretty=oneline -1 | cut -d ' ' -f1)
        if [[ "${#pkg_git_rev}" == 40 && $pkg_git_rev != $last_git_rev ]]; then
            # Retrieve version from the tag preceding the nightly date.
            local git_tag_line=$(cd $pkg_repo_dir && git log --tags --simplify-by-decoration --before="$date_nightly 00:00:00 +0000" --pretty="format:%d" | grep -e "$tag_pattern" | cut -d ')' -f1 | cut -d ',' -f1 | head -n 1)
            local pkg_version=${git_tag_line#"$tag_prefix_full"}
            if [[ $(semver validate "$pkg_version") != "valid" ]]; then
                pkg_version="0.0.0"
            fi

            # Generate the sha256. We must move the inner `.git` dir, hash, then put it back.
            (cd $pkg_repo_dir && git checkout -q "$pkg_git_rev")
            mv "$pkg_repo_dir/.git" "$WORK_DIR"
            local pkg_version_hash=$(nix hash path "$pkg_repo_dir")
            mv "$WORK_DIR/.git" $pkg_repo_dir

            # Construct a manifest for this package at this version.
            local pkg_manifest_name="${npkg[name]}-$pkg_version-nightly-$date_nightly"

            write_manifest "${npkg[name]}" "$repo_url" "$pkg_version" "$date_nightly" "$pkg_git_rev" "$pkg_version_hash" "$pkg_manifest_name"

            # Switch back to the default branch before looping back.
            (cd $pkg_repo_dir && git checkout -q "$pkg_git_branch")
            last_git_rev="$pkg_git_rev"
        fi
        date_nightly=$(date -u '+%F' -d "$date_nightly+1 days")
    done
}

# Get the date of the first tag matching a prefix in a repo.
function get_first_tag_date {
    local repo_url=$1
    local tag_prefix=$2

    local pkg_repo_suffix="${repo_url##*/}"
    local pkg_repo_dir="$WORK_DIR/$pkg_repo_suffix"
    if [ ! -d "$pkg_repo_dir" ]; then
        git clone "$repo_url" "$pkg_repo_dir"
    fi
    # Find the first (oldest) tag matching the prefix by sorting tags by date.
    local first_tag=$(cd "$pkg_repo_dir" && git tag --list "${tag_prefix}*" --sort=creatordate | head -n 1)
    if [[ -n "$first_tag" ]]; then
        (cd "$pkg_repo_dir" && git show -s --format=%ci "$first_tag" | cut -d ' ' -f1)
    fi
}

# Refresh the set of nightly manifests for the given package.
function refresh_nightlies {
    local -n pkg=$1
    echo "Refreshing nightly manifests for ${pkg[name]}"
    # Only keep the last 30 days of nightlies to reduce manifest count
    local date_today=$(date -u +"%F")
    local date_start=$(date -u '+%F' -d "$date_today-30 days")

    if [[ -n "${pkg[legacy_repo]:-}" ]]; then
        # For packages with legacy repos, find the cutoff date (first tag in new repo).
        local first_new_tag_date=$(get_first_tag_date "${pkg[repo]}" "${pkg[name]}-")
        if [[ -n "$first_new_tag_date" ]]; then
            echo "First ${pkg[name]} tag in new repo: $first_new_tag_date"
            # Legacy repo: from date_start to day before first new tag (if in range).
            local legacy_end=$(date -u '+%F' -d "$first_new_tag_date-1 days")
            if [[ ! "$legacy_end" < "$date_start" ]]; then
                refresh_nightlies_from_repo pkg "${pkg[legacy_repo]}" "v" "$date_start" "$legacy_end"
            fi
            # New repo: from first new tag date (or date_start if later) to today.
            local new_start="$first_new_tag_date"
            if [[ "$new_start" < "$date_start" ]]; then
                new_start="$date_start"
            fi
            refresh_nightlies_from_repo pkg "${pkg[repo]}" "${pkg[name]}-" "$new_start" "$date_today"
        else
            # No tags in new repo yet, use legacy repo for all nightlies.
            refresh_nightlies_from_repo pkg "${pkg[legacy_repo]}" "v" "$date_start" "$date_today"
        fi
    else
        refresh_nightlies_from_repo pkg "${pkg[repo]}" "v" "$date_start" "$date_today"
    fi
}

function refresh {
    local -n fpkg=$1
    refresh_published fpkg
    refresh_nightlies fpkg
}

refresh pkg_forc
refresh pkg_forc_client
refresh pkg_forc_crypto
refresh pkg_forc_debug
refresh pkg_forc_doc
refresh pkg_forc_node
refresh pkg_forc_fmt
refresh pkg_forc_lsp
refresh pkg_forc_tx
refresh pkg_forc_migrate
refresh pkg_forc_publish
refresh pkg_forc_wallet
refresh pkg_fuel_core
refresh pkg_fuel_core_client
