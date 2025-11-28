# Adding Packages

Adding new packages requires making small updates to multiple sections of
**fuel.nix**:

## Updating `./scripts/refresh-manifests.sh`

If the new package requires adding a new repository, first add an entry to the
set of repositories:

```sh
# The set of fuel repositories.
declare -A fuel_repos=(
    [forc]="https://github.com/fuellabs/forc"
    [forc-wallet-legacy]="https://github.com/fuellabs/forc-wallet"
    [fuel-core]="https://github.com/fuellabs/fuel-core"
    [sway]="https://github.com/fuellabs/sway"
    [sway-vim]="https://github.com/fuellabs/sway.vim"
)
```

Next, add a dedicated package declaration:

```sh
# The set of packages.
declare -A pkg_forc=(
    [name]="forc"
    [repo]="${fuel_repos[sway]}"
)
declare -A pkg_forc_client=(
    [name]="forc-client"
    [repo]="${fuel_repos[sway]}"
)
declare -A pkg_forc_doc=(
    [name]="forc-doc"
    [repo]="${fuel_repos[sway]}"
)
# ...
```

Finally, add a call to `refresh` for the new package:

```sh
refresh pkg_forc
refresh pkg_forc_client
refresh pkg_forc_doc
refresh pkg_forc_fmt
refresh pkg_forc_index
refresh pkg_forc_lsp
refresh pkg_forc_tx
refresh pkg_forc_wallet
refresh pkg_fuel_core
refresh pkg_fuel_core_client
refresh pkg_fuel_indexer
```

This should ensure that the new package's manifests are generated as a part of
the nightly `refresh-manifests` CI action.

## Updating `./filters.nix`

It's often useful to filter out older versions that will never be tested by the
flake's CI.

We can do so by adding a condition to the list of filters:

```nix
  (m: m.pname != "forc" || versionAtLeast m.version "0.19.0")
  (m: m.pname != "forc-client" || versionAtLeast m.version "0.19.0")
  # ...
```

See the [Filtering
Manifests](./internals/providing-packages.html#filtering-manifests) section for
more details.

## Updating `./patches.nix`

If necessary, add a custom patch for the new package including any necessary
unique attributes, environment variables, etc:

```nix
    {
      condition = m: m.pname == "forc-client";
      patch = m: {
        buildAndTestSubdir = "forc-plugins/${m.pname}";
        nativeBuildInputs = [
          pkgs.perl # for openssl-sys
          pkgs.pkg-config # for openssl-sys
        ];
      };
    }
```

For more details on how to apply manifest patches, see the
[Patching Manifests](./internals/providing-packages.html#patching-manifests)
section.

> **Tip:** Check the new package's upstream CI to get an idea of what system
> dependencies, build inputs and environment setup might be required for the
> patch.

## Updating `./milestones.nix`

If the new package is provided from a new repository, ensure the new repository
is added to the milestones as necessary.

## Package Sets

The new package should automatically be included as a part of the `fuel`,
`fuel-nightly` and milestone package sets.

## Example Commits

The following commits show the basics of adding a new package. In this case,
the `forc-client` plugin.

- [**Add forc-client to the refresh-manifests script**](https://github.com/FuelLabs/fuel.nix/pull/13/commits/ee1045ff1e6ce5df0e7f08aca4ce4cd6e72b3b51)
- [**Add forc-client package to the nix flake**](https://github.com/FuelLabs/fuel.nix/pull/13/commits/117257429a3055abfe1bb8084be76f5facccfaba)
