# Internals

At a very high level, **fuel.nix** does the following:

1. [**Generate unique "manifests" for each version of each package**](./generating-manifests.md)
   every night at 00:00 UTC under the `./manifests` directory using a CI action
   that runs the `./scripts/refresh-manifests.sh` script.
2. [**Provide `package` flake outputs**](./providing-packages.md)
   (e.g. `forc-0-20-0`, `fuel-core-0-18-0-nightly-2023-04-29`) by collecting,
   filtering (`filters.nix`) and patching (`patches.nix`) all manifests. Also
   provide package **sets** for the latest semver releases and nightlies e.g.
   (`fuel-latest`, `fuel-nightly`).
3. [**Provide a special set of "milestone" packages**](./providing-milestones.md)
   (e.g. `forc-wallet-beta-2`) and package sets (e.g. `fuel-beta-3`) by finding
   packages that match the commits specified in `milestones.nix`.
4. **Provide `devShell`s** to assist working on the fuel repos by collecting all
   of the inputs to their associated packages and inheriting their environment
   variables.

Click on the links above to dive into more details on each step.

Alternatively, for a quick look at adding or updating packages:

- [Adding Packages](../adding-packages.md)
- [Updating Packages](../updating-packages.md)
- [Updating Flake Inputs](../updating-flake-inputs.md)