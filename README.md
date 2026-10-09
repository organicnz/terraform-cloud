# terraform-cloud — unified multi-cloud stack

Monorepo multi-state orchestrator for all `terraform-*` providers with a Rust TUI selector.

Strategy: **monorepo multi-state** (one state per provider, TUI picks `working_dir`).
No mega-state. Originals in `..` stay untouched in v1; `stacks/` documents mapping.

## Layout

```
terraform-cloud/
  docs/PLAN.md
  Makefile
  Cargo.toml                 # workspace: crates/core + crates/tui
  crates/core/               # discovery + runner + checks + diff (no UI deps)
  crates/tui/                # ratatui selector (full: diff + checks)
  stacks/                    # per-provider notes, points at ../terraform-*
```

## Quick start

```bash
cd terraform-cloud
cargo run -p cloud-tui            # arrow keys / j,k select, p=plan o=outputs c=checks i=init v=validate q=quit
make list                         # list discovered stacks
make validate STACK=terraform-hetzner
make plan STACK=terraform-hetzner
```

## Safety

- Never `apply` from TUI without explicit `plan` first.
- Secrets stay in `TF_VAR_*` / ignored `.env`, never committed.
- Each stack keeps its own `terraform.tfstate` until remote backend migration.
- Azure: `subscription_id` defaults to the free Azure for Students subscription
  (`97e7954d-922c-49e9-b244-68753e6b316c`). Override via `TF_VAR_subscription_id` if needed.
- Secrets must be seeded and used via vars files, never committed to version control.
