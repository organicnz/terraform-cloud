use anyhow::{Context, Result};
use std::collections::HashMap;
use std::path::PathBuf;
use std::process::Stdio;
use tokio::io::{AsyncBufReadExt, BufReader};
use tokio::process::Command;

#[derive(Debug, Clone)]
pub struct TerraformRunner {
    pub working_dir: PathBuf,
    pub env_vars: HashMap<String, String>,
    pub binary: String,
}

impl TerraformRunner {
    pub fn new(working_dir: PathBuf) -> Self {
        Self {
            working_dir,
            env_vars: HashMap::new(),
            binary: "terraform".to_string(),
        }
    }

    pub fn with_env(mut self, k: &str, v: &str) -> Self {
        self.env_vars.insert(k.to_string(), v.to_string());
        self
    }

    fn cmd(&self, args: &[&str]) -> Command {
        let mut c = Command::new(&self.binary);
        c.args(args)
            .current_dir(&self.working_dir)
            .envs(&self.env_vars);
        c
    }

    pub async fn run_capture(&self, args: &[&str]) -> Result<String> {
        let out = self
            .cmd(args)
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()
            .await
            .with_context(|| format!("spawn {} {:?}", self.binary, args))?;
        let mut combined = String::from_utf8_lossy(&out.stdout).to_string();
        combined.push_str(&String::from_utf8_lossy(&out.stderr));
        if !out.status.success() {
            anyhow::bail!("{} {:?} failed:\n{}", self.binary, args, combined);
        }
        Ok(combined)
    }

    pub async fn run_stream<F>(&self, args: &[&str], on_line: F) -> Result<()>
    where
        F: Fn(String) + Send + 'static,
    {
        let mut child = self
            .cmd(args)
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .context("spawn terraform")?;
        // stream stdout; stderr merged into status only (keep simple, avoid deadlock)
        if let Some(stdout) = child.stdout.take() {
            let mut lines = BufReader::new(stdout).lines();
            while let Some(line) = lines.next_line().await? {
                on_line(line);
            }
        }
        let status = child.wait().await?;
        if !status.success() {
            anyhow::bail!("terraform {:?} exited {}", args, status);
        }
        Ok(())
    }

    pub async fn init(&self) -> Result<String> {
        self.run_capture(&["init", "-input=false"]).await
    }
    pub async fn validate(&self) -> Result<String> {
        self.run_capture(&["validate"]).await
    }
    pub async fn fmt_check(&self) -> Result<String> {
        self.run_capture(&["fmt", "-check", "-recursive", "-diff"])
            .await
    }
    pub async fn plan(&self) -> Result<String> {
        self.run_capture(&["plan", "-input=false", "-out=tfplan"])
            .await
    }
    pub async fn show_json(&self) -> Result<serde_json::Value> {
        let out = self
            .cmd(&["show", "-json", "tfplan"])
            .output()
            .await
            .context("terraform show")?;
        if !out.status.success() {
            anyhow::bail!("show failed: {}", String::from_utf8_lossy(&out.stderr));
        }
        Ok(serde_json::from_slice(&out.stdout)?)
    }
    pub async fn apply(&self) -> Result<String> {
        self.run_capture(&["apply", "-input=false", "-auto-approve", "tfplan"])
            .await
    }
    pub async fn output_json(&self) -> Result<serde_json::Value> {
        let out = self
            .cmd(&["output", "-json"])
            .output()
            .await
            .context("terraform output")?;
        if !out.status.success() {
            // no outputs is not fatal for TUI
            return Ok(serde_json::Value::Object(Default::default()));
        }
        if out.stdout.is_empty() {
            return Ok(serde_json::Value::Object(Default::default()));
        }
        Ok(serde_json::from_slice(&out.stdout).unwrap_or(serde_json::Value::Null))
    }
}
