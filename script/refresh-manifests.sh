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
    [fuel-core]="https://github.com/fuellabs/fuel-core"
    [sway]="https://github.com/fuellabs/sway"
    [sway-vim]="https://github.com/fuellabs/sway.vim"
)

# Unique attributes for each package.
declare -A pkg_fuel_core=(
    [name]="fuel-core"
    [repo]="${fuel_repos[fuel-core]}"
    [subdir]="./fuel-core"
    [lock]="./Cargo.lock"
)
declare -A pkg_fuel_gql_cli=(
    [name]="fuel-gql-cli"
    [repo]="${fuel_repos[fuel-core]}"
    [subdir]="./fuel-gql-cli"
    [lock]="./Cargo.lock"
)
declare -A pkg_forc=(
    [name]="forc"
    [repo]="${fuel_repos[sway]}"
    [subdir]="./forc"
    [lock]="./Cargo.lock"
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
    local repo_suffix="${pkg[repo]##*/}"
    local repo_dir="$WORK_DIR/$repo_suffix"
    echo "Refreshing published manifests for ${pkg[name]}"
    if [ ! -d "$repo_dir" ]; then
        git clone "${pkg[repo]}" "$repo_dir"
    fi
    echo "Retrieving published versions from git tags"
    pkg_git_tags=($(cd "$repo_dir" && git tag --list))
    echo "Found ${#pkg_git_tags[@]} git tags"
    for pkg_git_tag in ${pkg_git_tags[@]}; do
        pkg_version=${pkg_git_tag:1}

        echo "  Git tag: $pkg_git_tag | Version: $pkg_version"
    done

    #pkg_versions=($(cd "$repo_dir" && git tag --list | grep "^v" | cut -c 2-))
}

refresh_published pkg_fuel_core
# refresh_published pkg_fuel_gql_cli
# refresh_published pkg_forc


# # Ensure the `manifests/published` directory exists and contains an entry for
# # each published version of each package.
# # manifests/published/forc-0.21.0, etc.
# update_published() {
#     local published_path = "$manifests_path/published"
#     mkdir -p published_path
# }
