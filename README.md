# fuel.nix

A Nix flake for the Fuel Labs ecosystem. https://fuel.network/

## System Requirements

Requires a recent version of [Nix][nix-manual] with [the "flakes" feature][nix-flakes] enabled.

## Packages

Includes the following packages:

| Package | Description |
| --- | --- |
| [`fuel-core`][fuel-core-repo] | The Fuel VM node client. |
| [`fuel-gql-cli`][fuel-core-repo] | A Fuel VM transaction client. |
| [`forc`][sway-repo] | The Fuel Orchestrator. Compiler, packaging and plugin support. |
| [`forc-client`][sway-repo] | Provides the `forc deploy` and `forc run` commands. |
| [`forc-explore`][sway-repo] | Runs the Fuel Explorer. |
| [`forc-fmt`][sway-repo] | The Sway code formatter. |
| [`forc-lsp`][sway-repo] | The Sway Language Server Protocol implementation. |
| [`forc-wallet`][forc-wallet-repo] | A Fuel Wallet CLI implementation. |
| [`sway-vim`][sway-vim-repo] | The Sway Vim plugin. |
| `fuel` | All of the above tools under a single package. |

If you have Nix installed with the "flakes" feature enabled, you can run any of
the above programs like so:

```
nix run github:mitchmindtree/fuel.nix#fuel-core
```

To run the latest nightly for a package, add `-nightly` to the end, e.g.

```
nix run github:mitchmindtree/fuel.nix#forc-nightly
```

To enter a temporary shell with all of the fuel packages available on `$PATH`,
you can use the following:

```
nix shell github:mitchmindtree/fuel.nix#fuel
```

When you `exit` the shell the tools will no longer be on the `PATH`.

The `nix shell` command is useful for maintaining isolated, temporary
environments and to avoid endlessly polluting your `PATH` with different
versions. E.g. in the following, we trivially switch between a stable fuel
toolchain and nightly toolchain:

```sh
$ nix shell github:mitchmindtree/fuel.nix#fuel

# All latest stable `fuel` packages on `PATH`.

$ exit

# No fuel packages on `PATH`

$ nix shell github:mitchmindtree/fuel.nix#fuel-nightly

# All latest nightly `fuel` packages on `PATH`.
```


To specify a specific version, append the semver or nightly date to the end:

```
nix run github:mitchmindtree/fuel.nix#forc-fmt-0.24.1
```
```
nix run github:mitchmindtree/fuel.nix#forc-fmt-0-24-3-nightly-2022-09-14
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
| `fuel-dev` | A shell ready for working with on any Fuel repo. |

You can enter a temporary dev shell like so:

```
nix develop github:mitchmindtree/fuel.nix#fuel-dev
```

Note that you can also enter a dev shell for individual packages. E.g. the
following enters a dev shell with the required environment for working on the
Sway language server implementation

```
nix develop github:mitchmindtree/fuel.nix#forc-lsp
```

Note that currently the vim plugin still needs to be installed separately. See
the "Overlay" section below and the [Nix Vim wiki](https://nixos.wiki/wiki/Vim)
for more details.

## Overlay

A nixpkgs overlay is provided that allows for "merging" the set of packages
provided by this flake with nixpkgs.

Note that this makes the `sway-vim` plugin accessible via the `vimPlugins` set
following the nixpkgs convention, e.g. `nixpkgs.vimPlugins.sway-vim`.

## Editor plugins

Currently this flake and its overlay only provide the `sway-vim` Vim plugin.

Contributions adding support for other editors/IDE plugins are more than
welcome.

## Packaging Sway Applications

*TODO: Provide a `forcPlatform` wrapper around `forc` and related plugins
inspired by nixpkgs' `rustPlatform`.*


[nix-manual]: https://nixos.org/manual/nix/stable/
[nix-flakes]: https://nixos.wiki/wiki/Flakes
[forc-wallet-repo]: https://github.com/fuellabs/forc-wallet
[fuel-core-repo]: https://github.com/fuellabs/fuel-core
[rust-overlay-repo]: https://github.com/oxalica/rust-overlay
[sway-repo]: https://github.com/fuellabs/sway
[sway-vim-repo]: https://github.com/fuellabs/sway.vim
