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
    forc-wallet = "c0a69f05e48031632b58e1b69eebb1ea19b6dd2d";
    fuel-core = "843ed0b5008acbb7934ae92a1e9ae1368f2b5157";
    fuel-indexer = "a72e66da03e530976c34e94c4b35ae588fac1d6d";
    sway = "5d2b10bd83791d2eaff04206dbd45bfdd9cf23ff";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-beta-4-rc.toml
  beta-4-rc = {
    forc-explorer = "4bb7392eed085ee3a6795b98ea25392b3f41ade8";
    forc-wallet = "14c29a7b160edfd974901f8e10bbe23aba3db105";
    fuel-core = "955ff5f7508daf0cd4b1542a58bded78d09516f4";
    fuel-indexer = "c4aa7256308b77e3c612a217e81a2bfc0ac3532d";
    sway = "3b66f8e424bd21e3ba467783b10b36e808cfa6ee";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-beta-4-rc.2.toml
  beta-4-rc-2 = {
    forc-explorer = "4bb7392eed085ee3a6795b98ea25392b3f41ade8";
    forc-wallet = "755404c32dc3955b72304b200449e0cc9759f6ca";
    fuel-core = "704848a7b2164033b01e3c6c56c8a87772b81000";
    fuel-indexer = "94ee6d6b345c50e5016d5e6b1efa7dbe4e750b45";
    sway = "04a597093e7441898933dd412b8e4dc6ac860cd3";
  };
}
