use anyhow::{Context, Result};
use clap::Parser;
use regex::Regex;
use serde::Deserialize;
use std::collections::HashMap;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use tracing::info;
use tracing_subscriber::fmt::time::ChronoLocal;

#[derive(Debug, Deserialize)]
struct GitHubRelease {
    tag_name: String,
    #[allow(dead_code)]
    target_commitish: Option<String>,
}

#[derive(Debug, Deserialize)]
struct GitHubTag {
    #[serde(rename = "ref")]
    #[allow(dead_code)]
    tag_ref: String,
    object: GitHubObject,
}

#[derive(Debug, Deserialize)]
struct GitHubObject {
    sha: String,
}

#[derive(Debug, Clone)]
struct ComponentVersion {
    tag: String,
    commit_hash: String,
}

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Path to milestones.nix file (defaults to ../../../milestones.nix relative to this script)
    #[arg(long, default_value = "../../milestones.nix")]
    milestones_file: PathBuf,

    /// GitHub token for API authentication (can also be set via GITHUB_TOKEN env var)
    #[arg(long, env, alias = "token")]
    github_token: Option<String>,

    /// Tag or commit hash for forc-wallet in testnet environment
    #[arg(long)]
    testnet_forc_wallet: Option<String>,

    /// Tag or commit hash for fuel-core in testnet environment
    #[arg(long)]
    testnet_fuel_core: Option<String>,

    /// Tag or commit hash for sway in testnet environment
    #[arg(long)]
    testnet_sway: Option<String>,

    /// Tag or commit hash for forc-wallet in ignition/mainnet environment
    #[arg(long)]
    mainnet_forc_wallet: Option<String>,

    /// Tag or commit hash for fuel-core in ignition/mainnet environment
    #[arg(long)]
    mainnet_fuel_core: Option<String>,

    /// Tag or commit hash for sway in ignition/mainnet environment
    #[arg(long)]
    mainnet_sway: Option<String>,
}

fn main() -> Result<()> {
    // Initialize tracing with datetime stamps
    tracing_subscriber::fmt()
        .with_timer(ChronoLocal::new("%Y-%m-%d %H:%M:%S%.3f".to_string()))
        .init();

    info!("Starting update-milestones script");

    let args = Args::parse();
    let client = build_http_client(&args.github_token)?;

    // Resolve the milestones file path
    let milestones_path = resolve_milestones_path(&args.milestones_file)?;
    info!("Using milestones file: {}", milestones_path.display());

    // Process testnet environment
    let testnet_versions = process_environment(
        &client,
        "testnet",
        args.testnet_forc_wallet,
        args.testnet_fuel_core,
        args.testnet_sway,
    )?;

    // Process ignition/mainnet environments
    let mainnet_versions = process_environment(
        &client,
        "ignition/mainnet",
        args.mainnet_forc_wallet,
        args.mainnet_fuel_core,
        args.mainnet_sway,
    )?;

    // Update milestones.nix file
    update_milestones_file(&milestones_path, &testnet_versions, &mainnet_versions)?;

    // Generate PR description
    let pr_description = generate_pr_description(&testnet_versions, &mainnet_versions);

    // Output PR description
    if env::var("GITHUB_ENV").is_ok() {
        let github_env_path = env::var("GITHUB_ENV")?;
        let mut env_content = fs::read_to_string(&github_env_path).unwrap_or_default();
        env_content.push_str(&format!("PR_DESCRIPTION<<EOF\n{}\nEOF\n", pr_description));
        fs::write(&github_env_path, env_content)?;
        info!("PR description written to GITHUB_ENV");
    } else {
        println!("{}", pr_description);
    }
    Ok(())
}

fn build_http_client(github_token: &Option<String>) -> Result<reqwest::blocking::Client> {
    let mut headers = reqwest::header::HeaderMap::new();

    if let Some(token) = github_token {
        headers.insert(
            reqwest::header::AUTHORIZATION,
            reqwest::header::HeaderValue::from_str(&format!("Bearer {}", token))
                .context("Invalid GitHub token format")?,
        );
        info!("Using GitHub token for authentication");
    } else {
        info!("No GitHub token provided - requests may be rate limited");
    }

    headers.insert(
        reqwest::header::ACCEPT,
        reqwest::header::HeaderValue::from_static("application/vnd.github.v3+json"),
    );

    reqwest::blocking::Client::builder()
        .default_headers(headers)
        .build()
        .context("Failed to build HTTP client")
}

