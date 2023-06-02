# Nix Setup

[**Nix**](https://nixos.org/) is a package manager with a focus on
reproducibility and reliability. Fuel Labs leverages Nix to provide a simple
way to natively install the ecosystem tooling along with any necessary system
dependencies and environment setup.

This chapter provides a more detailed look at the Nix installation process,
describes how to setup an existing Nix configuration, and covers how to
uninstall Nix and its installed packages if necessary.

## Install Nix

To recap our [Quick Start](./quick-start.html), we can install Nix with the
following command:

```console
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix/tag/v0.9.0 | sh -s -- install --extra-conf "extra-substituters = https://fuellabs.cachix.org" --extra-conf "extra-trusted-public-keys = fuellabs.cachix.org-1:3gOmll82VDbT7EggylzOVJ6dr0jgPVU/KMN6+Kf8qx8="
```

This uses the [`nix-installer` tool by Determinate Systems](nix-installer) to
install Nix with the [**flakes**](nix-flakes) and [**nix-command**](nix-command)
features enabled, and provides `--extra-conf` flags that enable [the Fuel Labs
binary cache](fuel-labs-cache).

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

## Uninstall Everything

If you installed Nix using the Determinate Systems nix-installer tool as
described in this guide, you can uninstall Nix along with all nix-installed
packages  with the following:

```console
/nix/nix-installer uninstall
``` 

[fuel-labs-cache]: https://app.cachix.org/cache/fuellabs
[nix-flakes]: https://nixos.wiki/wiki/Flakes
[nix-command]: https://nixos.wiki/wiki/Nix_command
[nix-installer]: https://github.com/DeterminateSystems/nix-installer
