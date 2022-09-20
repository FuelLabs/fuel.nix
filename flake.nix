{
  description = ''
    A Nix flake for the Fuel Labs ecosystem.
  '';

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

    # Collect the package manifests and sort them into published, nightly,
    # latest and default sets.
    mkManifests = pkgs: let
      # Load the manually defined filters and patches.
      filters = import ./filters.nix {inherit pkgs;};
      patches = import ./patches.nix {inherit pkgs;};

      # Returns true if the given manifest passes all our filters.
      filter = m: pkgs.lib.all (f: f m) filters;

      # Apply all `patches` whose conditions are met by the given manifest.
      patch = let
        filtered = m: pkgs.lib.filter (p: p.condition m) patches;
        apply = m: p: pkgs.lib.recursiveUpdate m (p.patch m);
      in
        m: pkgs.lib.foldl apply m (filtered m);

      # Load a manifest file given its filename and construct the attributes.
      manifest = filename: let
        fileattrs = import (./manifests + "/${filename}");
      in {
        inherit (fileattrs) pname version date;
        src = pkgs.fetchgit {
          inherit (fileattrs) url rev sha256;
        };
      };
    in rec {
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
        mapPublished = name: v: pkgs.lib.nameValuePair (name + "-latest") v;
        mapNightly = name: v: pkgs.lib.nameValuePair (name + "-nightly") v;
        foldPublished = pkgs.lib.foldr update {} published.prepared;
        foldNightly = pkgs.lib.foldr update {} nightly.prepared;
      in {
        published = pkgs.lib.mapAttrs' mapPublished foldPublished;
        nightly = pkgs.lib.mapAttrs' mapNightly foldNightly;
      };

      # Construct the default packages as aliases of the latest versions.
      defaults = pkgs.lib.mapAttrs' (n: v: pkgs.lib.nameValuePair (pkgs.lib.removeSuffix "-latest" n) v) latest.published;
    };

    # Generate the packages from the manifest sets.
    mkPackages = pkgs: let
      manifests = mkManifests pkgs;
      packageName = manifest: builtins.replaceStrings ["."] ["-"] "${manifest.pname}-${manifest.version}";
      packageNameNightly = manifest: "${packageName manifest}-nightly-${manifest.date}";
      buildRustPackage = manifest: let
        rust-platform = pkgs.makeRustPlatform {
          rustc = manifest.rust;
          cargo = manifest.rust;
        };
      in
        rust-platform.buildRustPackage manifest;
      packageAttr = manifest: {
        name = packageName manifest;
        value = buildRustPackage manifest;
      };
      packageAttrNightly = manifest: {
        name = packageNameNightly manifest;
        value = buildRustPackage manifest;
      };
      packagesPublished = builtins.listToAttrs (map packageAttr manifests.published.prepared);
      packagesNightly = builtins.listToAttrs (map packageAttrNightly manifests.nightly.prepared);
      packagesPublishedLatest = pkgs.lib.mapAttrs (n: m: buildRustPackage m) manifests.latest.published;
      packagesNightlyLatest = pkgs.lib.mapAttrs (n: m: buildRustPackage m) manifests.latest.nightly;
      packagesDefault = pkgs.lib.mapAttrs (n: m: buildRustPackage m) manifests.defaults;
      packagesGroups = rec {
        fuel-latest = pkgs.symlinkJoin {
          name = "fuel-latest";
          paths = pkgs.lib.attrValues packagesPublishedLatest;
        };
        fuel-nightly = pkgs.symlinkJoin {
          name = "fuel-nightly";
          paths = pkgs.lib.attrValues packagesNightlyLatest;
        };
        fuel = fuel-latest;
        default = fuel;
      };
      packagesOther = {
        refresh-manifests = pkgs.writeShellApplication {
          name = "refresh-manifests";
          runtimeInputs = [
            pkgs.coreutils # For `date` command
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
    in
      packagesPublished
      // packagesNightly
      // packagesPublishedLatest
      // packagesNightlyLatest
      // packagesDefault
      // packagesGroups
      // packagesOther;

    overlays = rec {
      fuel = final: prev: let
        fuelpkgs = mkPackages prev;
      in {
        inherit (fuelpkgs) fuel-core fuel-gql-cli forc forc-explore forc-fmt forc-lsp;
        vimPlugins = prev.vimPlugins // {inherit (fuelpkgs) sway-vim;};
      };
      default = fuel;
    };

    mkDevShells = pkgs: fuelpkgs: rec {
      fuel-core-dev = pkgs.mkShell {
        name = "fuel-core-dev";
        inputsFrom = with fuelpkgs; [fuel-core fuel-gql-cli];
        buildInputs = [pkgs.grpc-tools];
        inherit (fuelpkgs.fuel-core) LIBCLANG_PATH;
        PROTOC = "${pkgs.grpc-tools}/bin/protoc";
      };

      sway-dev = pkgs.mkShell {
        name = "sway-dev";
        inputsFrom = with fuelpkgs; [forc forc-client forc-explore forc-fmt forc-lsp];
        buildInputs = with fuelpkgs; [fuel-core fuel-gql-cli];
      };

      fuel-dev = pkgs.mkShell {
        name = "fuel-dev";
        inputsFrom = let
          isLatestPublished = name: pkgs.lib.hasInfix "latest" name && !(pkgs.lib.hasInfix "nightly" name);
          latestPublished = pkgs.lib.filterAttrs (n: v: isLatestPublished n) fuelpkgs;
        in
          pkgs.lib.mapAttrsToList (n: v: v) latestPublished;
        inherit (fuel-core-dev) LIBCLANG_PATH PROTOC;
      };
      default = fuel-dev;
    };

    mkOutput = system: let
      overlays = [inputs.rust-overlay.overlays.default];
      pkgs = import inputs.nixpkgs {inherit overlays system;};
    in rec {
      packages = mkPackages pkgs;
      devShells = mkDevShells pkgs packages;
      formatter = pkgs.alejandra;
    };

    # The output for each system.
    systemOutputs = utils.eachSupportedSystem mkOutput;
  in
    # Merge the outputs and overlays.
    systemOutputs // {inherit overlays utils;};
}
