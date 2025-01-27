# A map from repo name to git commit hash for each release milestone.
# Allows for referencing packages or package sets by milestone, e.g.
# `forc-testnet`, `fuel-core-mainnet`, etc.
{
  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-testnet.toml
  testnet = {
    forc-wallet = "f4052012e05babee66bf3a70ab06c0c8570f56d9";
    fuel-core = "eea8c605258d79d5243f3f822c0e1205b0802f3c";
    sway = "986aee2c1e34c9cd958c81e7fd6b84638b26619b";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-mainnet.toml
  ignition = {
    forc-wallet = "f4052012e05babee66bf3a70ab06c0c8570f56d9";
    fuel-core = "eea8c605258d79d5243f3f822c0e1205b0802f3c";
    sway = "986aee2c1e34c9cd958c81e7fd6b84638b26619b";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-mainnet.toml
  mainnet = {
    forc-wallet = "f4052012e05babee66bf3a70ab06c0c8570f56d9";
    fuel-core = "eea8c605258d79d5243f3f822c0e1205b0802f3c";
    sway = "986aee2c1e34c9cd958c81e7fd6b84638b26619b";
  };
}
