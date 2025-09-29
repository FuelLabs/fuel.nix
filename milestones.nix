# A map from repo name to git commit hash for each release milestone.
# Allows for referencing packages or package sets by milestone, e.g.
# `forc-testnet`, `fuel-core-mainnet`, etc.
{
  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-testnet.toml
  testnet = {
    forc-wallet = "9fea98d095d72c771f6a6f81f901fa4f8d5ece52";
    fuel-core = "8e34930a63329ce60bb361d38e25f6b9a7429a05";
    sway = "a1300bae7d7a57c96517364f6f1236927666176f";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-mainnet.toml
  ignition = {
    forc-wallet = "9fea98d095d72c771f6a6f81f901fa4f8d5ece52";
    fuel-core = "8e34930a63329ce60bb361d38e25f6b9a7429a05";
    sway = "a1300bae7d7a57c96517364f6f1236927666176f";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-mainnet.toml
  mainnet = {
    forc-wallet = "9fea98d095d72c771f6a6f81f901fa4f8d5ece52";
    fuel-core = "8e34930a63329ce60bb361d38e25f6b9a7429a05";
    sway = "a1300bae7d7a57c96517364f6f1236927666176f";
  };
}
