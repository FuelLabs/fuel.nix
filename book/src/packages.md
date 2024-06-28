# Packages


The `fuel.nix` flake provides the following packages:

| Package | Description |
| --- | --- |
| [`fuel-core`][fuel-core-repo] | The Fuel VM node client. |
| [`fuel-core-client`][fuel-core-repo] | A Fuel VM transaction client. |
| [`forc`][sway-repo] | The Fuel Orchestrator. Compiler, packaging and plugin support. |
| [`forc-client`][sway-repo] | Provides the `forc deploy` and `forc run` commands. |
| [`forc-crypto`][sway-repo] | A Forc plugin for hashing arbitrary data. |
| [`forc-debug`][sway-repo] | A Forc plugin for debugging via CLI and IDE. |
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

## Running Packages

You can run any of the above programs without installing them like so:

```
nix run github:fuellabs/fuel.nix#fuel-core
```

To run the latest nightly for a package, add `-nightly` to the end, e.g.

```
nix run github:fuellabs/fuel.nix#forc-nightly
```

Similarly, run the version of a package from a milestone with `-<milestone>`, e.g.

```
nix run github:fuellabs/fuel.nix#forc-lsp-beta-5
```
```
nix run github:fuellabs/fuel.nix#forc-wallet-beta-5
```

## Temporary Shells

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

$ nix shell github:fuellabs/fuel.nix#fuel-beta-5

# All beta-5 milestone `fuel` packages on `PATH`.
```

## Installing Packages

To install fuel packages persistently for the current user:

```console
nix profile install github:fuellabs/fuel.nix#fuel
```

To view whats installed for the current user:

```console
nix profile list
```

To upgrade all installed packages to their latest versions:

```console
nix profile upgrade
```

You can optionally specify a specific package to upgrade.

To remove an installed package:

```console
nix profile remove 3
```

where `3` is the index of the package when running `nix profile list`.

For more options around managing nix user profiles, see [the
docs](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-profile.html).

> **NOTE:** If a previous version of Nix was installed on the system, the
> `nix profile` command may not work due to an old symlink being present in $HOME.
> See [**this issue**](https://github.com/DeterminateSystems/nix-installer/issues/477).
> If you encounter this issue, you can remedy it by deleting the `~/.nix-profile`
> symlink so that the `nix profile` commands can recreate it with the correct
> path.


## Specifying Versions

To specify a specific version, append the semver or nightly date to the end:

```
nix run github:fuellabs/fuel.nix#forc-fmt-0-24-1
```
```
nix run github:fuellabs/fuel.nix#forc-fmt-0-24-3-nightly-2022-09-14
```

> **Note:** that when building an older version or nightly, they may no longer
> be available in the binary cache and may need to be rebuilt!

[forc-wallet-repo]: https://github.com/fuellabs/forc-wallet
[fuel-core-repo]: https://github.com/fuellabs/fuel-core
[fuel-indexer-repo]: https://github.com/fuellabs/fuel-indexer
[sway-repo]: https://github.com/fuellabs/sway
[sway-vim-repo]: https://github.com/fuellabs/sway.vim
