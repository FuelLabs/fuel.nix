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
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-beta-4.toml
  beta-4 = {
    forc-explorer = "4bb7392eed085ee3a6795b98ea25392b3f41ade8";
    forc-wallet = "7aea7749d716fbe807680b06935e3698a0cbd324";
    fuel-core = "704848a7b2164033b01e3c6c56c8a87772b81000";
    fuel-indexer = "fab101632573eff2b478277917b6c560965556ce";
    sway = "92dc9f361a9508a940c0d0708130f26fa044f6b3";
  };
}
