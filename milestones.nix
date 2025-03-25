# A map from repo name to git commit hash for each release milestone.
# Allows for referencing packages or package sets by milestone, e.g.
# `forc-testnet`, `fuel-core-mainnet`, etc.
{
  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-testnet.toml
  testnet = {
    forc-wallet = "8d59dbc462dab2d438c6ec8e52051deb000ac5a4";
    fuel-core = "ccff696336406e842c9ed25bc23af8bcaa47eccd";
    sway = "d821dcb0c7edb1d6e2a772f5a1ccefe38902eaec";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-mainnet.toml
  ignition = {
    forc-wallet = "8d59dbc462dab2d438c6ec8e52051deb000ac5a4";
    fuel-core = "ccff696336406e842c9ed25bc23af8bcaa47eccd";
    sway = "d821dcb0c7edb1d6e2a772f5a1ccefe38902eaec";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-mainnet.toml
  mainnet = {
    forc-wallet = "8d59dbc462dab2d438c6ec8e52051deb000ac5a4";
    fuel-core = "ccff696336406e842c9ed25bc23af8bcaa47eccd";
    sway = "d821dcb0c7edb1d6e2a772f5a1ccefe38902eaec";
  };
}
