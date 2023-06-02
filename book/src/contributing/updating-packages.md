# Updating Packages

Every now and then, a new nightly or published version of an upstream package
may add some new dependency or build environment requirement.

In order to avoid breaking older packages or invalidating the cache for existing
versions, we can make the necessary changes for new versions by adding a new
patch to `./patches.nix`.

See the [Patching
Manifests](./internals/providing-packages.html#patching-manifests) section for
details.
