mod app;
mod widgets;

use anyhow::Result;
use cloud_core::{checks, discover_profiles};
use std::path::PathBuf;

fn parent_root() -> PathBuf {
    // terraform-cloud/ -> parent contains terraform-*
    std::env::current_dir()
        .unwrap_or(PathBuf::from("."))
        .join("..")
        .canonicalize()
        .unwrap_or(PathBuf::from(".."))
}

fn cmd_list() -> Result<()> {
    let profiles = discover_profiles(&parent_root());
    println!("{} stacks:", profiles.len());
    for p in &profiles {
        println!(
            "- {} dir={} tf={} vars={} res={} state={} providers={}",
            p.id,
            p.dir.display(),
            p.tf_file_count,
            p.var_names.len(),
            p.resource_types.len(),
            p.has_state,
            p.provider_sources.join(",")
        );
    }
    Ok(())
}

fn cmd_checks(stack: &str) -> Result<()> {
    let root = parent_root();
    let profiles = discover_profiles(&root);
    let Some(p) = profiles.iter().find(|x| x.id == stack) else {
        anyhow::bail!("stack not found: {}", stack);
    };
    for c in checks::all_checks(&p.dir) {
        let lvl = match c.level {
            checks::Level::Pass => "PASS",
            checks::Level::Warn => "WARN",
            checks::Level::Fail => "FAIL",
        };
        println!("[{lvl}] {} — {}", c.name, c.detail);
    }
    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    if args.iter().any(|a| a == "--list") {
        return cmd_list();
    }
    if let Some(i) = args.iter().position(|a| a == "--checks") {
        let stack = args.get(i + 1).cloned().unwrap_or_default();
        return cmd_checks(&stack);
    }
    app::run().await
}
