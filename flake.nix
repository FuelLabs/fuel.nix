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
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    utils.eachSupportedSystem =
      inputs.utils.lib.eachSystem utils.supportedSystems;

    mkPackages = pkgs: rust-platform: rec {
      fuel-core = rust-platform.buildRustPackage {
        name = "fuel-core";
        version = "master";
        src = inputs.fuel-core-src;
        cargoLock.lockFile = "${inputs.fuel-core-src}/Cargo.lock";
        buildAndTestSubdir = "fuel-core";
        nativeBuildInputs = [
          pkgs.clang
          pkgs.pkg-config
          rust-platform.rust.cargo
          rust-platform.rust.rustc
        ];
        LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
        meta = {
          homepage = "https://github.com/fuellabs/fuel-core";
        };
      };

      fuel-gql-cli = rust-platform.buildRustPackage {
        name = "fuel-gql-cli";
        version = "master";
        src = inputs.fuel-core-src;
        cargoLock.lockFile = "${inputs.fuel-core-src}/Cargo.lock";
        buildAndTestSubdir = "fuel-client";
        nativeBuildInputs = [
          rust-platform.rust.cargo
          rust-platform.rust.rustc
        ];
        meta = {
          homepage = "https://github.com/fuellabs/fuel-core";
        };
      };

      forc = rust-platform.buildRustPackage {
        name = "forc";
        version = "master";
        src = inputs.sway-src;
        cargoHash = "sha256-Va6MqFiYxMn3NWU0xOKOlGec/Qus4Z3dSSCrUid7cKY=";
        buildAndTestSubdir = "forc";
        nativeBuildInputs = [
          pkgs.perl # for openssl-sys
          pkgs.pkg-config # for openssl-sys
          rust-platform.rust.cargo
          rust-platform.rust.rustc
        ];
        meta = {
          homepage = "https://github.com/fuellabs/sway";
          license = pkgs.lib.licenses.asl20;
        };
      };

      forc-explore = rust-platform.buildRustPackage {
        name = "forc-explore";
        version = "master";
        src = inputs.sway-src;
        cargoHash = "sha256-3xnrgnEJFEWQ1JS1RwuNKvYP68SFyOPrnBxr++1XL4k=";
        buildAndTestSubdir = "forc-plugins/forc-explore";
        nativeBuildInputs = [
          rust-platform.rust.cargo
          rust-platform.rust.rustc
        ];
        meta = {
          homepage = "https://github.com/fuellabs/sway";
          license = pkgs.lib.licenses.asl20;
        };
      };

      forc-fmt = rust-platform.buildRustPackage {
        name = "forc-fmt";
        version = "master";
        src = inputs.sway-src;
        cargoHash = "sha256-nufph2fKJs6IjAH8flxHuh4emCo2o8Kr/T1hh2oW3DI=";
        buildAndTestSubdir = "forc-plugins/forc-fmt";
        nativeBuildInputs = [
          rust-platform.rust.cargo
          rust-platform.rust.rustc
        ];
        meta = {
          homepage = "https://github.com/fuellabs/sway";
          license = pkgs.lib.licenses.asl20;
        };
      };

      forc-lsp = rust-platform.buildRustPackage {
        name = "forc-lsp";
        version = "master";
        src = inputs.sway-src;
        cargoHash = "sha256-bc/Xr0aBdZ+xoR0Ij72ItaoGB3X+v7cOGW+um3SCJiQ=";
        buildAndTestSubdir = "forc-plugins/forc-lsp";
        nativeBuildInputs = [
          pkgs.perl # for openssl-sys
          pkgs.pkg-config # for openssl-sys
          rust-platform.rust.cargo
          rust-platform.rust.rustc
        ];
        meta = {
          homepage = "https://github.com/fuellabs/sway";
          license = pkgs.lib.licenses.asl20;
        };
      };

      sway-vim = pkgs.vimUtils.buildVimPluginFrom2Nix {
        pname = "sway-vim";
        version = "master";
        src = inputs.sway-vim-src;
        meta = {
          homepage = "https://github.com/fuellabs/sway.vim";
          license = pkgs.lib.licenses.mit;
        };
      };

      fuel = pkgs.symlinkJoin {
        name = "fuel";
        paths = [
          fuel-core
          fuel-gql-cli
          forc
          forc-explore
          forc-fmt
          forc-lsp
        ];
      };

      default = fuel;
    };

    overlays = rec {
      fuel = final: prev: let
        fuelpkgs = mkPackages prev;
      in {
        inherit (fuelpkgs) fuel-core fuel-gql-cli forc forc-explore forc-fmt forc-lsp;
        vimPlugins = prev.vimPlugins // {inherit (fuelpkgs) sway-vim;};
      };
      default = fuel;
    };

    mkDevShells = pkgs: rust-platform: fuelpkgs: rec {
      fuel-dev = pkgs.mkShell {
        name = "fuel-dev";
        inputsFrom = pkgs.lib.attrValues fuelpkgs;
        buildInputs = [ pkgs.grpc-tools ];
        inherit (fuelpkgs.fuel-core) LIBCLANG_PATH;
        PROTOC = "${pkgs.grpc-tools}/bin/protoc";
      };
      default = fuel-dev;
    };

    mkOutput = system: let
      overlays = [inputs.rust-overlay.overlays.default];
      pkgs = import inputs.nixpkgs {inherit overlays system;};
      rust = pkgs.rust-bin.stable.latest.default;
      rust-platform = pkgs.makeRustPlatform {
        rustc = rust;
        cargo = rust;
      };
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
