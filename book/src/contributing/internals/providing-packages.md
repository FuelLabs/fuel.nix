# Providing Packages

**fuel.nix** provides packages as [Nix flake `package` outputs][nix-flakes].

# Overview

The way in which **fuel.nix** creates package outputs is as follows:

1. Load all manifests from the `./manifests/` directory (see [Generating
   Manifests](./generating-manifests.html)).
2. Filter out manifests for package versions that are known to be broken, or
   untested versions that are older than **fuel.nix** itself, by applying the
   list of conditions in `./filters.nix`.
3. Patch the remaining manifests with their necessary build inputs (e.g.
   openssl, rust, etc) and environment variables based on the list of patches in
   `./patches.nix`.
4. Split manifests into `published` (e.g. `forc-0-28-0`) and `nightly` (e.g.
   `fuel-core-0-18-0-nightly-2023-05-04`) sets based on their file suffix.
5. Pass the resulting sets of manifests to `mkPackages` and use the
   [`buildRustPackage`][build-rust-package] function to build a unique package
   for each.
6. Create special packages for each package *set* using
   [`symlinkJoin`][symlink-join], e.g. `fuel-latest` (aliased to `fuel`) and
   `fuel-nightly`.

The following shares some more details on each stage.

# Filtering Manifests

After loading all manifests into a list by reading them from the
`./manifests/` directory, we first apply the filters to cull versions that are
known to be broken or that are too old.

Filters are a list of conditions loaded from the `./filters.nix` file. Only
manifests that satisfy all of these conditions will be used to provide
packages.

Conditions are functions where given a manifest `m`, return whether or not the
manifest should be included.

The following is an example of one of the conditions in `./filters.nix`:

```nix
  (m: m.pname != "forc" || versionAtLeast m.version "0.19.0")
```

This condition implies that only `forc` versions that are at least `0.19.0`
or greater will be included. This means `nix build .#forc-0-19-0` should work,
though `nix build .#forc-0-17-0` will not.

# Patching Manifests

After filtering out unnecessary or known-broken manifests, we build up the
remaining manifests by applying the list of patches loaded from `./patches.nix`.

Each patch includes:

1. A `condition` that must be met for the patch to be applied and
2. A `patch` function that provides the extra attributes that should be merged
   into the existing manifest.

All patches are applied to all manifests in the order in which they are declared
in the `patches.nix` list, provided that they meet the patch's condition.

### Using Patches to Fix Manifests

The following is an example taken from `patches.nix` that applies a fix for a
known broken `forc-wallet` version:

```nix
  # A patch for some `forc-wallet` nightlies whose committed `Cargo.lock` file
  # was out of date.
  {
    condition = m: m.pname == "forc-wallet" && m.version == "0.1.0" && m.date < "2022-09-04";
    patch = m: {
      cargoPatches = [
        ./patch/forc-wallet-0.1.0-update-lock.patch
      ];
      cargoHash = "sha256-LXQaPcpf/n1RRFTQXAP6PexfEI67U2Z5OOW5DzNJvX8=";
      cargoLock = null;
    };
  }
```

As the condition suggests, the patch is only applied to `forc-wallet` manifests
with a version equal to `0.1.0` and whose commit date precedes 2022-09-04.

### Using Patches to Extend Manifests

Patches are not only used to *fix* existing manifests, but also to build up
commonly required attributes in a simple manner. For example, the following
patch is the first patch in the list:

```nix
  # By default, most packages have their `Cargo.lock` file in the repo root.
  # We also specify a base, minimum Rust version. This version should never
  # change in order to avoid invalidating the cache for all previously built
  # packages. Instead, if a new version of a fuel package requires a newer
  # version of Rust, we should specify the necessary condition in a new patch
  # to ensure only newer packages use the newer version of Rust.
  {
    condition = m: true;
    patch = m: {
      cargoLock.lockFile = "${m.src}/Cargo.lock";
      meta.homepage = m.src.gitRepoUrl;
      rust = pkgs.rust-bin.stable."1.63.0".default;
    };
  }
```

As the condition implies, this patch is currently applied to *all* manifests.
The patch function provides some commonly useful attributes for building Rust
packages, i.e. the common location for the lock file, the default version of
Rust, and some package metadata about where the repository is located.

> **Note:** This condition may need to be changed in the future when aiming to
> support distributing non-Rust Fuel projects from `fuel.nix`.

### Adding or Changing Patches

In general, it is better to add new patches with conditions that only apply to
newer packages when accounting for newly introduced dependencies or changes to
a package's build environment.

This approach ensures we don't accidentally break older versions of packages,
and allows us to isolate each change clearly with its own entry in the list.

Here's a patch that was added to account for an update in the Rust version used:

```nix
  # `fuel-core` needs Rust 1.64 as of bcb86da09b6fdce09f13ef4181a0ca6461f8e2a8.
  # This changes the Rust used for all pkgs to 1.64 from the day of the commit.
  {
    condition = m: m.date >= "2022-09-23";
    patch = m: {
      rust = pkgs.rust-bin.stable."1.64.0".default;
    };
  }
```

It avoids breaking older versions by only applying the patch to manifests whose
commits after dated after 2022-09-23.

### Overriding Attributes

The example above also demonstrates how attributes can be overridden. In the
previous patch example above, the `rust` attribute was set to version `1.63.0`,
however the patch above overrides this attribute for all manifests created on or
after 2023-09-23, setting the version to `1.64.0`.

Multiple Rust version changes can be found throughout `patches.nix` that
override the version following a particular date.

# Building Packages

Now that we have our final sets of manifests, we can build our flake's package
outputs from them.

This involves mapping the manifests we constructed with the `buildRustPackage`
function provided by the Rust platform. This is all performed within the flake's
`mkPackages` function.

Package outputs are created for the published and nightly releases of each
individual package (e.g. `forc-0-28-0`, `fuel-core-0-18-0-nightly-2023-05-04`).

> **Note:** The use of hyphens for delineating semver versions rather than
periods! This can be a common gotcha when trying to use packages. E.g. `nix
run .#forc-0.18.0` is invalid, but `nix run .#forc-0-18-0` is valid.

### Package Sets

Unique packages are also created for each of the common package *sets*. These
can be thought of as packages that provide multiple other packges at once.

Most notably, we provide:

- **`fuel`** (aliased from `fuel-latest`) - Provides the latest semver version
  of every Fuel tool.
- **`fuel-nightly`** - Provides the latest nightly version of every Fuel tool.

Sets are also provided for each milestone, however this is covered in the
[Providing Milestones](./providing-milestones.html) chapter.

### Other Packages

While `mkPackages` mostly focuses on generating package outputs for all of
Fuel's Rust packages, it also provides a couple of "hand-written" packages:

1. `refresh-manifests` - This is a small package for the script used to refresh
   the manifests under the `./manifests/` directory.
2. `sway-vim` - A Vim plugin derivation for NixOS or Nix home-manager users who
   want to configure Vim in their Nix configuration.


[nix-flakes]: https://nixos.wiki/wiki/Flakes
[build-rust-package]: https://github.com/NixOS/nixpkgs/blob/58c85835512b0db938600b6fe13cc3e3dc4b364e/doc/languages-frameworks/rust.section.md
[symlink-join]: https://nixos.org/manual/nixpkgs/stable/#trivial-builder-symlinkJoin
