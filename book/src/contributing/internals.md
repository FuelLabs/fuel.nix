# Internals

At a very high level, **fuel.nix** does the following:

1. [**Generate unique "manifests" for each version of each package**](./internals/generating-manifests.html)
   every night at 00:00 UTC under the `./manifests` directory using a CI action
   that runs the `./scripts/refresh-manifests.sh` script.
2. [**Provide `package` flake outputs**](./internals/providing-packages.html)
   (e.g. `forc-0-20-0`, `fuel-core-0-18-0-nightly-2023-04-29`) by collecting,
   filtering (`filters.nix`) and patching (`patches.nix`) all manifests. Also
   provide package **sets** for the latest semver releases and nightlies e.g.
   (`fuel-latest`, `fuel-nightly`).
3. [**Provide a special set of "milestone" packages**](./internals/providing-milestones.html)
   (e.g. `forc-wallet-testnet`) and package sets (e.g. `fuel-testnet`) by finding
   packages that match the commits specified in `milestones.nix`.
4. **Provide `devShell`s** to assist working on the fuel repos by collecting all
   of the inputs to their associated packages and inheriting their environment
   variables.

Click on the links above to dive into more details on each step.

Alternatively, for a quick look at adding or updating packages:

- [**Adding Packages**](./adding-packages.html)
- [**Updating Packages**](./updating-packages.html)
- [**Updating Flake Inputs**](./updating-flake-inputs.html)
