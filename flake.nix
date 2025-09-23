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
      mstones = import ./milestones.nix;

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

      # Construct the milestone package lists, e.g. `{ testnet = [...]; mainnet = [...]; }`.
      milestones = let
        filterPkg = revs: m: builtins.any (rev: rev == m.src.rev) (builtins.attrValues revs);
        filterPublished = revs: builtins.filter (filterPkg revs) published.prepared;
        mapPkg = mname: m: m // {pname = "${m.pname}" + "-" + "${mname}";};
        milestonePkgs = name: revs: map (mapPkg name) (filterPublished revs);
        mapMilestone = name: revs: pkgs.lib.nameValuePair name (milestonePkgs name revs);
      in
        pkgs.lib.mapAttrs' mapMilestone mstones;

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
      buildRustPackages = manifests: pkgs.lib.mapAttrs (n: m: buildRustPackage m) manifests;
      packageAttr = manifest: {
        name = packageName manifest;
        value = buildRustPackage manifest;
      };
      packageAttrNightly = manifest: {
        name = packageNameNightly manifest;
        value = buildRustPackage manifest;
      };
      packageAttrMilestone = manifest: {
        name = manifest.pname;
        value = buildRustPackage manifest;
      };
      packagesPublished = builtins.listToAttrs (map packageAttr manifests.published.prepared);
      packagesNightly = builtins.listToAttrs (map packageAttrNightly manifests.nightly.prepared);
      packagesPublishedLatest = buildRustPackages manifests.latest.published;
      packagesNightlyLatest = buildRustPackages manifests.latest.nightly;
      packagesDefault = buildRustPackages manifests.defaults;
      packagesMilestone = manifests: builtins.listToAttrs (map packageAttrMilestone manifests);
      packagesMilestones = pkgs.lib.mapAttrs' (mn: mms: pkgs.lib.nameValuePair mn (packagesMilestone mms)) manifests.milestones;
      packagesMilestonesAll = pkgs.lib.concatMapAttrs (_: pkgs: pkgs) packagesMilestones;
      packagesMilestoneGroup = mstone: packages: rec {
        name = "fuel-" + mstone;
        value = pkgs.symlinkJoin {
          inherit name;
          paths = pkgs.lib.attrValues packages;
        };
      };
      packagesMilestoneGroups = pkgs.lib.mapAttrs' packagesMilestoneGroup packagesMilestones;
      packagesGroups =
        rec {
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
        }
        // packagesMilestoneGroups;
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
      // packagesMilestonesAll
      // packagesGroups
      // packagesOther;

    overlays = rec {
      fuel = final: prev: let
        fuelpkgs = mkPackages prev;
      in {
        inherit (fuelpkgs) fuel;
        vimPlugins = prev.vimPlugins // {inherit (fuelpkgs) sway-vim;};
      };

      fuel-nightly = final: prev: let
        fuelpkgs = mkPackages prev;
      in {
        inherit (fuelpkgs) fuel-nightly;
        vimPlugins = prev.vimPlugins // {inherit (fuelpkgs) sway-vim;};
      };

      default = fuel;
    };

    mkDevShells = pkgs: fuelpkgs: rec {
      book-dev = pkgs.mkShell {
        name = "book-dev";
        buildInputs = [pkgs.mdbook];
      };

      fuel-core-dev = pkgs.mkShell {
        name = "fuel-core-dev";
        inputsFrom = with fuelpkgs; [
          fuel-core-nightly
        ];
        buildInputs = [
          pkgs.grpc-tools
          pkgs.rust-analyzer
        ];
        inherit (fuelpkgs.fuel-core-nightly) LIBCLANG_PATH ROCKSDB_LIB_DIR;
        PROTOC = "${pkgs.grpc-tools}/bin/protoc";
        NIX_CFLAGS_COMPILE = fuelpkgs.fuel-core-nightly.NIX_CFLAGS_COMPILE or "";
      };

      sway-dev = pkgs.mkShell {
        name = "sway-dev";
        inputsFrom = with fuelpkgs; [
          forc-nightly
          forc-client-nightly
          forc-doc-nightly
          forc-fmt-nightly
          forc-lsp-nightly
          forc-tx-nightly
        ]
        ++ (pkgs.lib.optional (fuelpkgs ? forc-call-nightly) forc-call-nightly)
        ++ (pkgs.lib.optional (fuelpkgs ? forc-migrate-nightly) forc-migrate-nightly)
        ++ (pkgs.lib.optional (fuelpkgs ? forc-node-nightly) forc-node-nightly)
        ++ (pkgs.lib.optional (fuelpkgs ? forc-publish-nightly) forc-publish-nightly);
        buildInputs = with fuelpkgs; [fuel-core fuel-gql-cli];
      };

      fuel-dev = pkgs.mkShell {
        name = "fuel-dev";
        inputsFrom = let
          isCurrentNightly = name: name != "fuel-nightly" && pkgs.lib.hasSuffix "nightly" name;
          currentNightlies = pkgs.lib.filterAttrs (n: v: isCurrentNightly n) fuelpkgs;
        in
          (pkgs.lib.mapAttrsToList (n: v: v) currentNightlies) ++ [fuel-core-dev sway-dev];
        buildInputs = [
          pkgs.postgresql
        ];
        inherit (fuel-core-dev) LIBCLANG_PATH ROCKSDB_LIB_DIR PROTOC NIX_CFLAGS_COMPILE;
        # Remove the hardening added by nix to fix jmalloc compilation error.
        # More info: https://github.com/tikv/jemallocator/issues/108
        hardeningDisable = ["fortify"];
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
