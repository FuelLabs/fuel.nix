# A map from repo name to git commit hash for each release milestone.
# Allows for referencing packages or package sets by milestone, e.g.
# `forc-beta-2`, `fuel-core-beta-1`, `fuel-beta-2`, etc.
{
  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-beta-1.toml
  beta-1 = {
    forc-wallet = "9473052e88048f58e8c4e1eba0ff88ef6a4cdd59";
    fuel-core = "a0351c241754f670470cbf0aa5bb743582b038d1";
    sway = "e7674f704f2706e22f77c0ed32df9c89302e5e7e";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-beta-2.toml
  beta-2 = {
    forc-explorer = "4bb7392eed085ee3a6795b98ea25392b3f41ade8";
    forc-wallet = "9473052e88048f58e8c4e1eba0ff88ef6a4cdd59";
    fuel-core = "49e4305fea691bbf293c606334e7b282a54393b3";
    fuel-indexer = "c2425c8b63f01ef1b540ff3e5832ebdc018b951d";
    sway = "c32b0759d25c0b515cbf535f9fb9b8e6fda38ff2";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-beta-3.toml
  beta-3 = {
    forc-explorer = "4bb7392eed085ee3a6795b98ea25392b3f41ade8";
    forc-wallet = "543bc1f4d7badd569c22dff88db2a988adee9d4e";
    fuel-core = "ce64223296537cecf5b8c2e2892e31e2f98fc9a5";
    fuel-indexer = "c55a0e34600d8f7c888a95dd3c0adb8fadfaf024";
    sway = "b6f19a3be7b2fb5ef88e358a926854dac10cb281";
  };
}
