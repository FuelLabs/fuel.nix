# A map from repo name to git commit hash for each release milestone.
# Allows for referencing packages or package sets by milestone, e.g.
# `forc-testnet`, `fuel-core-mainnet`, etc.
{
  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-testnet.toml
  testnet = {
    forc-wallet = "9015e09f45818bbb8068fa644e9cda0e5b5c3809";
    fuel-core = "9827d2115c8e73cf3a13952f2cb3dd596858165c";
    sway = "512bbfccdb15a0045576604ba97d7943c9b7520f";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-mainnet.toml
  ignition = {
    forc-wallet = "9015e09f45818bbb8068fa644e9cda0e5b5c3809";
    fuel-core = "9827d2115c8e73cf3a13952f2cb3dd596858165c";
    sway = "512bbfccdb15a0045576604ba97d7943c9b7520f";
  };

  # Commits sourced from:
  # https://raw.githubusercontent.com/FuelLabs/fuelup/gh-pages/channel-fuel-mainnet.toml
  mainnet = {
    forc-wallet = "9015e09f45818bbb8068fa644e9cda0e5b5c3809";
    fuel-core = "9827d2115c8e73cf3a13952f2cb3dd596858165c";
    sway = "512bbfccdb15a0045576604ba97d7943c9b7520f";
  };
}
