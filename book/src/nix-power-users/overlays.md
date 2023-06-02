# Overlays

Two nixpkgs [overlays] are provided (`fuel` and `fuel-nightly`) that allow for
"merging" the set of packages provided by this flake with nixpkgs.

Note that this makes the `sway-vim` plugin accessible via the `vimPlugins` set
following the nixpkgs convention, e.g. `nixpkgs.vimPlugins.sway-vim`.

[overlays]: https://nixos.wiki/wiki/Overlays
