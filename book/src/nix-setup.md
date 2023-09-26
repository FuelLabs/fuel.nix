# Nix Setup

**[Nix]** is a package manager with a focus on
reproducibility and reliability. Fuel Labs leverages Nix to provide a simple
way to natively install the ecosystem tooling along with any necessary system
dependencies and environment setup.

This chapter provides a more detailed look at the Nix installation process,
describes how to setup an existing Nix configuration, and covers how to
uninstall Nix and its installed packages if necessary.

## Install Nix

To recap our [Quickstart](./quickstart.md), we can install Nix with the
following command:

```console
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix/tag/v0.9.0 | sh -s -- install --extra-conf "extra-substituters = https://fuellabs.cachix.org" --extra-conf "extra-trusted-public-keys = fuellabs.cachix.org-1:3gOmll82VDbT7EggylzOVJ6dr0jgPVU/KMN6+Kf8qx8="
```

This uses the [`nix-installer` tool by Determinate Systems][nix-installer] to
install Nix with the [**flakes**][nix-flakes] and [**nix-command**][nix-command]
features enabled, and provides `--extra-conf` flags that enable [the Fuel Labs
binary cache][fuel-labs-cache].

> **Note:** Without a binary cache, Nix will build everything from source on
> first use. This can take a long time! The fuel.nix repo CI builds all channels
> (published, nightly, milestones) and provides a cache so you don't have to.

The installer will first present an installation plan before prompting
to continue. Feel free to review or prompt for further explanation before
proceeding with installation.

After continuing, Nix installation should complete within a few seconds. Be sure
to open a new terminal before using `nix`.

## Configuring an Existing Nix Installation

If you're an existing Nix user you can enable the necessary features along
with the Fuel Labs binary cache with the following additions to your Nix
configuration (`/etc/nix/nix.conf`):

```
experimental-features = nix-command flakes
extra-substituters = https://fuellabs.cachix.org
extra-trusted-public-keys = fuellabs.cachix.org-1:3gOmll82VDbT7EggylzOVJ6dr0jgPVU/KMN6+Kf8qx8=
```

## Configuring NixOS

Similarly, if you're an existing [NixOS](https://nixos.org/) user, you can
update your nixos configuration with the following:

```nix
{
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      extra-substituters = ["https://fuellabs.cachix.org"];
      extra-trusted-public-keys = [
        "fuellabs.cachix.org-1:3gOmll82VDbT7EggylzOVJ6dr0jgPVU/KMN6+Kf8qx8="
      ];
    };
  };
}
```

## Trouble Shooting

### Nix command not available

The daemon that makes nix available to your shell is not run automatically after installation. You'll need to either manually start it in your shell instance with `nix daemon` or open a new instance of your shell. If it persists, log out, log back in and open a new terminal.

### Nix isn't using the Fuel cache

In some cases, usually in existing nix installations, nix may have trouble finding or using the cache. This could happen for a few reasons:

#### Confirm you are a trusted user:

The user the request is coming from may not be a trusted user, in which case some permissions may be missing to use parts of the configuration.
There is a great example of this in the Nix discourse which can be found [here][trusted-users] that also provides a solution if you want certain features available to untrusted users.

#### The `extra-substitutors` section is overlooked:

`extra-substitutors` appends additional caches to those already specified by `substitutors`, and will silently ignore them when they are attempted to be used by unprivileged users. If the output of `nix show-config` does not show the Fuel cache in `extra-substitutors` after [confirming you are a trusted user](#confirm-you-are-a-trusted-user), you may need to restart your shell. If this still does not solve the issue, try adding the Fuel cachix link to `substitutors` instead, separating any existing substitutors by whitespace.

#### Negative caching:

If you ran into any of the previous problems, which made your system build a derivation from source, you may experience [negative caching][negative-caching] in which case you'll need to [reset the lookup cache][reset-lookup-cache] that nix uses to check if a cache doesn't exist.

If a problem persists after trying the above please [open an issue][open-an-issue].

## Uninstall Everything

If you installed Nix using the Determinate Systems nix-installer tool as
described in this guide, you can uninstall Nix along with all nix-installed
packages with the following:

```console
/nix/nix-installer uninstall
```

[Nix]: https://nixos.org/
[fuel-labs-cache]: https://app.cachix.org/cache/fuellabs
[nix-flakes]: https://nixos.wiki/wiki/Flakes
[nix-command]: https://nixos.wiki/wiki/Nix_command
[nix-installer]: https://github.com/DeterminateSystems/nix-installer
[trusted-users]: https://discourse.nixos.org/t/nix-flake-and-trusted-users/8882
[negative-caching]: https://en.wikipedia.org/wiki/Negative_cache
[reset-lookup-cache]: https://nix.dev/recipes/faq#how-do-i-force-nix-to-re-check-whether-something-exists-at-a-binary-cache
[open-an-issue]: https://github.com/FuelLabs/fuel.nix/issues/new
