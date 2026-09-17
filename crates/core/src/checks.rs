use std::path::Path;

#[derive(Debug, Clone)]
pub enum Level {
    Pass,
    Warn,
    Fail,
}

#[derive(Debug, Clone)]
pub struct StackCheck {
    pub name: String,
    pub level: Level,
    pub detail: String,
}

fn has(p: &Path) -> bool {
    p.exists()
}

/// Offline hygiene checks. Never reads secret values, only presence.
pub fn all_checks(dir: &Path) -> Vec<StackCheck> {
    let mut out = Vec::new();

    // tfvars present (expected, but must be gitignored)
    let tfvars = dir.join("terraform.tfvars");
    out.push(if has(&tfvars) {
        StackCheck {
            name: "terraform.tfvars present".into(),
            level: Level::Warn,
            detail: "exists on disk; ensure gitignored, prefer TF_VAR_*".into(),
        }
    } else {
        StackCheck {
            name: "terraform.tfvars present".into(),
            level: Level::Pass,
            detail: "absent (uses env/example)".into(),
        }
    });

    // .env present
    out.push(if has(&dir.join(".env")) || has(&dir.join(".env.local")) {
        StackCheck {
            name: ".env present".into(),
            level: Level::Warn,
            detail: ".env on disk; ensure gitignored".into(),
        }
    } else {
        StackCheck {
            name: ".env present".into(),
            level: Level::Pass,
            detail: "absent".into(),
        }
    });

    // private keys
    let mut pems = Vec::new();
    if let Ok(entries) = std::fs::read_dir(dir) {
        for e in entries.flatten() {
            let p = e.path();
            if p.extension().map(|x| x == "pem").unwrap_or(false) {
                pems.push(
                    p.file_name()
                        .unwrap_or_default()
                        .to_string_lossy()
                        .to_string(),
                );
            }
        }
    }
    // also keys/ subdir
    if dir.join("keys").exists() {
        pems.push("keys/".into());
    }
    out.push(if pems.is_empty() {
        StackCheck {
            name: "private keys".into(),
            level: Level::Pass,
            detail: "no *.pem in stack root".into(),
        }
    } else {
        StackCheck {
            name: "private keys".into(),
            level: Level::Fail,
            detail: format!("live key material on disk: {}", pems.join(",")),
        }
    });

    // state present
    let state = has(&dir.join("terraform.tfstate"))
        || has(&dir.join("terraform.tfstate.backup"))
        || dir.join("terraform.tfstate.d").exists();
    out.push(if state {
        StackCheck {
            name: "local state".into(),
            level: Level::Warn,
            detail: "local tfstate exists; migrate to remote with lock".into(),
        }
    } else {
        StackCheck {
            name: "local state".into(),
            level: Level::Pass,
            detail: "no local state".into(),
        }
    });

    // backend block
    let mut has_backend = false;
    if let Ok(entries) = std::fs::read_dir(dir) {
        for e in entries.flatten() {
            let p = e.path();
            if p.extension().map(|x| x == "tf").unwrap_or(false) {
                if let Ok(c) = std::fs::read_to_string(&p) {
                    if c.contains("backend \"") && !c.trim_start().starts_with('#') {
                        // crude: active backend line (commented lines still contain it;
                        // accept as hint)
                        has_backend = true;
                    }
                }
            }
        }
    }
    out.push(if has_backend {
        StackCheck {
            name: "backend config".into(),
            level: Level::Pass,
            detail: "backend block found (verify not all commented)".into(),
        }
    } else {
        StackCheck {
            name: "backend config".into(),
            level: Level::Warn,
            detail: "implicit local backend".into(),
        }
    });

    // versions pin
    let versions = dir.join("versions.tf");
    out.push(if has(&versions) {
        StackCheck {
            name: "versions.tf".into(),
            level: Level::Pass,
            detail: "present".into(),
        }
    } else {
        StackCheck {
            name: "versions.tf".into(),
            level: Level::Warn,
            detail: "missing; add required_version + provider pins".into(),
        }
    });

    out
}
