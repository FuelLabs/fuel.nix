# Update Milestones Tool

This tool updates the `milestones.nix` file with the latest commit hashes from GitHub releases for the Fuel ecosystem components.

## Building

```bash
cargo build --release
```

## Usage

You can specify custom tags or commit hashes for any component:

```bash
# Fetch latest releases for all channels
cargo run --

# Or use the built binary
./target/release/update-milestones

# Update testnet sway to a specific commit
cargo run -- --testnet-sway 1fb61fdc42054109c54a57544b9aeb88afd3cae8

# Update all testnet components
cargo run -- \
  --testnet-forc-wallet 0.16.1 \
  --testnet-fuel-core v0.40.0 \
  --testnet-sway v0.65.2

# Update all components for all environments
cargo run -- \
  --testnet-forc-wallet 0.16.1 \
  --testnet-fuel-core v0.40.0 \
  --testnet-sway v0.65.2 \
  --mainnet-forc-wallet 0.16.1 \
  --mainnet-fuel-core v0.40.0 \
  --mainnet-sway v0.65.1
```

## GitHub Token

To avoid GitHub API rate limits (60 requests/hour for unauthenticated requests), you should use a GitHub personal access token:

1. Go to https://github.com/settings/tokens
2. Generate a new token (classic) with `public_repo` scope
3. Set it as an environment variable:
   ```bash
   export GITHUB_TOKEN="ghp_your_token_here"
   ```

The token can be provided in three ways:
- Environment variable: `GITHUB_TOKEN=xxx cargo run`
- Command line alias: `cargo run -- --token xxx`

## Output

The tool will:
1. Update the `milestones.nix` file with new commit hashes
2. Generate a PR description with the format:
  ```
  Bump testnet, ignition and mainnet channels.

  Testnet:
  `forc-wallet`: forc-wallet-X.Y.Z
  `fuel-core`: vX.Y.Z
  `sway`: vX.Y.Z

  Ignition & Mainnet:
  `forc-wallet`: forc-wallet-X.Y.Z
  `fuel-core`: vX.Y.Z
  `sway`: vX.Y.Z
  ```

If running in GitHub Actions (when `GITHUB_ENV` is set), the PR description is written to the GitHub environment file. Otherwise, it's printed to stdout.
