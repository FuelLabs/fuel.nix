# This file contains a list of manually defined manifest patches.
# These are used to update or transform manifests to suit the specific needs of each package.
# Patches are applied if their condition is met in the order they are defined in this list.
{pkgs}: [
  # By default, most packages have their `Cargo.lock` file in the repo root.
  # We also specify a base, minimum Rust version. This version should never
  # change in order to avoid invalidating the cache for all previously built
  # packages. Instead, if a new version of a fuel package requires a newer
  # version of Rust, we should specify the necessary condition in a new patch
  # to ensure only newer packages use the newer version of Rust.
  {
    condition = m: true;
    patch = m: {
      cargoLock.lockFile = "${m.src}/Cargo.lock";
      meta.homepage = m.src.gitRepoUrl;
      rust = pkgs.rust-bin.stable."1.63.0".default;
    };
  }

  # Packages within the sway and fuel-core repos are normally defined within a
  # subdirectory that is equal to their package name.
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

  # From around version 0.19.0 until roughly 2022-09-08, the Sway repo had a
  # workspace-level patch for `mdbook` that pointed to a git repo. This patch
  # provides that git repo's output hash to ensure deterministic builds for
  # commits within that range.
  {
    condition = m:
      m.src.gitRepoUrl
      == "https://github.com/fuellabs/sway"
      && pkgs.lib.versionAtLeast m.version "0.19.0"
      && (m.date <= "2022-09-08" || m.src.rev == "19b9fecdba613a229b7b3c3db7fe86113aefb2fe");
    patch = m: {
      cargoLock.outputHashes = {
        "mdbook-0.4.20" = "sha256-hNyG2DVD1KFttXF4m8WnfoxRjA0cghA7NoV5AW7wZrI=";
      };
      meta.license = pkgs.lib.licenses.asl20;
    };
  }

  # The fuel-core crate requires clang for the rocksdb bindings generation.
  # We also specify `ROCKSDB_LIB_DIR` in order to allow the rocksdb build
  # script to use rocksdb as a dynamic library.
  {
    condition = m: m.pname == "fuel-core";
    patch = m: {
      nativeBuildInputs = (m.nativeBuildInputs or []) ++ [pkgs.clang];
      buildInputs = (m.buildInputs or []) ++ [pkgs.rocksdb];
      doCheck = false; # Already tested at repo, causes longer build times.
      LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
      ROCKSDB_LIB_DIR = "${pkgs.rocksdb}/lib";
    };
  }

  # The `fuel-gql-cli`'s fuel-core subdirectory does not match its binary name,
  # so we specify the correct subdirectory here.
  {
    condition = m: m.pname == "fuel-gql-cli";
    patch = m: {
      buildAndTestSubdir = "fuel-client";
    };
  }

  # Some `forc-pkg` and some crates that depend on it require openssl, so add
  # the required packages.
  {
    condition = m: m.pname == "forc" || m.pname == "forc-client" || m.pname == "forc-lsp";
    patch = m: {
      nativeBuildInputs =
        (m.nativeBuildInputs or [])
        ++ [
          pkgs.perl # for openssl-sys
          pkgs.pkg-config # for openssl-sys
        ];
    };
  }

  # The forc plugins that reside in the Sway repo are in a dedicated
  # subdirectory.
  {
    condition = m: m.pname == "forc-client" || m.pname == "forc-explore" || m.pname == "forc-fmt" || m.pname == "forc-lsp";
    patch = m: {
      buildAndTestSubdir = "forc-plugins/${m.pname}";
    };
  }

  # A patch for some `forc-wallet` nightlies whose committed `Cargo.lock` file
  # was out of date.
  {
    condition = m: m.pname == "forc-wallet" && m.version == "0.1.0" && m.date < "2022-09-04";
    patch = m: {
      cargoPatches = [
        ./patch/forc-wallet-0.1.0-update-lock.patch
      ];
      cargoHash = "sha256-LXQaPcpf/n1RRFTQXAP6PexfEI67U2Z5OOW5DzNJvX8=";
      cargoLock = null;
    };
  }

  # A patch for a `fuel-core` and `fuel-gql-cli` nightly whose committed
  # `Cargo.lock` file was out of date.
  {
    condition = m: (m.pname == "fuel-core" || m.pname == "fuel-gql-cli") && m.version == "0.10.1" && m.date == "2022-09-07";
    patch = m: {
      cargoPatches = [
        ./patch/fuel-core-0.10.1-nightly-2022-09-08-update-lock.patch
      ];
      cargoHash =
        if m.pname == "fuel-core"
        then "sha256-WyGQWKLVtk+z0mahfve/0SyEW4u1oo3xQOUCYi9CKWM="
        else "sha256-xxFA97O1RX1rR9LGvU7z/4r/8b/VmeMksaoRYTgXcPo=";
      cargoLock = null;
    };
  }

  # We generally appear to require these frameworks on darwin.
  {
    condition = m: pkgs.lib.hasInfix "darwin" pkgs.system;
    patch = m: {
      buildInputs =
        (m.buildInputs or [])
        ++ [
          pkgs.darwin.apple_sdk.frameworks.CoreFoundation
          pkgs.darwin.apple_sdk.frameworks.Security
          pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
        ];
    };
  }

  # Attempt at solving this:
  # https://github.com/mitchmindtree/fuel.nix/pull/17#issuecomment-1254844214
  {
    condition = m: pkgs.lib.hasInfix "darwin" pkgs.system && m.pname == "fuel-core";
    patch = m: {
      NIX_CFLAGS_COMPILE = pkgs.lib.optionalString pkgs.stdenv.cc.isClang "-Wno-error=unused-private-field -faligned-allocation";
    };
  }

  # `fuel-core` needs Rust 1.64 as of bcb86da09b6fdce09f13ef4181a0ca6461f8e2a8.
  # This changes the Rust used for all pkgs to 1.64 from the day of the commit.
  {
    condition = m: m.date >= "2022-09-23";
    patch = m: {
      rust = pkgs.rust-bin.stable."1.64.0".default;
    };
  }

  # Since this date, `forc-wallet` got some tests that require doing file
  # operations that are unpermitted in Nix's sandbox during a build. These
  # tests are run at `forc-wallet`'s repo CI, so it's fine to disable the check
  # here.
  {
    condition = m: m.pname == "forc-wallet" && m.date >= "2022-10-10";
    patch = m: {
      doCheck = false; # Already tested at repo.
    };
  }

  # At some point around this date, Sway LSP started requiring the CoreServices
  # framework on Darwin due to a dependency update. Here we just make it
  # available to all fuel packages going forward.
  {
    condition = m: pkgs.lib.hasInfix "darwin" pkgs.system && m.date >= "2022-10-10";
    patch = m: {
      buildInputs =
        (m.buildInputs or [])
        ++ [
          pkgs.darwin.apple_sdk.frameworks.CoreServices
        ];
    };
  }

  # Since this date, `forc` got some tests that require doing file operations
  # that are unpermitted in Nix's sandbox during a build. These tests are run
  # at `forc`'s repo CI, so it's fine to disable the check here.
  {
    condition = m: m.pname == "forc" && m.date >= "2022-11-01";
    patch = m: {
      doCheck = false; # Already tested at repo.
    };
  }
]