fn resolve_milestones_path(path: &PathBuf) -> Result<PathBuf> {
    let path = Path::new(path);

    // If it's an absolute path, use it directly
    if path.is_absolute() {
        return Ok(path.to_path_buf());
    }

    // If it's a relative path, resolve it relative to the current directory
    let current_dir = env::current_dir().context("Failed to get current directory")?;
    let resolved = current_dir.join(path);

    // Check if the file exists
    if !resolved.exists() {
        return Err(anyhow::anyhow!(
            "Milestones file not found at: {}",
            resolved.display()
        ));
    }

    Ok(resolved)
}

fn process_environment(
    client: &reqwest::blocking::Client,
    env_name: &str,
    forc_wallet_input: Option<String>,
    fuel_core_input: Option<String>,
    sway_input: Option<String>,
) -> Result<HashMap<String, ComponentVersion>> {
    info!("Processing {} environment", env_name);

    let mut versions = HashMap::new();

    versions.insert(
        "forc-wallet".to_string(),
        get_component_version(
            client,
            "forc-wallet",
            "FuelLabs/forc-wallet",
            forc_wallet_input,
        )?,
    );

    versions.insert(
        "fuel-core".to_string(),
        get_component_version(client, "fuel-core", "FuelLabs/fuel-core", fuel_core_input)?,
    );

    versions.insert(
        "sway".to_string(),
        get_component_version(client, "sway", "FuelLabs/sway", sway_input)?,
    );

    Ok(versions)
}

fn get_component_version(
    client: &reqwest::blocking::Client,
    component_name: &str,
    repo: &str,
    input: Option<String>,
) -> Result<ComponentVersion> {
    match input {
        Some(value) => {
            // Check if it's a commit hash (40 chars hex) or a tag
            if value.len() == 40 && value.chars().all(|c| c.is_ascii_hexdigit()) {
                info!("{}: Using provided commit hash: {}", component_name, value);
                // For a commit hash, we don't have the tag, so we'll use the hash as the tag too
                Ok(ComponentVersion {
                    tag: value.clone(),
                    commit_hash: value,
                })
            } else {
                // It's a tag, fetch the commit hash
                let tag = if value.starts_with('v') {
                    value
                } else {
                    format!("v{}", value)
                };
                info!("{}: Fetching commit hash for tag: {}", component_name, tag);
                let commit_hash = fetch_commit_hash_for_tag(client, repo, &tag)?;
                Ok(ComponentVersion { tag, commit_hash })
            }
        }
        None => {
            // Fetch latest release
            info!("{}: Fetching latest release", component_name);
            fetch_latest_release(client, repo)
        }
    }
}

fn fetch_latest_release(
    client: &reqwest::blocking::Client,
    repo: &str,
) -> Result<ComponentVersion> {
    let url = format!("https://api.github.com/repos/{}/releases/latest", repo);

    let request = client.get(&url).header("User-Agent", "update-milestones");

    let response = request
        .send()
        .context(format!("Failed to fetch latest release for {}", repo))?;

    if !response.status().is_success() {
        let status = response.status();
        let error_body = response
            .text()
            .unwrap_or_else(|_| "Unable to read error response".to_string());
        return Err(anyhow::anyhow!(
            "Failed to fetch latest release for {}: {} - {}",
            repo,
            status,
            error_body
        ));
    }

    let release: GitHubRelease = response
        .json()
        .context(format!("Failed to parse release response for {}", repo))?;

    let tag = release.tag_name;

    // Fetch the commit hash for this tag
    let commit_hash = fetch_commit_hash_for_tag(client, repo, &tag)?;

    info!(
        "Found latest release for {}: {} ({})",
        repo, tag, commit_hash
    );

    Ok(ComponentVersion { tag, commit_hash })
}

