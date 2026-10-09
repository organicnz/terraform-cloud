# Tailscale access control — tailnet `tailnet-7aa4`

Runbook for the personal Tailscale tailnet that carries this repo's CI runner and
the production software apps (`frontend`, `backend`).

The Azure VM in `stacks/providers/azure/runner/` (RG `ghrunner-rg`, VM
`ghrunner-vm`) deliberately provisions **no internet ingress**: the NSG has zero
rules (Azure default `DenyAllInBound`), the NIC has no public IP, and the VM sits
at `10.0.1.4`. Tailscale is the only way in.

## Topology — verified 2026-09-29

All six nodes owned by a single user, so `autogroup:member`/`admin` carries no
cross-tenant risk.

| Node | Tailscale IP | OS | Role |
|---|---|---|---|
| `organic` | `100.72.151.90` | macOS | admin workstation |
| `iphone-15-pro-max` | `100.87.144.103` | iOS | personal device |
| `frontend` | `100.99.241.23` | linux | app frontend |
| `backend` | `100.92.38.119` | linux | app backend |
| `github-runnervmtr4k5` | `100.93.53.72` | linux | CI runner |
| `ghrunner-vm` | `100.111.249.64` | linux | Azure runner (this repo) |

Nodes are addressed by **Tailscale IP, not tags**, because only `ghrunner-vm`
can be tagged from here. See "Tagging" below.

## Applied 2026-09-29

Verified in place after the change:

- **Tailscale SSH enabled** on `ghrunner-vm` (`RunSSH: true`). Claims port 22
  on the Tailscale IP only; `authorized_keys` untouched. There is no OpenSSH
  daemon installed, so this is now the *only* SSH surface.
- **`--accept-dns=false`** so Azure DNS (`168.63.129.16`) keeps precedence.
- **UFW active**, `deny incoming` / `allow outgoing`, with explicit allows for
  `tailscale0`, `tunl0`, `168.63.129.16` (Azure platform) and `169.254.169.254`
  (IMDS). Verified after the change: waagent still reaches IMDS
  (`IMDS_OK`), `tailscaled` active, containers healthy.

## Exposure surface — measured

| Check | Result |
|---|---|
| NSG rules | zero → `DenyAllInBound` |
| Public IP | none |
| `ss -tlnp` on `0.0.0.0` | **nothing** |
| Container published ports | **none** (all `ghrunner-runner` containers) |
| `sshd` / `ssh.socket` | both inactive — no OpenSSH daemon |
| UFW | active, default-deny inbound |
| Funnel / Serve | no serve config |
| Tailscale version | `1.102.4` (clears TS-2026-006 floor of 1.98.9) |

**Direct Tailscale connections work** despite the empty NSG: Tailscale dials
outbound UDP and Azure NSGs are stateful, so return traffic flows without an
inbound rule. Tailscale's [Azure guide](https://tailscale.com/kb/1142/cloud-azure-linux)
recommends allowing UDP 41641 ingress — that is latency advice for NAT-blocked
paths, unnecessary here, and following it would widen the NSG for no benefit.

## The critical gap: no policy file existed

Tailscale applies **default-allow-all** when no `acls` section is present, so
every node could reach every other on every port. `tailnet-policy.hujson`
replaces that.

**It is not a blanket default-deny, by design.** `frontend` → `backend` is the
production API path; a policy omitting it breaks the software. The draft:

```jsonc
"grants": [
  { "src": ["100.99.241.23"], "dst": ["100.92.38.119"], "ip": ["tcp:*"] },
  { "src": ["100.72.151.90"], "dst": ["100.111.249.64"], "ip": ["tcp:22"] }
]
```

Reverse direction (`backend` → `frontend`) is deliberately not granted.

## Applying

1. Replace `REPLACE_WITH_ADMIN_EMAIL` in both `tests` entries with the Tailscale
   login email. The console runs `tests` on save and rejects a policy whose
   assertions fail.
2. Admin console → Access Controls → JSON editor → paste → Save.
3. Verify: `tailscale ssh --check organic@ghrunner-vm`

Roll back by restoring the previous (empty) policy — but note that reverts to
default-allow-all.

### Tightening the app grant

`tcp:*` on frontend→backend is deliberately loose because the ports the app uses
are not recorded in this repo, and guessing them has an outage as the failure
mode. To narrow it, find the real ports from the app side and substitute:

```jsonc
{ "src": ["100.99.241.23"], "dst": ["100.92.38.119"], "ip": ["tcp:443", "tcp:5432"] }
```

### Tagging

Tag-based grants survive IP reassignment and let `grants` target a role rather
than an address. Only `ghrunner-vm` is taggable from this machine; tagging
`frontend`/`backend` requires access to those hosts.

```sh
az vm run-command invoke -g ghrunner-rg -n ghrunner-vm \
  --command-id RunShellScript \
  --scripts "tailscale set --advertise-tags=tag:ghrunner" \
  --query "value[].message" -o tsv
```

Note: `tailscale set --advertise-tags` is **not available in CLI 1.102.4**
(`flag provided but not defined`) — apply tags from the admin console instead.
Tagging also disables key expiry for the node by default, which is correct for
infrastructure; the untagged node's key currently expires `2027-03-27`.

## Access without Tailscale

`az vm run-command invoke` bypasses the NSG and UFW entirely — waagent-mediated
over the Azure management fabric, not the VNet. It runs as root and is the
recovery path if `tailscaled` dies.

```sh
az vm run-command invoke -g ghrunner-rg -n ghrunner-vm \
  --command-id RunShellScript --scripts "uname -a" \
  --query "value[].message" -o tsv
```

Use `invoke`. The bare `az vm run-command` subcommand is deprecated and fails
with a misleading `'ghrunner-rg' is misspelled or not recognized by the system`.

**This depends on an interactive `az login` — currently a personal MSA holding
`Owner` on the subscription.** There is no service principal, so no non-human
identity can reach this VM. That is the real single point of failure: losing
that account makes the box unreachable and unrecreatable, and the Tailscale auth
key is stored nowhere (`cloud-init.sh:22-24` deliberately keeps it out).

## References

- [Security best practices](https://tailscale.com/docs/reference/best-practices/security)
- [Device hardening](https://tailscale.com/docs/reference/best-practices/device-hardening.md)
- [Grants syntax](https://tailscale.com/docs/reference/syntax/grants) — supersedes ACLs
- [Tailscale SSH](https://tailscale.com/docs/features/tailscale-ssh.md)
- [Security bulletins](https://tailscale.com/security-bulletins/index.xml)