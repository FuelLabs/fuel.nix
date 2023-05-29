# Contributing

This chapter will cover the internals of **fuel.nix** and how it works.

At a very high level, **fuel.nix** does the following:

1. **Generate a unique "manifest" for each version of each package** every night
   at 00:00 UTC under the `./manifests` directory using a CI action that runs
   the `./scripts/refresh-manifests.sh` script.
2. **Provide `package` flake outputs** (e.g. `forc-0-20-0`,
   `fuel-core-0-18-0-nightly-2023-04-29`) by collecting, filtering
   (`filters.nix`) and patching (`patches.nix`) all manifests.
3. **Provide a special set of "milestone" packages** (e.g.
   `forc-wallet-beta-2`) and package sets (e.g. `fuel-beta-3`) by finding
   packages that match the commits specified in `milestones.nix`.
4. **Provide individual "sets" of packages** for the latest semver releases and
   nightlies, e.g. (`fuel-latest`, `fuel-nightly`).
5. **Provide the default fuel package set `fuel`** as an alias for `fuel-latest`.
6. **Provide `devShell`s** to assist working on the fuel repos by collecting all
   of the inputs to their associated packages and inheriting their environment
   variables.

Read on for more details on each of these steps.


# 1. Generating Manifests

In **fuel.nix**, "Manifests" are small nix files that declare some unique
properties for a particular version of a particular package. These manifests
are used by `flake.nix` to provide all of the fuel packages in a declarative,
reproducible manner.

Here's an example of what a manifest looks like:

```nix
{{#include ../../manifests/fuel-core-0.18.0.nix}}
```

Each night at 00:00 UTC, the `fuel.nix` repo's `refresh-manifests` GitHub action
runs the `./scripts/refresh-manifests.sh` script.

The role of this script is to fetch each of the FuelLabs GitHub repositories,
scan them for all versioned releases (by checking their git tags) and for all
nightly releases (by checking timestamps) in order to generate a unique manifest
for every version of every package and store them under the `./manifests/`
directory.

The GitHub action checks the diff to see if there are any new manifests since
the previous night. If so, it attempts to build and cache them on each supported
platform. Upon success, the action commits the new manifests directly to the
`master` branch.

**Refreshing Manifests Locally**

As a maintainer, you can run the script locally by cloning the repository,
`cd`ing into the repo and running:

```console
nix run .#refresh-manifests
```

Running the script like this will ensure you have access to the necessary tools.
These include `git`, `coreutils` (for the `date` cmd), `nix` (used to generate
the package src sha256 hashes) and `semver-tool` (used to validate the semver
retrieved from git tags).

After running the script, you can use `git status` to see if any new manifests
have been generated. You can commit and open a PR with these changes at any
time, or simply wait for the next nightly `refresh-manifests` GitHub action
to run.

**Notes on refresh-manifests.sh**

- The script begins by declaring all FuelLabs repositories that we care about,
  followed by each unique package and which repository it is associated with.
  To declare new packages, see the
  [Adding Packages](./contributing/adding-packages.html) chapter.
- The script aims to be idempotent, i.e. even if you were to delete the entire
  `./manifests` directory and all its manifests, running the script again should
  reproduce the exact same directory with the same set of manifests, assuming
  the git history of each of the FuelLabs repos was not edited in some manner.
- Running the script can take a long time. This is because we scan each
  repository in its entirety multiple times - once while generating nightly
  manifests, and again while generating semver manifests.


# 2. Providing `package` flake outputs

TBC


[nix-flakes]: https://nixos.wiki/wiki/Flakes
