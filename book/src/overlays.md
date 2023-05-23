# Overlays

*This chapter is targeted to more experienced Nix or NixOS users who are looking
to use an "overlay" to merge the Fuel packages with an instance of
[nixpkgs](https://github.com/nixos/nixpkgs).*

Two nixpkgs overlays are provided (`fuel` and `fuel-nightly`) that allow for
"merging" the set of packages provided by this flake with nixpkgs.

Note that this makes the `sway-vim` plugin accessible via the `vimPlugins` set
following the nixpkgs convention, e.g. `nixpkgs.vimPlugins.sway-vim`.
