# Only package manifests that satisfy the following manually defined list of
# conditions will be used to generate packages. Feel free to update this to
# ignore certain problematic or impossible-to-build packages!
{pkgs}: [
  # Specify some minimum versions that we want to support, to save ourselves
  # having to build everything since the dawn of time and from having to patch
  # old unused versions.
  (m: m.pname != "fuel-core" || pkgs.lib.versionAtLeast m.version "0.9.0")
  (m: m.pname != "fuel-gql-cli" || pkgs.lib.versionAtLeast m.version "0.9.0")
  (m: m.pname != "forc" || pkgs.lib.versionAtLeast m.version "0.19.0")
  (m: m.pname != "forc-client" || pkgs.lib.versionAtLeast m.version "0.19.0")
  (m: m.pname != "forc-explore" || pkgs.lib.versionAtLeast m.version "0.19.0")
  (m: m.pname != "forc-fmt" || pkgs.lib.versionAtLeast m.version "0.19.0")
  (m: m.pname != "forc-lsp" || pkgs.lib.versionAtLeast m.version "0.19.0")
  (m: m.pname != "forc-wallet" || pkgs.lib.versionAtLeast m.version "0.1.0")
]
