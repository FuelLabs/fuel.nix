# A map from repo name to git commit hash for each release milestone.
# Allows for referencing packages or package sets by milestone, e.g.
# `forc-testnet`, `fuel-core-mainnet`, etc.
{
  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-testnet.toml
  testnet = {
    forc-wallet = "9fea98d095d72c771f6a6f81f901fa4f8d5ece52";
    fuel-core = "e295b233078e8d236826019c4a5db13ed89a437c";
    sway = "ec6f0ca5c7c062251713021c42fdf51223810d21";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-mainnet.toml
  ignition = {
    forc-wallet = "9fea98d095d72c771f6a6f81f901fa4f8d5ece52";
    fuel-core = "e295b233078e8d236826019c4a5db13ed89a437c";
    sway = "ec6f0ca5c7c062251713021c42fdf51223810d21";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-mainnet.toml
  mainnet = {
    forc-wallet = "9fea98d095d72c771f6a6f81f901fa4f8d5ece52";
    fuel-core = "e295b233078e8d236826019c4a5db13ed89a437c";
    sway = "ec6f0ca5c7c062251713021c42fdf51223810d21";
  };
}
