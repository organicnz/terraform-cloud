# terraform-cloud 🌍 — unified multi-cloud stack

Monorepo multi-state orchestrator for all `terraform-*` providers with a Rust
TUI selector. One repository holds every cloud stack, a shared Rust core for
driving `terraform`, and a terminal UI for planning, diffing and hygiene
checking across all of them.

![Strategy](https://img.shields.io/badge/Strategy-monorepo--multi--state-6b46c1?style=for-the-badge)
![Rust](https://img.shields.io/badge/rust-1.70%2B-dea584?style=for-the-badge)
![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.5-7b42bc?style=for-the-badge)
![License](https://img.shields.io/badge/license-MIT-2ea44f?style=for-the-badge)

---

## What this is

Nine clouds, nine Terraform stacks, one place to look at them:

- **One repo, nine stacks.** `stacks/providers/<name>/` holds the HCL for each
  provider. Each stack keeps its own state — there is no mega-state.
- **A shared Rust core.** `cloud-core` discovers stacks, runs `terraform`,
  parses plan JSON into a field-level diff, and runs offline hygiene checks.
  It has no UI dependencies, so it can be reused headless.
- **A terminal UI.** `cloud-tui` renders the provider list, plan diffs, outputs
  and check results in a `ratatui` interface.

The point is consistency: one set of commands, one safety model, one place to
look when something across providers needs attention.

---

## Layout

```text
terraform-cloud/
  Cargo.toml                 # workspace: crates/core + crates/tui
  Makefile                   # the command surface — prefer this over raw terraform
  LICENSE                    # MIT
  CONTRIBUTING.md            # how to help
  docs/PLAN.md               # phases, decisions, and what is still pending
  crates/
    core/                    # cloud-core — discovery + runner + checks + diff
      src/providers.rs       # stack discovery + HCL-lite scanning
      src/runner.rs          # terraform subprocess wrapper
      src/checks.rs          # offline hygiene checks
      src/diff.rs            # plan JSON -> field-level diff
    tui/                     # cloud-tui — ratatui interface
      src/app.rs             # event loop, key handling, tabs
      src/widgets/           # provider list, plan diff, checks view
  stacks/
    providers/<name>/        # one Terraform stack per cloud provider
  tailscale/                 # tailnet ACL runbook + policy file
```

---

## Requirements

| Tool | Version | Needed for |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | >= 1.5 | All stacks declare `required_version >= 1.5`. |
| [Rust](https://rustup.rs) | stable (1.70+) | Building `cloud-core` and `cloud-tui`. |
| GNU Make | any | The `Makefile` targets below. |

No cloud credentials are needed for `validate`, the unit tests, or the hygiene
checks — all of those run offline.

---

## Quick start

```bash
git clone https://github.com/organicnz/terraform-cloud.git
cd terraform-cloud

cargo build          # builds cloud-core + cloud-tui
cargo test           # unit tests

cargo run -p cloud-tui             # launch the TUI
cargo run -p cloud-tui -- --list   # list discovered stacks
make list                          # same, via the Makefile
```

### TUI keybindings

| Key | Action |
|---|---|
| `j` / `k` or `↓` / `↑` | Move down / up the provider list |
| `1`–`5` or `Tab` | Switch tab: Detail, Plan, Outputs, Checks, Logs |
| `p` | `terraform plan` for the selected stack |
| `o` | `terraform output -json` for the selected stack |
| `c` | Run hygiene checks on the selected stack |
| `i` | `terraform init` |
| `v` | `terraform validate` |
| `f` | `terraform fmt -check -recursive -diff` |
| `q` / `Esc` | Quit |

There is deliberately **no `apply` key**. See [Safety](#safety-️).

### Makefile

`make help` lists everything. The common ones:

```bash
make list                                # list all stacks
make init      STACK=hetzner             # terraform init
make validate  STACK=hetzner             # terraform validate
make fmt       STACK=hetzner             # terraform fmt -check
make plan      STACK=hetzner             # terraform plan
make output    STACK=hetzner             # terraform output
make checks    STACK=hetzner             # offline hygiene checks

make init-all                              # every stack
make validate-all
make fmt-all
make check-all
```

Stack names: `hetzner`, `do`, `contabo`, `timeweb`, `cloudflare`, `azure`,
`oracle`, `ovhcloud`, `cloudnium`. The `terraform-*` aliases
(`terraform-hetzner`, …) are accepted for backwards compatibility.

---

## Stacks

| Stack | Provider | Kind |
|---|---|---|
| `stacks/providers/hetzner/` | Hetzner Cloud | VPS |
| `stacks/providers/do/` | DigitalOcean | VPS |
| `stacks/providers/contabo/` | Contabo | VPS |
| `stacks/providers/timeweb/` | Timeweb Cloud | VPS |
| `stacks/providers/cloudflare/` | Cloudflare | DNS |
| `stacks/providers/azure/` | Azure | VM + CI runner |
| `stacks/providers/oracle/` | Oracle Cloud | VPS |
| `stacks/providers/ovhcloud/` | OVHcloud | VPS + monitoring |
| `stacks/providers/cloudnium/` | Cloudnium (Virtualizor) | VPS |

Each stack is self-contained: its own `backend.tf`, `provider.tf`,
`variables.tf`, `outputs.tf`, `versions.tf` and a
`terraform.tfvars.example` template. Real values are never committed.

`stacks/providers/azure/runner/` provisions the self-hosted CI runner, and
`tailscale/` carries the runbook for the tailnet that reaches it.

---

## Safety 🛡️

- ❌ **Never `apply` from the TUI.** The `apply` method exists in `cloud-core`
  but is deliberately not bound to a key. Plan first, read the diff, then apply
  by hand.
- 🔐 **Secrets stay in `TF_VAR_*` or an ignored `.env`.** Never committed —
  see the secrets section of [CONTRIBUTING.md](CONTRIBUTING.md).
- 📁 **Each stack keeps its own `terraform.tfstate`** until remote backends
  are migrated. State may contain live resource IDs and IPs, so it is ignored
  and never pasted into issues.
- 💙 **Azure:** `subscription_id` defaults to the Azure for Students
  subscription (`97e7954d-922c-49e9-b244-68753e6b316c`). Override via
  `TF_VAR_subscription_id`.
- 🛡️ **The runner VM has no public ingress.** The Azure NSG is
  `DenyAllInBound`, the NIC has no public IP, and Tailscale SSH is the only
  way in. Do not open the NSG as a debugging shortcut.

---

## Hygiene checks 🩺

`cloud-core` runs offline checks that never read a secret value — only whether
one is *present*:

```bash
make checks STACK=hetzner
```

```text
[PASS] terraform.tfvars present — absent (uses env/example)
[PASS] .env present — absent
[PASS] private keys — no *.pem in stack root
[WARN] local state — local tfstate exists; migrate to remote with lock
[PASS] backend config — backend block found
[PASS] versions.tf — present
```

The checks cover live key material, on-disk `terraform.tfvars` and `.env`,
local state, backend configuration, and version pinning. `FAIL` means fix it
before pushing.

---

## Status

Phases 0–2 are done: the 9 stacks were inventoried and migrated, discovery
and the TUI were built, and every stack reaches `init` + `validate` cleanly.
`docs/PLAN.md` tracks the current phase.

**Phase 3 — hardening (in progress):**

- [ ] Remote backend per stack (S3 + lock) — all stacks still use `backend "local"`
- [ ] `sensitive = true` on all outputs — needs verification
- [ ] `sops` / env-based secrets integration
- [ ] CI running `fmt` / `validate` / `tflint` / `tfsec`
- [ ] Remove `timestamp()` churn from resources

Open issues track the work — see [Issues](https://github.com/organicnz/terraform-cloud/issues).

---

## Contributing

Contributions are welcome, including from first-time Terraform and Rust
authors. Issues tagged `good first issue` are scoped for newcomers.

- 🐛 Report a bug, or 💡 propose a feature via
  [issues](https://github.com/organicnz/terraform-cloud/issues/new)
- 📖 **[CONTRIBUTING.md](CONTRIBUTING.md)** — setup, ground rules, PR process,
  code style, and how to add a new provider stack
- 🔒 Report vulnerabilities through
  [GitHub's private vulnerability reporting](https://github.com/organicnz/terraform-cloud/security/advisories/new),
  not a public issue

---

## License

[MIT](LICENSE) © 2026 Tarlan Isaev. See [LICENSE](LICENSE) for the full text.
