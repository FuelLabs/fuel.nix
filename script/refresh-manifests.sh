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
    [forc-wallet]="https://github.com/fuellabs/forc-wallet"
    [fuel-core]="https://github.com/fuellabs/fuel-core"
    [sway]="https://github.com/fuellabs/sway"
    [sway-vim]="https://github.com/fuellabs/sway.vim"
)

# The set of packages.
declare -A pkg_fuel_core=(
    [name]="fuel-core"
    [repo]="${fuel_repos[fuel-core]}"
)
declare -A pkg_fuel_gql_cli=(
    [name]="fuel-gql-cli"
    [repo]="${fuel_repos[fuel-core]}"
)
declare -A pkg_forc=(
    [name]="forc"
    [repo]="${fuel_repos[sway]}"
)
declare -A pkg_forc_explore=(
    [name]="forc-explore"
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
declare -A pkg_forc_wallet=(
    [name]="forc-wallet"
    [repo]="${fuel_repos[forc-wallet]}"
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

# Refresh the set of published manifests for the given package.
function refresh_published {
    local -n pkg=$1
    local pkg_repo_suffix="${pkg[repo]##*/}"
    local pkg_repo_dir="$WORK_DIR/$pkg_repo_suffix"
    echo "Refreshing published manifests for ${pkg[name]}"
    if [ ! -d "$pkg_repo_dir" ]; then
        git clone "${pkg[repo]}" "$pkg_repo_dir"
    fi
    echo "Retrieving published versions from git tags"
    pkg_git_tags=($(cd "$pkg_repo_dir" && git tag --list))
    echo "Found ${#pkg_git_tags[@]} git tags"
    for pkg_git_tag in "${pkg_git_tags[@]}"; do
        pkg_version="${pkg_git_tag:1}"
        if [[ $(semver validate $pkg_version) != "valid" ]]; then
            echo "Skipping non-semver tag: $pkg_git_tag"
            continue
        fi

        # Construct a manifest for this package at this version.
        local pkg_manifest_name="${pkg[name]}-$pkg_version"
        local pkg_manifest_path="$MANIFESTS_DIR/$pkg_manifest_name.nix"
        echo "Creating manifest for $pkg_manifest_name at $pkg_manifest_path"

        # Retrieve the commit for the tag.
        (cd $pkg_repo_dir && git checkout "$pkg_git_tag")
        local pkg_git_rev=$(git -C $pkg_repo_dir rev-parse HEAD)

        # Generate the sha256. We must move the inner `.git` dir, hash, then put it back.
        mv "$pkg_repo_dir/.git" "$WORK_DIR"
        local pkg_version_hash=$(nix hash path "$pkg_repo_dir")
        mv "$WORK_DIR/.git" $pkg_repo_dir

        # Write the nix attrset.
        local tmp_manifest_path="$WORK_DIR/$pkg_manifest_name.nix"
        local pkg_manifest_nix="\
            {
              pname = \"${pkg[name]}\";
              version = \"$pkg_version\";
              url = \"${pkg[repo]}\";
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
    done
}

refresh_published pkg_fuel_core
refresh_published pkg_fuel_gql_cli
refresh_published pkg_forc
refresh_published pkg_forc_explore
refresh_published pkg_forc_fmt
refresh_published pkg_forc_lsp
refresh_published pkg_forc_wallet

# # Ensure the `manifests/published` directory exists and contains an entry for
# # each published version of each package.
# # manifests/published/forc-0.21.0, etc.
# update_published() {
#     local published_path = "$manifests_path/published"
#     mkdir -p published_path
# }
