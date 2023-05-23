# fuel.nix

A Nix flake for the Fuel Labs ecosystem. https://fuel.network/

Each night at midnight (UTC) this repo is automatically updated with the latest
stable and nightly releases of all fuel packages. Builds are tested and cached
for both `x86_64-linux` and `x86_64-darwin` systems.

## System Requirements

Requires a recent version of [Nix][nix-manual] with [the "flakes"
feature][nix-flakes] enabled.

We also recommend enabling the Fuel Labs Nix cache hosted by
[cachix][fuellabs-cachix]. Otherwise, upon first use Nix will try to build all
of the packages from scratch which can take a long time!

On **NixOS**, we can enable the necessary features and our cache within our
NixOS configuration (i.e. `/etc/nixos/configuration.nix`) like so:

```nix
{
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      substituters = ["https://fuellabs.cachix.org"];
      trusted-public-keys = [
        "fuellabs.cachix.org-1:3gOmll82VDbT7EggylzOVJ6dr0jgPVU/KMN6+Kf8qx8="
      ];
    };
  };
}
```

On **non-NixOS** systems, you may add the following to your Nix configuration
file (e.g.  `/etc/nix/nix.conf`):

```conf
experimental-features = nix-command flakes
substituters = https://cache.nixos.org/ https://fuellabs.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= fuellabs.cachix.org-1:3gOmll82VDbT7EggylzOVJ6dr0jgPVU/KMN6+Kf8qx8=
```

On non-NixOS Linux systems, be sure to make sure that your user is part of the
`nixbld` group. Only this group has permissions to access the caches. You can
check if your user is a part of the group with the `groups` command. You can add
your user to the `nixbld` group with the following, replacing `user` with your
username:

```
$ sudo usermod -a -G nixbld user
```

## Packages

Includes the following packages:

| Package | Description |
| --- | --- |
| [`fuel-core`][fuel-core-repo] | The Fuel VM node client. |
| [`fuel-core-client`][fuel-core-repo] | A Fuel VM transaction client. |
| [`forc`][sway-repo] | The Fuel Orchestrator. Compiler, packaging and plugin support. |
| [`forc-client`][sway-repo] | Provides the `forc deploy` and `forc run` commands. |
| [`forc-doc`][sway-repo] | Sway API documentation generator. |
| [`forc-explore`][sway-repo] | Runs the Fuel Explorer. |
| [`forc-fmt`][sway-repo] | The Sway code formatter. |
| [`forc-index`][fuel-indexer-repo] | A forc plugin for working with the indexer. |
| [`forc-lsp`][sway-repo] | The Sway Language Server Protocol implementation. |
| [`forc-tx`][sway-repo] | Construct transactions with a CLI. |
| [`forc-wallet`][forc-wallet-repo] | A Fuel Wallet CLI implementation. |
| [`fuel-indexer`][fuel-indexer-repo] | An indexer for the Fuel blockchain. |
| [`sway-vim`][sway-vim-repo] | The Sway Vim plugin. |
| `fuel` | All of the above tools under a single package. |

If you have Nix installed with the "flakes" feature enabled, you can run any of
the above programs like so:

```
nix run github:fuellabs/fuel.nix#fuel-core
```

To run the latest nightly for a package, add `-nightly` to the end, e.g.

```
nix run github:fuellabs/fuel.nix#forc-nightly
```

Similarly, run the version of a package from a milestone with `-<milestone>`, e.g.

```
nix run github:fuellabs/fuel.nix#forc-lsp-beta-3
```
```
nix run github:fuellabs/fuel.nix#forc-wallet-beta-1
```

To enter a temporary shell with all of the fuel packages available on `$PATH`,
you can use the following:

```
nix shell github:fuellabs/fuel.nix#fuel
```

When you `exit` the shell the tools will no longer be on the `PATH`.

The `nix shell` command is useful for maintaining isolated, temporary
environments and to avoid endlessly polluting your `PATH` with different
versions. E.g. in the following, we trivially switch between a stable fuel
toolchain and nightly toolchain:

```sh
$ nix shell github:fuellabs/fuel.nix#fuel

# All latest stable `fuel` packages on `PATH`.

$ exit

# No fuel packages on `PATH`

$ nix shell github:fuellabs/fuel.nix#fuel-nightly

# All latest nightly `fuel` packages on `PATH`.

$ exit

# No fuel packages on `PATH`

$ nix shell github:fuellabs/fuel.nix#fuel-beta-3

# All beta-3 milestone `fuel` packages on `PATH`.
```


To specify a specific version, append the semver or nightly date to the end:

```
nix run github:fuellabs/fuel.nix#forc-fmt-0.24.1
```
```
nix run github:fuellabs/fuel.nix#forc-fmt-0-24-3-nightly-2022-09-14
```

## Dev Shells

This flake also features a few `devShell`s that make it easy to drop into a
development shell for working on the fuel packages. They allow you to drop into
a temporary shell with all the tools and environment variables required to build
the various fuel projects yourself.

| Dev Shell | Description |
| --- | --- |
| `fuel-core-dev` | A shell for working on the `fuel-core` repo. |
| `sway-dev` | A shell for working on the `sway` repo. |
| `fuel-indexer-dev` | A shell for working on the `fuel-indexer` repo. |
| `fuel-dev` | A shell ready for working with on any Fuel repo. |

You can enter a temporary dev shell like so:

```
nix develop github:fuellabs/fuel.nix#fuel-dev
```

Note that you can also enter a dev shell for individual packages. E.g. the
following enters a dev shell with the required environment for working on the
Sway language server implementation

```
nix develop github:fuellabs/fuel.nix#forc-lsp
```

Note that currently the vim plugin still needs to be installed separately. See
the "Overlay" section below and the [Nix Vim wiki](https://nixos.wiki/wiki/Vim)
for more details.

## Overlay

Two nixpkgs overlays are provided (`fuel` and `fuel-nightly`) that allow for
"merging" the set of packages provided by this flake with nixpkgs.

Note that this makes the `sway-vim` plugin accessible via the `vimPlugins` set
following the nixpkgs convention, e.g. `nixpkgs.vimPlugins.sway-vim`.

## Editor plugins

Currently this flake and its overlay only provide the `sway-vim` Vim plugin.

Contributions adding support for other editors/IDE plugins are more than
welcome.

## Packaging Sway Applications

*TODO: Provide a `forcPlatform` wrapper around `forc` and related plugins
inspired by nixpkgs' `rustPlatform`.*


[cachix-docs]: https://docs.cachix.org/
[forc-wallet-repo]: https://github.com/fuellabs/forc-wallet
[fuel-core-repo]: https://github.com/fuellabs/fuel-core
[fuel-indexer-repo]: https://github.com/fuellabs/fuel-indexer
[fuellabs-cachix]: https://app.cachix.org/cache/fuellabs
[nix-flakes]: https://nixos.wiki/wiki/Flakes
[nix-manual]: https://nixos.org/manual/nix/stable/
[rust-overlay-repo]: https://github.com/oxalica/rust-overlay
[sway-repo]: https://github.com/fuellabs/sway
[sway-vim-repo]: https://github.com/fuellabs/sway.vim
