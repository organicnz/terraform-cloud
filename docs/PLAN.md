# PLAN — terraform-cloud unified stack

## Decision (user-confirmed)
- Location: `terraform-cloud/` (new, sibling of `terraform-*`)
- Strategy: monorepo multi-state
- TUI v1: full with diff + checks

## Phase 0 — inventory (done)
9 HCL stacks + raindrop Rust shell. Providers: azurerm/azuread, contabo,
digitalocean, hcloud, oci, ovh, cloudflare, timeweb-cloud, virtualizor.
All satisfy terraform >=1.5 (`v1.15.5` installed). No remote backends in use.
Secrets on disk in 8/9 stacks — must not copy secrets into new repo.

## Phase 1 — scaffold (done)
- [x] `terraform-cloud/` workspace (`cloud-core` + `cloud-tui`)
- [x] `providers.rs`: unified `stacks/providers/*` discovery + legacy `../terraform-*` fallback
- [x] `runner.rs`: init/validate/plan/show/apply/output via `terraform` binary
- [x] `checks.rs`: secrets/state/backend hygiene checks (offline, no creds)
- [x] `diff.rs`: plan diff + summary (ported from raindrop-core)
- [x] `tui`: provider list + Detail/Plan/Outputs/Checks/Logs tabs
- [x] `cargo check`, `cargo test`, `cargo fmt`

## Phase 2 — migrate (done)
- [x] All 9 providers: init + validate Success
- Copied `.tf` + `modules/` + `*.tfvars.example` into `terraform-cloud/stacks/providers/<x>/`.
  Excluded `*.tfvars` (non-example), `.env`, `*.pem`, `*.tfstate*`, `tfplan`, `logs/`, `.terraform/`.
  Note: `scripts|helpers/Makefile/*.yaml` not included in examples directory.
- Added explicit `backend local` per stack except contabo/oracle/ovhcloud (keep original).
- Fixed cloudnium: removed unavailable `anschoewe/virtualizor` provider dependency,
  removed `virtualizor_vps` resource, updated outputs. Now init + validate success.
- Azure: added `subscription_id` variable with default for Azure for Students subscription,
  updated `provider.tf` with `subscription_id`, changed `location` default to `eastasia`.

## Phase 3 — harden (in progress)
- [ ] Remote backend per stack (s3+lock) — currently all stacks use `backend "local"`
- [ ] `sensitive=true` everywhere on outputs — needs verification
- [ ] `sops`/env secrets integration
- [ ] CI `fmt/validate/tflint/tfsec`
- [ ] Remove `timestamp()` churn

## Non-goals v1
No single mega-state. No secret rotation automation. No GUI changes.