fn fetch_commit_hash_for_tag(
    client: &reqwest::blocking::Client,
    repo: &str,
    tag: &str,
) -> Result<String> {
    let url = format!("https://api.github.com/repos/{}/git/ref/tags/{}", repo, tag);

    let request = client.get(&url).header("User-Agent", "update-milestones");

    let response = request
        .send()
        .context(format!("Failed to fetch tag {} for {}", tag, repo))?;

    if !response.status().is_success() {
        let status = response.status();
        let error_body = response
            .text()
            .unwrap_or_else(|_| "Unable to read error response".to_string());
        return Err(anyhow::anyhow!(
            "Failed to fetch tag {} for {}: {} - {}",
            tag,
            repo,
            status,
            error_body
        ));
    }

    let tag_info: GitHubTag = response
        .json()
        .context(format!("Failed to parse tag response for {}", repo))?;

    Ok(tag_info.object.sha)
}

fn update_milestones_file(
    milestones_path: &Path,
    testnet_versions: &HashMap<String, ComponentVersion>,
    mainnet_versions: &HashMap<String, ComponentVersion>,
) -> Result<()> {
    info!("Updating milestones.nix file");

    let content =
        fs::read_to_string(milestones_path).context("Failed to read milestones.nix file")?;

    let mut lines: Vec<String> = content.lines().map(|s| s.to_string()).collect();

    // Update testnet section
    update_section(&mut lines, "testnet", testnet_versions)?;

    // Update ignition section
    update_section(&mut lines, "ignition", mainnet_versions)?;

    // Update mainnet section
    update_section(&mut lines, "mainnet", mainnet_versions)?;

    let mut updated_content = lines.join("\n");

    // Preserve the original file's trailing newline if it had one
    if content.ends_with('\n') {
        updated_content.push('\n');
    }

    fs::write(milestones_path, updated_content)
        .context("Failed to write updated milestones.nix file")?;

    info!("Successfully updated milestones.nix file");
    Ok(())
}

fn update_section(
    lines: &mut Vec<String>,
    section_name: &str,
    versions: &HashMap<String, ComponentVersion>,
) -> Result<()> {
    let section_pattern = format!(r"^\s*{}\s*=\s*\{{", section_name);
    let section_regex = Regex::new(&section_pattern)?;

    let mut in_section = false;
    let mut brace_count = 0;

    for i in 0..lines.len() {
        if !in_section && section_regex.is_match(&lines[i]) {
            in_section = true;
            brace_count = 1;
            continue;
        }

        if in_section {
            // Count braces to track when we exit the section
            brace_count += lines[i].matches('{').count() as i32;
            brace_count -= lines[i].matches('}').count() as i32;

            // Update component lines
            for (component, version) in versions {
                let component_pattern = format!(r#"^\s*{}\s*=\s*".*";"#, regex::escape(component));
                let component_regex = Regex::new(&component_pattern)?;

                if component_regex.is_match(&lines[i]) {
                    lines[i] = format!(r#"    {} = "{}";"#, component, version.commit_hash);
                    info!(
                        "Updated {} in {} section: {}",
                        component, section_name, version.commit_hash
                    );
                }
            }

            if brace_count == 0 {
                in_section = false;
            }
        }
    }

    Ok(())
}

fn generate_pr_description(
    testnet_versions: &HashMap<String, ComponentVersion>,
    mainnet_versions: &HashMap<String, ComponentVersion>,
) -> String {
    let mut description = String::new();
    description.push_str("Bump testnet, ignition and mainnet channels.\n\n");
    description.push_str("Testnet:\n");
    if let Some(version) = testnet_versions.get("forc-wallet") {
        description.push_str(&format!("`forc-wallet`: {}\n", version.tag));
    }
    if let Some(version) = testnet_versions.get("fuel-core") {
        description.push_str(&format!("`fuel-core`: {}\n", version.tag));
    }
    if let Some(version) = testnet_versions.get("sway") {
        description.push_str(&format!("`sway`: {}\n", version.tag));
    }
    description.push_str("\nIgnition & Mainnet:\n");
    if let Some(version) = mainnet_versions.get("forc-wallet") {
        description.push_str(&format!("`forc-wallet`: {}\n", version.tag));
    }
    if let Some(version) = mainnet_versions.get("fuel-core") {
        description.push_str(&format!("`fuel-core`: {}\n", version.tag));
    }
    if let Some(version) = mainnet_versions.get("sway") {
        description.push_str(&format!("`sway`: {}\n", version.tag));
    }
    description
}
