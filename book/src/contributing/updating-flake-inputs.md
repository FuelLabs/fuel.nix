# Updating Flake Inputs

Nix flakes can be thought of as a collection of pure functions that produce a
plan for how to provide packages, devShells and other outputs.

Any external inputs to these functions must be declared as a part of the flake
inputs. Apart from these, only files available within the flake's repository (or
[fetchers](https://nixos.org/manual/nixpkgs/stable/#chap-pkgs-fetchers) that can
verify reproducibility of the fetched content using a hash) may be used to
construct flake outputs.

Here's what **fuel.nix**'s flake inputs look like today:

```nix
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sway-vim-src = {
      url = "github:fuellabs/sway.vim";
      flake = false;
    };
    utils = {
      url = "github:numtide/flake-utils";
    };
  };
```

Our inputs include:

- `nixpkgs` - The main nix package repository, providing most packages you could
  imagine.
- `rust-overlay` - A nixpkgs overlay for providing more fine-grained control
  over selecting Rust versions, choosing components, etc. It can be thought of as
  a nix-esque version of rustup.
- `sway-vim-src` - Unlike the other fuel packages, we only provide the latest
  version of the sway-vim plugin. This input provides the repo for the plugin.
- `utils` - Some flake utility functions that make it a little easier to provide
  outputs for multiple different systems.

## Updating Inputs

Inputs are **locked** to a set of commits via the `flake.lock` file.
Occasionally it might be necessary to update nixpkgs or rust-overlay in order
to get access to some new version of Rust, a new openssl version with a security
patch, etc.

To update *all* inputs:

```console
nix flake update
```

To update a single input:

```console
nix flake lock --update-input nixpkgs
```

After updating, be sure to commit the changes to the lock file (CI should fail
if you forget). It's best to update inputs in a dedicated PR, as doing so may
have implications on the way package's are built.

### Cache Implications

It's worth keeping in mind that updating inputs will result in new derivations
for existing packages in the case that existing packages use something provided
by the updated input that might have changed. As a result, it's better to update
`nixpkgs` only as necessary.

A possible future solution to this might be to update nixpkgs versions in
the same way that we update Rust versions, i.e. using `patches.nix`. This may
require a bit of a refactor of `patches.nix` (e.g. fetch nixpkgs at pinned
commits internally using [`fetchFromGitHub`], rather than passing in `pkgs` as an
input), and would likely still require at least one version of nixpkgs as an
input in order to provide useful nix functions via `lib` outside of the package
outputs.

[`fetchFromGitHub`]: https://nixos.org/manual/nixpkgs/stable/#fetchfromgithub
