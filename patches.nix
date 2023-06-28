# This file contains a list of manually defined manifest patches.
# These are used to update or transform manifests to suit the specific needs of each package.
# Patches are applied if their condition is met in the order they are defined in this list.
{pkgs}: let
  forc-plugins = [
    "forc-client"
    "forc-doc"
    "forc-fmt"
    "forc-lsp"
    "forc-tx"
  ];
in [
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
      LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
      ROCKSDB_LIB_DIR = "${pkgs.rocksdb}/lib";
    };
  }

  # Fuel-core tests run at their repo - no need to repeat them here.
  {
    condition = m: m.src.gitRepoUrl == "https://github.com/fuellabs/fuel-core";
    patch = m: {
      doCheck = false; # Already tested at repo, causes longer build times.
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
    condition = m: pkgs.lib.any (n: m.pname == n) (["forc"] ++ forc-plugins);
    patch = m: {
      nativeBuildInputs =
        (m.nativeBuildInputs or [])
        ++ [
          pkgs.perl # for openssl-sys
          pkgs.pkg-config # for openssl-sys
	  pkgs.libssh2
        ];
    };
  }

  # The forc plugins that reside in the Sway repo are in a dedicated
  # subdirectory.
  {
    condition = m: pkgs.lib.any (n: m.pname == n) forc-plugins;
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
    condition = m: m.src.gitRepoUrl == "https://github.com/fuellabs/fuel-core" && m.version == "0.10.1" && m.date == "2022-09-07";
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
          pkgs.darwin.apple_sdk_11_0.frameworks.CoreFoundation
          pkgs.darwin.apple_sdk_11_0.frameworks.Security
          pkgs.darwin.apple_sdk_11_0.frameworks.SystemConfiguration
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
          pkgs.darwin.apple_sdk_11_0.frameworks.CoreServices
        ];
    };
  }

  # Since this date, `forc` got some tests that require doing file operations
  # that are unpermitted in Nix's sandbox during a build. These tests are run
  # at `forc`'s repo CI, so it's fine to disable the check here.
  {
    condition = m: pkgs.lib.any (n: m.pname == n) (["forc"] ++ forc-plugins) && m.date >= "2022-10-31";
    patch = m: {
      doCheck = false; # Already tested at repo.
    };
  }

  # As of 2022-12-17 the fuel-core exe was moved into the `bin` subdirectory.
  # Version 0.15.3 (rev 49e4305fea691bbf293c606334e7b282a54393b3) retains the
  # old directory structure.
  {
    condition = m:
      m.pname
      == "fuel-core"
      && m.date >= "2022-12-17"
      && m.src.rev != "49e4305fea691bbf293c606334e7b282a54393b3";
    patch = m: {
      buildAndTestSubdir = "bin/fuel-core";
    };
  }

  # As of 2022-12-17 the fuel-core-client exe was renamed and moved into the `bin`
  # subdirectory.
  # Version 0.15.3 (rev 49e4305fea691bbf293c606334e7b282a54393b3) retains the
  # old directory structure.
  {
    condition = m: m.pname == "fuel-core-client";
    patch = m: {
      buildAndTestSubdir =
        if m.src.rev == "49e4305fea691bbf293c606334e7b282a54393b3"
        then "fuel-client"
        else "bin/fuel-core-client";
    };
  }

  # For a short while around version 0.33.0 (roughly 2023-01-14 to 2023-01-18),
  # the Sway repo had a git dependency on the ethabi-18.0.0 crate. This was
  # removed in favour of using our own crate.
  {
    condition = m:
      m.src.gitRepoUrl
      == "https://github.com/fuellabs/sway"
      && pkgs.lib.versionAtLeast m.version "0.33.0"
      && (m.date >= "2023-01-14" || m.src.rev == "a0be5f2cbe0bf7a6d008a2210920da9d4ff5dbae")
      && m.date < "2023-01-18";
    patch = m: {
      cargoLock.outputHashes =
        (m.cargoLock.outputHashes or {})
        // {
          "ethabi-18.0.0" = "sha256-N5bjuJoGYzcnfQg5pe79joUI2gOPAd9tcSvrBOYv5rc=";
        };
    };
  }

  # `fuel-storage` needs Rust 1.65 as of
  # cc11d3184c78401436d984e660748c9a9ed3df88 due to its use of generic
  # associated types. This changes the Rust used for all pkgs to 1.65 from the
  # day of the commit.
  {
    condition = m: m.date >= "2023-01-13";
    patch = m: {
      rust = pkgs.rust-bin.stable."1.65.0".default;
    };
  }

  # The fuel-indexer crates generally require postgresql and sqlx-cli.
  # They're normally placed under `packages` directory with the exception of
  # forc plugins.
  {
    condition = m: m.src.gitRepoUrl == "https://github.com/fuellabs/fuel-indexer";
    patch = m: {
      nativeBuildInputs = (m.nativeBuildInputs or []) ++ [pkgs.pkg-config];
      buildAndTestSubdir =
        if pkgs.lib.hasPrefix "forc-" m.pname
        then "plugins/${m.pname}"
        else "packages/${m.pname}";
      buildInputs =
        (m.buildInputs or [])
        ++ [
          pkgs.postgresql
          pkgs.sqlx-cli
        ];
      doCheck = false; # Already tested at repo.
      LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
      SQLX_OFFLINE = true;
    };
  }

  # `fuel-core` crates need Rust 1.67 as of
  # `580b2212bd5fa9870c9fef11e0ad72f373925e78` due to use of `checked_ilog` in
  # `fuel-vm` 0.25.3.
  {
    condition = m: m.date >= "2023-02-03" || m.src.rev == "580b2212bd5fa9870c9fef11e0ad72f373925e78";
    patch = m: {
      rust = pkgs.rust-bin.stable."1.67.0".default;
    };
  }

  # As of ~2023-02-15, the fuel-indexer crates appear to require openssl.
  {
    condition = m: m.date >= "2023-02-15" && m.src.gitRepoUrl == "https://github.com/fuellabs/fuel-indexer";
    patch = m: {
      buildInputs = (m.buildInputs or []) ++ [pkgs.openssl];
    };
  }

  # `forc-client` requires Rust 1.68 as of 0.40.1.
  {
    condition = m: m.date >= "2023-05-30";
    patch = m: {
      rust = pkgs.rust-bin.stable."1.68.0".default;
    };
  }
]
