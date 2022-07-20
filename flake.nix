{
  description = ''
    A Nix flake for the Fuel Labs ecosystem.
  '';

  inputs = {
    fuel-core-src = {
      url = "github:fuellabs/fuel-core";
      flake = false;
    };
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sway-src = {
      url = "github:fuellabs/sway";
      flake = false;
    };
    sway-vim-src = {
      url = "github:fuellabs/sway.vim";
      flake = false;
    };
    utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = inputs: let
    utils.supportedSystems = [
      # "aarch64-linux"
      # "i686-linux"
      "x86_64-linux"
      # "aarch64-darwin"
      # "x86_64-darwin"
    ];
    utils.eachSupportedSystem =
      inputs.utils.lib.eachSystem utils.supportedSystems;

    mkPackages = pkgs: rust-platform: rec {
      fuel-core = rust-platform.buildRustPackage {
        name = "fuel-core";
        version = "master";
        src = inputs.fuel-core-src;
        cargoSha256 = "sha256-kyMRWIRNxOohrloMrbHP526sxqqyt7zSBXW37y8rhLo=";
        nativeBuildInputs = [
          rust-platform.rust.cargo
          rust-platform.rust.rustc
          pkgs.pkg-config
          pkgs.clang
          pkgs.libclang
        ];
        buildInputs = [
          pkgs.grpc-tools
          pkgs.openssl
        ];
        LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
        PROTOC = "${pkgs.grpc-tools}/bin/protoc";
      };

      # forc = {};
      # forc-explore = {};
      # forc-fmt = {};
      # forc-lsp = {};

      sway-vim = pkgs.vimUtils.buildVimPluginFrom2Nix {
        pname = "sway-vim";
        version = "master";
        src = inputs.sway-vim-src;
        meta = {
          homepage = "https://github.com/fuellabs/sway.vim";
          license = pkgs.lib.licenses.mit;
        };
      };
    };

    overlays = rec {
      fuel = final: prev: let
        fuelpkgs = mkPackages prev;
      in {
        inherit (fuelpkgs) fuel-core forc forc-explore forc-fmt forc-lsp;
        vimPlugins = prev.vimPlugins // {inherit (fuelpkgs) sway-vim;};
      };
      default = fuel;
    };

    mkDevShells = pkgs: rust-platform: fuelpkgs: rec {
      fuel-core = pkgs.mkShell {
        name = "fuel-core";
        version = "master";
        nativeBuildInputs = [
          rust-platform.rust.cargo
          rust-platform.rust.rustc
          pkgs.pkg-config
          pkgs.clang
          pkgs.libclang
        ];
        buildInputs = [
          pkgs.grpc-tools
          pkgs.openssl
        ];
        LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
        PROTOC = "${pkgs.grpc-tools}/bin/protoc";
      };

      # fuel-core = pkgs.mkShell {
      #   name = "fuel-core-dev";
      #   buildInputs = [
      #     # rust-platform.rust
      #   ];
      # };
      # sway = pkgs.mkShell {
      #   name = "sway-dev";
      #   buildInputs = [
      #     # fuelpkgs.fuel-core
      #     # rust-platform.rust
      #   ];
      # };
      # # TODO: All dev shells combined.
      # fuel = pkgs.mkShell {
      #   name = "fuel-dev";
      # };
      # default = fuel;
    };

    mkOutput = system: let
      overlays = [inputs.rust-overlay.overlays.default];
      pkgs = import inputs.nixpkgs {inherit overlays system;};
      rust = pkgs.rust-bin.stable.latest.default;
      rust-platform = pkgs.makeRustPlatform { rustc = rust; cargo = rust; };
    in rec {
      packages = mkPackages pkgs rust-platform;
      devShells = mkDevShells pkgs rust-platform packages;
      formatter = pkgs.alejandra;
    };

    # The output for each system.
    systemOutputs = utils.eachSupportedSystem mkOutput;
  in
    # Merge the outputs and overlays.
    systemOutputs // {inherit overlays utils;};
}
