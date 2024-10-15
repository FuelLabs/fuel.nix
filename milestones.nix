# A map from repo name to git commit hash for each release milestone.
# Allows for referencing packages or package sets by milestone, e.g.
# `forc-beta-4`, `fuel-core-beta-5`, etc.
{
  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-beta-4.toml
  beta-4 = {
    forc-explorer = "4bb7392eed085ee3a6795b98ea25392b3f41ade8";
    forc-wallet = "7aea7749d716fbe807680b06935e3698a0cbd324";
    fuel-core = "704848a7b2164033b01e3c6c56c8a87772b81000";
    fuel-indexer = "fab101632573eff2b478277917b6c560965556ce";
    sway = "92dc9f361a9508a940c0d0708130f26fa044f6b3";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-beta-5.toml
  beta-5 = {
    forc-explorer = "4bb7392eed085ee3a6795b98ea25392b3f41ade8";
    forc-wallet = "4d5fa8b1214df6bcad9b31dbef571a67af70da8f";
    fuel-core = "d134579bc4054838e8809984070076bcfac56bb7";
    sway = "a70c746d27b3300beef896ccd1dcce1299836192";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-testnet.toml
  testnet = {
    forc-wallet = "ee49fcbacedc5f446134c6b7e5513d4232bb7566";
    fuel-core = "8c92d37598b760d64a14df1588ff27b3d14c7d2c";
    sway = "66bb430395daf5b8f7205f7b9d8d008e2e812d54";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-mainnet.toml
  ignition = {
    forc-wallet = "152bfb48c347363d32dc573c77315baba8d05e5b";
    fuel-core = "eea8c605258d79d5243f3f822c0e1205b0802f3c";
    sway = "d5662c6bd0e5519446aa1b3ebb6af703025accec";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-mainnet.toml
  mainnet = {
    forc-wallet = "152bfb48c347363d32dc573c77315baba8d05e5b";
    fuel-core = "eea8c605258d79d5243f3f822c0e1205b0802f3c";
    sway = "d5662c6bd0e5519446aa1b3ebb6af703025accec";
  };
}
