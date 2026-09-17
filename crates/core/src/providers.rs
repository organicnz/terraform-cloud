use std::path::{Path, PathBuf};

#[derive(Debug, Clone, PartialEq)]
pub enum StackKind {
    Vps,
    Dns,
    Unknown,
}

#[derive(Debug, Clone)]
pub struct ProviderProfile {
    pub id: String,
    pub display: String,
    pub dir: PathBuf,
    pub kind: StackKind,
    pub provider_sources: Vec<String>,
    pub var_names: Vec<String>,
    pub resource_types: Vec<String>,
    pub tf_file_count: usize,
    pub has_tfvars: bool,
    pub has_state: bool,
}

fn read_to_string(p: &Path) -> String {
    std::fs::read_to_string(p).unwrap_or_default()
}

/// Very small HCL-lite scanners: good enough for discovery, no HCL parser dep.
fn scan_sources(content: &str) -> Vec<String> {
    let mut out = Vec::new();
    // match only `source = "x"` as whole word, not source_ips/source_details
    let bytes = content.as_bytes();
    let mut i = 0;
    while i + 6 < content.len() {
        if &content[i..i + 6] == "source" {
            let prev_ok = i == 0 || {
                let c = bytes[i - 1] as char;
                !(c.is_alphanumeric() || c == '_' || c == '-')
            };
            let after = &content[i + 6..];
            let after_trim = after.trim_start();
            if prev_ok && after_trim.starts_with('=') {
                let val = after_trim[1..].trim_start();
                if val.starts_with('"') {
                    if let Some(end) = val[1..].find('"') {
                        let s = val[1..1 + end].to_string();
                        // skip local paths / module sources
                        if !s.starts_with('.')
                            && !s.starts_with('/')
                            && s.contains('/')
                            && !out.contains(&s)
                        {
                            out.push(s);
                        }
                    }
                }
            }
            i += 6;
        } else {
            i += 1;
        }
    }
    out
}

fn scan_variables(content: &str) -> Vec<String> {
    let mut out = Vec::new();
    let mut rest = content;
    while let Some(i) = rest.find("variable") {
        let chunk = &rest[i..];
        if let Some(a) = chunk.find('"') {
            if let Some(b) = chunk[a + 1..].find('"') {
                out.push(chunk[a + 1..a + 1 + b].to_string());
            }
        }
        rest = &chunk[8.min(chunk.len())..];
        if rest.len() < 10 {
            break;
        }
    }
    out
}

fn scan_resources(content: &str) -> Vec<String> {
    let mut out = Vec::new();
    let mut rest = content;
    while let Some(i) = rest.find("resource") {
        let chunk = &rest[i..];
        let parts: Vec<&str> = chunk.split('"').collect();
        if parts.len() >= 4 {
            out.push(format!("{}.{}", parts[1], parts[3]));
        }
        rest = &chunk[8.min(chunk.len())..];
        if rest.len() < 10 {
            break;
        }
    }
    out
}

fn analyze_dir(dir: &Path, require_prefix: bool) -> Option<ProviderProfile> {
    let id = dir.file_name()?.to_string_lossy().to_string();
    if id == "terraform-cloud" {
        return None;
    }
    let mut tf_files = Vec::new();
    let entries = std::fs::read_dir(dir).ok()?;
    for e in entries.flatten() {
        let p = e.path();
        if p.extension().map(|x| x == "tf").unwrap_or(false) {
            tf_files.push(p);
        }
    }
    if tf_files.is_empty() {
        // allow raindrop-style (no .tf) but mark unknown with 0 files
        if id.starts_with("terraform-") {
            return Some(ProviderProfile {
                display: id.clone(),
                id,
                dir: dir.to_path_buf(),
                kind: StackKind::Unknown,
                provider_sources: vec![],
                var_names: vec![],
                resource_types: vec![],
                tf_file_count: 0,
                has_tfvars: dir.join("terraform.tfvars").exists(),
                has_state: dir.join("terraform.tfstate").exists(),
            });
        }
        return None;
    }
    if require_prefix && !id.starts_with("terraform-") {
        // unified stacks use short names (hetzner, do); allow them only
        // when called from unified discovery
        return None;
    }
    let mut sources = Vec::new();
    let mut vars = Vec::new();
    let mut resources = Vec::new();
    for f in &tf_files {
        let c = read_to_string(f);
        for s in scan_sources(&c) {
            if !sources.contains(&s) {
                sources.push(s);
            }
        }
        for v in scan_variables(&c) {
            if !vars.contains(&v) {
                vars.push(v);
            }
        }
        for r in scan_resources(&c) {
            resources.push(r);
        }
    }
    let kind = if sources.iter().any(|s| s.contains("cloudflare")) {
        StackKind::Dns
    } else if tf_files.is_empty() {
        StackKind::Unknown
    } else {
        StackKind::Vps
    };
    Some(ProviderProfile {
        display: id.clone(),
        id,
        dir: dir.to_path_buf(),
        kind,
        provider_sources: sources,
        var_names: vars,
        resource_types: resources,
        tf_file_count: tf_files.len(),
        has_tfvars: dir.join("terraform.tfvars").exists(),
        has_state: dir.join("terraform.tfstate").exists()
            || dir.join("terraform.tfstate.backup").exists(),
    })
}

/// Discover stacks. Prefers unified `terraform-cloud/stacks/providers/*`,
/// falls back to sibling `terraform-*` dirs. `root` is usually `..` of terraform-cloud,
/// or terraform-cloud itself when running via `cargo run`.
pub fn discover_profiles(root: &Path) -> Vec<ProviderProfile> {
    // 1) unified layout: <root>/terraform-cloud/stacks/providers OR <root>/stacks/providers
    let candidates = [
        root.join("terraform-cloud/stacks/providers"),
        root.join("stacks/providers"),
    ];
    for unified in &candidates {
        if unified.is_dir() {
            let mut out = Vec::new();
            if let Ok(entries) = std::fs::read_dir(unified) {
                for e in entries.flatten() {
                    let p = e.path();
                    if !p.is_dir() {
                        continue;
                    }
                    // short names allowed here (hetzner, do, ...)
                    if let Some(mut prof) = analyze_dir(&p, false) {
                        // normalize display to terraform-<id> for continuity
                        if !prof.id.starts_with("terraform-") {
                            prof.display = format!("terraform-{}", prof.id);
                        }
                        out.push(prof);
                    }
                }
            }
            if !out.is_empty() {
                out.sort_by(|a, b| a.id.cmp(&b.id));
                return out;
            }
        }
    }
    // 2) legacy sibling layout
    let mut out = Vec::new();
    let entries = match std::fs::read_dir(root) {
        Ok(e) => e,
        Err(_) => return out,
    };
    for e in entries.flatten() {
        let p = e.path();
        if !p.is_dir() {
            continue;
        }
        let name = p
            .file_name()
            .unwrap_or_default()
            .to_string_lossy()
            .to_string();
        if !name.starts_with("terraform-") {
            continue;
        }
        if let Some(prof) = analyze_dir(&p, true) {
            out.push(prof);
        }
    }
    out.sort_by(|a, b| a.id.cmp(&b.id));
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn scanners_work() {
        let c =
            r#"variable "foo" {} resource "hcloud_server" "web" {} source = "hetznercloud/hcloud""#;
        assert!(scan_variables(c).contains(&"foo".to_string()));
        assert!(scan_resources(c)
            .iter()
            .any(|r| r.contains("hcloud_server")));
        assert!(scan_sources(c).iter().any(|s| s.contains("hetzner")));
    }
}
