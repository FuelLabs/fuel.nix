# Providing Milestones

**fuel.nix** allows for declaring "milestones".

Milestones provide a way of pinning a significant set of hand-picked commits
across the Fuel ecosystem under a single named release.

Milestones are provided by the `./milestones.nix` file. As of writing this,
the file includes milestones for `beta-1`, `beta-2` and `beta-3`.

Each milestone is a mapping from a name to a set of repository commits, each of
which is used to select the set of package manifests used to generate package
outputs for the milestone.

Here's what the `beta-2` milestone looks like:

```nix
  beta-2 = {
    forc-explorer = "4bb7392eed085ee3a6795b98ea25392b3f41ade8";
    forc-wallet = "9473052e88048f58e8c4e1eba0ff88ef6a4cdd59";
    fuel-core = "49e4305fea691bbf293c606334e7b282a54393b3";
    fuel-indexer = "c2425c8b63f01ef1b540ff3e5832ebdc018b951d";
    sway = "c32b0759d25c0b515cbf535f9fb9b8e6fda38ff2";
  };
```

While [providing packages](./providing-packages.html), milestones are used to
provide a unique output for each package along with a dedicated package set.
E.g. the above `beta-2` milestone is used to provide `fuel-core-beta-2` and
`forc-beta-2` package aliases, as well as the extra `fuel-beta-2` package set.

## CI

To ensure we maintain availability of milestone binaries in the cache, we build
each of the milestones under the CI workflow.

Currently, the milestones are manually specified. As a result, they'll need
to be updated upon adding new milestones, or removed when they're no longer
officially supported.
