# stacks/ — mapping to ../terraform-* (v1: reference, no copy)

v1 discovers siblings automatically via `cloud-core::discover_profiles(..)`.
Physical import happens in Phase 2, one provider at a time (hetzner first).

Expected finals:
- stacks/providers/hetzner/ <- ../terraform-hetzner (.tf only)
- stacks/providers/do/ <- ../terraform-do
- stacks/providers/contabo/ <- ../terraform-contabo
- stacks/providers/ovhcloud/ <- ../terraform-ovhcloud
- stacks/providers/oracle/ <- ../terraform-oracle
- stacks/providers/azure/ <- ../terraform-azure (subscription_id variable added, location default changed to eastasia)
- stacks/providers/cloudflare/ <- ../terraform-cloudflare
- stacks/providers/timeweb/ <- ../terraform-timeweb
- stacks/providers/cloudnium/ <- ../terraform-cloudnium
