# Quickstart

Let's install both Nix and the latest full suite of Fuel tools in just two
commands.

## Install Nix

Nix is a package manager with a focus on reproducibility and reliability. We can
install it and enable the Fuel Labs binary cache with the following:

```console
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix/tag/v0.9.0 | sh -s -- install --extra-conf "extra-substituters = https://fuellabs.cachix.org" --extra-conf "extra-trusted-public-keys = fuellabs.cachix.org-1:3gOmll82VDbT7EggylzOVJ6dr0jgPVU/KMN6+Kf8qx8="
```

> **Note:** For more details on Nix installation or how to configure an existing
> Nix or NixOS installation, see the detailed
> [**Nix Setup**][nix setup] chapter.

## Install Fuel

After installing Nix, open a new terminal and install the stable Fuel toolchain
in a temporary shell with the following:

```console
nix shell github:fuellabs/fuel.nix#fuel
```

This will download the latest semver release of `fuel-core`, `forc`, and a suite
of other tools from the Fuel Labs cache into the local `/nix/store` cache and
"install" them to `PATH` for the duration of the current shell.

Let's check installation worked:

```console
fuel-core --version
```

Should return:

```console
> fuel-core 0.18.1
```

In the case of forc:

```console
forc --version
```

Should return:

```console
> forc 0.39.0
```

> **Note:** If you have previously installed Fuel tools using `cargo`, `fuelup`
> or some other means, it is recommended to double check your `PATH` to make
> sure you are using those installed by Nix.
>
> ```console
> echo $PATH
> ```
>
> Your console will always use the first version of an executable that appears
> in your `PATH`.

Now we're ready to build with Fuel!

We can `exit` the current shell to remove the tools from our `PATH` as if they
were never installed.

## Diving Deeper

To find out how to install tools persistently for the current user, how to
install different toolchain channels (nightly, beta-3, etc), how to install
individual components, along with a whole suite of other options, see [**the
Packages chapter**](./packages.md).

For more details on installing Nix or configuring an existing Nix or NixOS
installation, see [**the Nix Setup chapter**][nix setup].

If you are content with the installation, see the
**[Documentation Portal]**
for more details on how to build with Fuel!

[nix setup]: ./nix-setup.md
[Documentation Portal]: https://docs.fuel.network/