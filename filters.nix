# Only package manifests that satisfy the following manually defined list of
# conditions will be used to generate packages. Feel free to update this to
# ignore certain problematic or impossible-to-build packages!
{pkgs}:
with pkgs.lib; [
  # Specify some minimum versions that we want to support, to save ourselves
  # having to build everything since the dawn of time and from having to patch
  # old unused versions.
  (m: m.pname != "forc" || versionAtLeast m.version "0.19.0")
  (m: m.pname != "forc-client" || versionAtLeast m.version "0.19.0")
  (m: m.pname != "forc-doc" || versionAtLeast m.version "0.29.0")
  (m: m.pname != "forc-explore" || versionAtLeast m.version "0.19.0")
  (m: m.pname != "forc-fmt" || versionAtLeast m.version "0.19.0")
  (m: m.pname != "forc-lsp" || versionAtLeast m.version "0.19.0")
  (m: m.pname != "forc-tx" || versionAtLeast m.version "0.33.1")
  (m: m.pname != "forc-wallet" || versionAtLeast m.version "0.1.0")
  (m: m.pname != "fuel-core" || versionAtLeast m.version "0.9.0")
  (m: m.pname != "fuel-core-client" || (versionAtLeast m.version "0.14.2" && m.date >= "2022-12-17"))
  (m: m.pname != "fuel-gql-cli" || (versionAtLeast m.version "0.9.0" && m.date < "2022-12-17"))
  (m: m.pname != "fuel-indexer" || versionAtLeast m.version "0.1.8")
]
