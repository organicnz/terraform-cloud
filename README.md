# terraform-cloud 🌍 — unified multi-cloud stack

Monorepo multi-state orchestrator for all `terraform-*` providers with a Rust TUI selector.

![Strategy](https://img.shields.io/badge/Strategy-monorepo--multi--state-6b46c1?style=for-the-badge)

---

## Layout

```text
terraform-cloud/
  docs/PLAN.md
  Makefile
  Cargo.toml                 # workspace: crates/core + crates/tui
  crates/core/               # discovery + runner + checks + diff (no UI deps)
  crates/tui/                # ratatui selector (full: diff + checks)
  stacks/                    # per-provider notes, points at ../terraform-*
```

---

## Quick start

```bash
cd terraform-cloud
cargo run -p cloud-tui            # arrow keys / j,k select, p=plan o=outputs c=checks i=init v=validate q=quit
make list                         # list discovered stacks
make validate STACK=terraform-hetzner
make plan STACK=terraform-hetzner
```

---

## Safety 🛡️

- ❌ Never `apply` from TUI without explicit `plan` first.
- 🔐 Secrets stay in `TF_VAR_*` / ignored `.env`, never committed.
- 📁 Each stack keeps its own `terraform.tfstate` until remote backend migration.
- 💙 Azure: `subscription_id` defaults to the free Azure for Students subscription
  (`97e7954d-922c-49e9-b244-68753e6b316c`). Override via `TF_VAR_subscription_id` if needed.
- ⚠️ **Secrets must be seeded and used via vars files, never committed to version control.**
- 🏗️ **Phase 3 hardening in progress** — remote backends (s3+lock), `sensitive=true` on outputs,
  `sops`/env secrets integration, and CI `fmt/validate/tflint/tfsec` are pending.

---

## Next steps 🚀

- Run `make list` to discover stacks
- Start the TUI selector: `cargo run -p cloud-tui`
- Track hardening progress in `docs/PLAN.md`

---

## Stack mapping 📍

| Stack | Original |
|---|---|
| stacks/providers/hetzner/ | ../terraform-hetzner (.tf only) |
| stacks/providers/do/ | ../terraform-do |
| stacks/providers/contabo/ | ../terraform-contabo |
| stacks/providers/ovhcloud/ | ../terraform-ovhcloud |
| stacks/providers/oracle/ | ../terraform-oracle |
| stacks/providers/azure/ | ../terraform-azure (subscription_id variable added, location default changed to eastasia, backend local) |
| stacks/providers/cloudflare/ | ../terraform-cloudflare |
| stacks/providers/timeweb/ | ../terraform-timeweb |
| stacks/providers/cloudnium/ | ../terraform-cloudnium |