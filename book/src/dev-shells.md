# Dev Shells

**fuel.nix** also features a few `devShell`s that make it easy to drop into a
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
[the Overlays chapter](./overlays.html) and the [Nix Vim wiki](https://nixos.wiki/wiki/Vim)
for more details.
