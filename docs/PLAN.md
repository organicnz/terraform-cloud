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
- Copied `.tf` + `modules/` + `scripts|helpers/Makefile/*.yaml` + `*.tfvars.example`
- into `terraform-cloud/stacks/providers/<x>/`. Excluded `*.tfvars` (non-example),
  `.env`, `*.pem`, `*.tfstate*`, `tfplan`, `logs/`, `.terraform/`.
- Added explicit `backend local` per stack except contabo/oracle/ovhcloud (keep original).
- Fixed cloudnium: removed unavailable `anschoewe/virtualizor` provider dependency,
  removed `virtualizor_vps` resource, updated outputs. Now init + validate success.

## Phase 3 — harden
Remote backend per stack (s3+lock), `sensitive=true` everywhere,
`sops`/env secrets, CI `fmt/validate/tflint/tfsec`, remove `timestamp()` churn.

## Non-goals v1
No single mega-state. No secret rotation automation. No GUI changes.
