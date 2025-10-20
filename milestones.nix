# A map from repo name to git commit hash for each release milestone.
# Allows for referencing packages or package sets by milestone, e.g.
# `forc-testnet`, `fuel-core-mainnet`, etc.
{
  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-testnet.toml
  testnet = {
    forc-wallet = "6ba79bc6fb2f14acfedb4eed6197f5b56294fc38";
    fuel-core = "e295b233078e8d236826019c4a5db13ed89a437c";
    sway = "107b092e9d7003256321d3890a636273d0845662";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-mainnet.toml
  ignition = {
    forc-wallet = "6ba79bc6fb2f14acfedb4eed6197f5b56294fc38";
    fuel-core = "e295b233078e8d236826019c4a5db13ed89a437c";
    sway = "107b092e9d7003256321d3890a636273d0845662";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-mainnet.toml
  mainnet = {
    forc-wallet = "6ba79bc6fb2f14acfedb4eed6197f5b56294fc38";
    fuel-core = "e295b233078e8d236826019c4a5db13ed89a437c";
    sway = "107b092e9d7003256321d3890a636273d0845662";
  };
}
