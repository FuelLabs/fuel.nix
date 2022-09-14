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

If you have Nix installed with the "flakes" feature enabled, you can run the
above programs like so:

```
nix run github:mitchmindtree/fuel.nix#fuel-core
```

For now this flake simply pins the repo of each respective tool's master branch.
The future goal is to allow for selecting specific versions or following a
particular channel (e.g. nightly, stable) akin to [oxalica's
rust-overlay][rust-overlay-repo].

*TODO: Add fuel-indexer, forc-wallet, any other fuel tools/applications.*

## Dev Shell

This flake features a `fuel-dev` devShell. It allows for trivially entering a
shell that includes all of the above package dependencies available on the PATH.
This is useful for developers working *on* the sway tools.

If you have Nix installed with the "flakes" feature enabled, you can enter this
shell with:

```
nix develop github:mitchmindtree/fuel.nix#fuel-dev
```

When you `exit` the shell these tools will no longer be on the `PATH`.

Note that currently the vim plugin still needs to be installed separately. See
the "Overlay" section below and the [Nix Vim wiki](https://nixos.wiki/wiki/Vim)
for more details.

*TODO: Provide a `fuel` devShell that provides all of the above packages
directly under a single shell for developers building applications with the Fuel
tools. This should be the default devShell.*

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
