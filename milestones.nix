# A map from repo name to git commit hash for each release milestone.
# Allows for referencing packages or package sets by milestone, e.g.
# `forc-testnet`, `fuel-core-mainnet`, etc.
{
  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-testnet.toml
  testnet = {
    forc-wallet = "9fea98d095d72c771f6a6f81f901fa4f8d5ece52";
    fuel-core = "85b2356d510a30cffaa8be7015203bb8ac30fee6";
    sway = "b68a3861db866f33078b3c966eaf5b3379e716cf";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-mainnet.toml
  ignition = {
    forc-wallet = "9fea98d095d72c771f6a6f81f901fa4f8d5ece52";
    fuel-core = "8e34930a63329ce60bb361d38e25f6b9a7429a05";
    sway = "b68a3861db866f33078b3c966eaf5b3379e716cf";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-mainnet.toml
  mainnet = {
    forc-wallet = "9fea98d095d72c771f6a6f81f901fa4f8d5ece52";
    fuel-core = "8e34930a63329ce60bb361d38e25f6b9a7429a05";
    sway = "b68a3861db866f33078b3c966eaf5b3379e716cf";
  };
}
