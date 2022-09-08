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
      "x86_64-linux"
      "aarch64-linux"
      "i686-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    utils.eachSupportedSystem =
      inputs.utils.lib.eachSystem utils.supportedSystems;

    # Collect the manifests, one for each package that we will construct.
    lib.manifests = pkgs: rust-platform: rec {
      # The set of manually defined manifest filters to be applied.
      filters = [
        (m: m.pname != "fuel-core" || pkgs.lib.versionAtLeast m.version "0.9.0")
        (m: m.pname != "fuel-gql-cli" || pkgs.lib.versionAtLeast m.version "0.9.0")
        (m: m.pname != "forc" || pkgs.lib.versionAtLeast m.version "0.19.0")
        (m: m.pname != "forc-explore" || pkgs.lib.versionAtLeast m.version "0.19.0")
        (m: m.pname != "forc-fmt" || pkgs.lib.versionAtLeast m.version "0.19.0")
        (m: m.pname != "forc-lsp" || pkgs.lib.versionAtLeast m.version "0.19.0")
        (m: m.pname != "forc-wallet" || pkgs.lib.versionAtLeast m.version "0.1.0")
      ];

      # Returns true if the given manifest passes all our filters.
      filter = m: pkgs.lib.all (f: f m) filters;

      # Patches are applied if their condition is met in the order they are defined in this list.
      patches = [
        {
          condition = m: true;
          patch = m: {
            cargoLock.lockFile = "${m.src}/Cargo.lock";
            nativeBuildInputs = [
              rust-platform.rust.cargo
              rust-platform.rust.rustc
            ];
            meta.homepage = m.src.gitRepoUrl;
            meta.platforms = utils.supportedSystems;
          };
        }
        {
          condition = m:
            pkgs.lib.any (url: m.src.gitRepoUrl == url) [
              "https://github.com/fuellabs/sway"
              "https://github.com/fuellabs/fuel-core"
            ];
          patch = m: {
            buildAndTestSubdir = m.pname;
          };
        }
        {
          condition = m: m.src.gitRepoUrl == "https://github.com/fuellabs/sway" && pkgs.lib.versionAtLeast m.version "0.19.0" && m.date < "2022-09-08";
          patch = m: {
            cargoLock.outputHashes = {
              "mdbook-0.4.20" = "sha256-hNyG2DVD1KFttXF4m8WnfoxRjA0cghA7NoV5AW7wZrI=";
            };
            meta.license = pkgs.lib.licenses.asl20;
          };
        }
        {
          condition = m: m.pname == "fuel-core";
          patch = m: {
            nativeBuildInputs =
              m.nativeBuildInputs
              ++ [
                pkgs.clang
                pkgs.pkg-config
              ];
            LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
          };
        }
        {
          condition = m: m.pname == "fuel-gql-cli";
          patch = m: {
            buildAndTestSubdir = "fuel-client";
          };
        }
        {
          condition = m: m.pname == "forc";
          patch = m: {
            nativeBuildInputs = [
              pkgs.perl # for openssl-sys
              pkgs.pkg-config # for openssl-sys
            ];
          };
        }
        {
          condition = m: m.pname == "forc-explore";
          patch = m: {
            buildAndTestSubdir = "forc-plugins/${m.pname}";
          };
        }
        {
          condition = m: m.pname == "forc-fmt";
          patch = m: {
            buildAndTestSubdir = "forc-plugins/${m.pname}";
          };
        }
        {
          condition = m: m.pname == "forc-lsp";
          patch = m: {
            buildAndTestSubdir = "forc-plugins/${m.pname}";
            nativeBuildInputs = [
              pkgs.perl # for openssl-sys
              pkgs.pkg-config # for openssl-sys
            ];
          };
        }
        {
          condition = m: m.pname == "forc-wallet" && m.version == "0.1.0";
          patch = m: {
            cargoPatches = [
              ./patch/forc-wallet-0.1.0-update-lock.patch
            ];
            cargoHash = "sha256-LXQaPcpf/n1RRFTQXAP6PexfEI67U2Z5OOW5DzNJvX8=";
            cargoLock = null;
          };
        }
      ];

      # Apply all `patches` whose conditions are met by the given manifest.
      patch = let
        filtered = m: pkgs.lib.filter (p: p.condition m) patches;
        apply = m: p: pkgs.lib.recursiveUpdate m (p.patch m);
      in
        m: pkgs.lib.foldl apply m (filtered m);

      # Load each manifest file and construct the attributes.
      manifest = filename: let
        fileattrs = import (./manifests + "/${filename}");
      in {
        inherit (fileattrs) pname version date;
        src = pkgs.fetchgit {
          inherit (fileattrs) url rev sha256;
        };
      };

      # Read the manifest files.
      filenames = builtins.attrNames (builtins.readDir ./manifests);

      # Filter and patch the published package manifests.
      published = rec {
        fnames = builtins.filter (n: !(pkgs.lib.hasInfix "nightly" n)) filenames;
        all = map manifest fnames;
        filtered = ms: builtins.filter filter ms;
        patched = ms: map patch ms;
        prepared = patched (filtered all);
      };

      # Filter and patch the nightly package manifests.
      nightly = rec {
        fnames = builtins.filter (n: pkgs.lib.hasInfix "nightly" n) filenames;
        all = map manifest fnames;
        filtered = ms: builtins.filter filter ms;
        patched = ms: map patch ms;
        prepared = patched (filtered all);
      };

      # Find the latest published and nightly version for each package.
      latest = let
        update = m: acc:
          acc
          // {
            "${m.pname}" =
              if builtins.hasAttr m.pname acc && pkgs.lib.versionAtLeast acc."${m.pname}".version m.version && acc."${m.pname}".date >= m.date
              then acc."${m.pname}"
              else m;
          };
        map-published = name: v: pkgs.lib.nameValuePair (name + "-latest") v;
        map-nightly = name: v: pkgs.lib.nameValuePair (name + "-nightly") v;
        fold-published = pkgs.lib.foldr update {} published.prepared;
        fold-nightly = pkgs.lib.foldr update {} nightly.prepared;
      in {
        published = pkgs.lib.mapAttrs' map-published fold-published;
        nightly = pkgs.lib.mapAttrs' map-nightly fold-nightly;
      };

      # Construct the default packages as aliases of the latest versions.
      defaults = pkgs.lib.mapAttrs' (n: v: pkgs.lib.nameValuePair (pkgs.lib.removeSuffix "-latest" n) v) latest.published;
    };

    # Generate the published packages from the `manifests` directory.
    mkPublishedPackages = pkgs: rust-platform: let
      manifests = lib.manifests pkgs rust-platform;
      packageName = manifest: builtins.replaceStrings ["."] ["-"] "${manifest.pname}-${manifest.version}";
      packageNameNightly = manifest: "${packageName manifest}-nightly-${manifest.date}";
      packageAttr = manifest: {
        name = packageName manifest;
        value = rust-platform.buildRustPackage manifest;
      };
      packageAttrNightly = manifest: {
        name = packageNameNightly manifest;
        value = rust-platform.buildRustPackage manifest;
      };
      packages-published = builtins.listToAttrs (map packageAttr manifests.published.prepared);
      packages-nightly = builtins.listToAttrs (map packageAttrNightly manifests.nightly.prepared);
      packages-latest = pkgs.lib.mapAttrs (n: manifest: rust-platform.buildRustPackage manifest) manifests.latest.published;
      packages-latest-nightly = pkgs.lib.mapAttrs (n: manifest: rust-platform.buildRustPackage manifest) manifests.latest.nightly;
      packages-default = pkgs.lib.mapAttrs (n: manifest: rust-platform.buildRustPackage manifest) manifests.defaults;
    in
      packages-published
      // packages-nightly
      // packages-latest
      // packages-latest-nightly
      // packages-default
      // rec {
        fuel-latest = pkgs.symlinkJoin {
          name = "fuel-latest";
          paths = pkgs.lib.attrValues packages-latest;
        };
        fuel = fuel-latest;
        default = fuel;
      };

    mkPackages = pkgs: rust-platform: rec {
      refresh-manifests = pkgs.writeShellApplication {
        name = "refresh-manifests";
        runtimeInputs = [
          pkgs.git # Used to fetch the fuel repos.
          pkgs.nix # Used to generate the package src sha256 hashes.
          pkgs.semver-tool # Validate semver retrieved from git tags.
        ];
        checkPhase = ""; # Temporarily disable check phase while devving.
        text = builtins.readFile ./script/refresh-manifests.sh;
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
      fuel-core-dev = pkgs.mkShell {
        name = "fuel-core-dev";
        inputsFrom = with fuelpkgs; [fuel-core fuel-gql-cli];
        buildInputs = [pkgs.grpc-tools];
        inherit (fuelpkgs.fuel-core) LIBCLANG_PATH;
        PROTOC = "${pkgs.grpc-tools}/bin/protoc";
      };

      sway-dev = pkgs.mkShell {
        name = "sway-dev";
        inputsFrom = with fuelpkgs; [forc forc-explore forc-fmt forc-lsp];
        buildInputs = with fuelpkgs; [fuel-core fuel-gql-cli];
      };

      fuel-dev = pkgs.mkShell {
        name = "fuel-dev";
        inputsFrom = [fuel-core-dev sway-dev];
        inherit (fuel-core-dev) LIBCLANG_PATH PROTOC;
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
      packages = mkPackages pkgs rust-platform // mkPublishedPackages pkgs rust-platform;
      devShells = mkDevShells pkgs rust-platform packages;
      formatter = pkgs.alejandra;
    };

    # The output for each system.
    systemOutputs = utils.eachSupportedSystem mkOutput;
  in
    # Merge the outputs and overlays.
    systemOutputs // {inherit overlays utils;};
}
