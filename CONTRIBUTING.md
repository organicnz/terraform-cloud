# Contributing to terraform-cloud 🌍

Thanks for your interest in improving this project! This is a collaborative
infrastructure repo — a monorepo of Terraform stacks for nine cloud providers
with a Rust TUI that drives them. Contributions of all sizes are welcome, from
a one-line docs fix to a whole new provider stack.

This document explains how to get set up, what we expect from a pull request,
and the rules that keep this repo safe for everyone.

---

## Table of contents

- [Ways to contribute](#ways-to-contribute)
- [Ground rules](#ground-rules)
- [Getting set up](#getting-set-up)
- [Repository layout](#repository-layout)
- [Working on an issue](#working-on-an-issue)
- [Opening a pull request](#opening-a-pull-request)
- [Checks to run before you push](#checks-to-run-before-you-push)
- [Code style](#code-style)
- [Adding a new provider stack](#adding-a-new-provider-stack)
- [Safety rules](#safety-rules)
- [Reporting a security issue](#reporting-a-security-issue)
- [License](#license)

---

## Ways to contribute

| Contribution | Where to start |
|---|---|
| 🐛 **Bug report** | [Open an issue](https://github.com/organicnz/terraform-cloud/issues/new) — include the stack name, the command you ran, and the output. |
| 💡 **Feature idea** | [Open an issue](https://github.com/organicnz/terraform-cloud/issues/new) and describe the workflow you want. Discussion first beats a large PR that gets rewritten. |
| 📖 **Docs** | The `docs/`, `stacks/README.md` and `tailscale/README.md` files are all contributor-facing. Small improvements are welcome as direct PRs. |
| 🌐 **New provider stack** | See [Adding a new provider stack](#adding-a-new-provider-stack). This is a bigger change — please open an issue before writing HCL. |
| 🛠️ **Rust code** | `crates/core` (logic, no UI deps) and `crates/tui` (ratatui interface) are both good first targets. Issues tagged `good first issue` are scoped for newcomers. |
| 🔍 **Review** | Reading a PR and leaving a concrete comment is a real contribution. We are a small project and review capacity is the scarcest resource we have. |

---

## Ground rules

These are non-negotiable. They protect contributors, the project, and anyone
who later runs this code against a real cloud account.

1. **Never commit secrets.** No API tokens, no SSH private keys, no
   `terraform.tfvars` containing real values, no `.env` with live credentials.
   Use `TF_VAR_*` environment variables or the `*.tfvars.example` files as
   templates. See [Ground rules → secrets](#1-never-commit-secrets) below.
2. **Never commit state or plan files.** `*.tfstate`, `*.tfstate.backup`,
   `tfplan`, and `*.tfplan` are ignored by `.gitignore` — do not force-add
   them with `git add -f`.
3. **Never run `apply` against a stack you have not read.** Plan first, read
   the diff, then apply. See [Safety rules](#safety-rules).
4. **One logical change per PR.** A PR that changes the Azure stack *and*
   rewrites the TUI is hard to review and hard to revert. Split it.
5. **Leave the tree buildable.** `cargo check`, `cargo test`, and
   `terraform validate` must pass on every stack you touched.

### 1. Never commit secrets

The `.gitignore` already excludes the common offenders, but gitignore is a
safety net, not a guarantee. Before you commit, check:

```bash
git diff --cached | grep -iE 'token|secret|password|api_key|private_key'
```

If you *do* accidentally commit a credential, do not just delete the file in a
follow-up commit — the object stays in history. Rotate the credential first,
then rewrite the history (`git filter-repo` or BFG) and force-push. If the
credential was ever pushed to a public remote, **treat it as compromised and
rotate it immediately**, even if you deleted it right away.

The `crates/core/src/checks.rs` module runs offline hygiene checks that flag
live key material, on-disk `terraform.tfvars`, and local state. Run them
before pushing:

```bash
make checks STACK=hetzner
```

---

## Getting set up

### Prerequisites

| Tool | Version | Notes |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | >= 1.5 | The stacks use `required_version` >= 1.5. |
| [Rust](https://rustup.rs) | stable | `cargo` 1.70+ is enough; the workspace is edition 2021. |
| GNU Make | any | The `Makefile` is the main entry point. |
| [Tailscale](https://tailscale.com/download) | >= 1.98.9 | Only needed for the `tailscale/` runbook and the CI runner. |

> **Note on credentials:** you do **not** need live cloud credentials to work
> on this repo. `terraform validate`, the Rust unit tests, and the hygiene
> checks all run offline. Plan against real infrastructure only when a task
> genuinely requires it.

### Setup

```bash
git clone https://github.com/organicnz/terraform-cloud.git
cd terraform-cloud
cargo build          # builds cloud-core + cloud-tui
cargo test           # unit tests
```

The Rust workspace has no code-generation step and no build script, so
`cargo build` is the entire setup.

---

## Repository layout

```text
terraform-cloud/
  Cargo.toml                  # workspace root: crates/core + crates/tui
  Makefile                    # the command surface — prefer this over raw terraform
  LICENSE
  CONTRIBUTING.md
  docs/PLAN.md                # phases, decisions, and what is still pending
  crates/
    core/                     # cloud-core — no UI dependencies
      src/providers.rs        # stack discovery + HCL-lite scanning
      src/runner.rs           # terraform subprocess wrapper
      src/checks.rs           # offline hygiene checks
      src/diff.rs             # plan JSON -> field-level diff
    tui/                      # cloud-tui — ratatui interface
      src/app.rs              # event loop, key handling, tabs
      src/widgets/            # provider list, plan diff, checks view
  stacks/
    providers/<name>/         # one Terraform stack per cloud provider
  tailscale/                  # tailnet ACL runbook + policy file
```

Two Rust crates, deliberately split:

- **`cloud-core`** holds all the logic and depends on **no UI code**. If you
  want to reuse the orchestrator from a script, a CLI, or a different TUI,
  depend on this crate. It is the right place for new behaviour.
- **`cloud-tui`** is the `ratatui` front end. It renders what `cloud-core`
  reports and sends key events back. Keep UI concerns here.

---

## Working on an issue

1. **Claim it.** Comment on the issue before you start so two people don't
   duplicate work.
2. **Ask questions in the issue**, not in your head — the answer helps the next
   person too.
3. **Keep the change focused.** If a fix turns into a redesign, stop and open
   a new issue.
4. **Reference the issue** in your PR description (`Closes #42`).

If you find a bug but have no time to fix it, opening a high-quality issue is
already a contribution.

---

## Opening a pull request

### Branch naming

Use a short, descriptive branch off `master`:

```text
feature/<short-description>     # e.g. feature/remote-backend-s3
fix/<short-description>         # e.g. fix/ovhcloud-fmt
docs/<short-description>        # e.g. docs/plan-phase-4
chore/<short-description>       # e.g. chore/ci-workflow
```

One branch per issue. If your change grows past a few hundred lines, consider
splitting it into a stack of small PRs that each pass review on their own.

### Commit messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) style:

```text
<type>(<scope>): <subject>

<optional body explaining why, not what>

<optional footer with issue refs>
```

Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`,
`build`, `ci`, `chore`.

Good examples:

```text
feat(core): add --json flag to the checks command
fix(tui): stop plan job from overwriting logs on error
docs(stacks): explain the contabo backend exception
```

Avoid vague subjects like `fix stuff` or `wip`. If you must, use
`git commit --amend` before pushing rather than adding a "fixed typo" commit.

### PR description

A good PR description lets a reviewer approve without asking follow-up
questions. Include:

- **What** changed and **why** (the motivation, not a restatement of the diff).
- **Which stacks** are affected.
- **How you verified it** — the exact commands you ran and their result.
- A **screenshot** for any TUI change.
- `Closes #<n>` when the PR resolves an issue.

### Review

- Two maintainers' eyes are better than one; small PRs get reviewed faster.
- Reviewers may ask for changes. That is normal, not a rejection.
- Address review comments with new commits during review, then squash-merge.
  Do not rewrite published history — force-pushing to a shared branch makes
  review impossible.

---

## Checks to run before you push

Run these locally. CI is not wired up yet (tracked in `docs/PLAN.md`), so your
local run *is* the check.

### Everything

```bash
cargo fmt --all -- --check     # Rust formatting
cargo clippy --workspace --all-targets -- -D warnings
cargo test
terraform fmt -check -recursive stacks/providers
```

### Per stack

```bash
make init     STACK=hetzner
make validate STACK=hetzner
make checks   STACK=hetzner
```

`make validate-all` and `make check-all` run the same checks across all nine
stacks. The full list of stack names is in the `STACKS` variable at the top of
the `Makefile`.

### Before you open the PR

Re-read your own diff. Look for:

- [ ] Committed secrets, state, or plan files
- [ ] Debug output (`dbg!`, `println!` in library code, commented-out blocks)
- [ ] Unrelated reformatting — it buries the real change
- [ ] New files that should be in `.gitignore`

---

## Code style

### Rust

- **`rustfmt` is the source of truth.** Run `cargo fmt --all` before pushing.
- **`clippy` must be clean** with `-D warnings`.
- Prefer `?` and `anyhow::Context` over manual error handling. The codebase
  uses `anyhow` for application errors — do not introduce a new error-handling
  dependency without discussion.
- Keep `cloud-core` free of UI dependencies. It should stay usable headless.
- Add a `#[cfg(test)] mod tests` block for new pure functions. The existing
  HCL-lite scanners in `providers.rs` are the reference for how to test this
  kind of code.

### Terraform

- **`terraform fmt` is the source of truth.** `make fmt STACK=<name>` checks
  it; `terraform fmt -recursive stacks/providers/<name>` applies it.
- **`terraform validate` must pass** for every stack you touch.
- Pin provider versions in `versions.tf` and declare `required_version`.
- Prefer explicit `backend` blocks — an implicit local backend is treated as a
  warning by the hygiene checks.
- Mark sensitive outputs with `sensitive = true`. A "sensitive" value printed
  in CI logs is still a leaked value.
- One stack per provider directory. Do not merge two providers into one state.
- Document new variables in `variables.tf` with a `description`, and add a
  matching entry to `terraform.tfvars.example`.

### Commit hygiene

- Do not commit `Cargo.lock` for the workspace if it is already ignored — the
  current `.gitignore` excludes it, matching the upstream convention for
  library-style crates.
- Do not reformat files you did not otherwise touch.

---

## Adding a new provider stack

This is the most substantial contribution, so please open an issue first to
agree on scope. The shape of a new stack is:

```text
stacks/providers/<name>/
  backend.tf                 # explicit backend block
  provider.tf                # provider configuration
  variables.tf               # all variables, with descriptions
  outputs.tf                 # outputs, sensitive ones marked
  versions.tf                # required_version + provider version pins
  terraform.tfvars.example   # template only — never real values
  main.tf                    # resources
```

Then:

1. Add the stack name to the `STACKS` variable in the `Makefile`.
2. Confirm discovery works: `cargo run -p cloud-tui -- --list`.
3. Add the row to the stack mapping table in `README.md` and `stacks/README.md`.
4. Update `docs/PLAN.md` with what changed.
5. Run `make init`, `make validate`, and `make checks` for the new stack.

---

## Safety rules

This repo manages real infrastructure for a real cloud account. A careless
change here can cost money, leak credentials, or take something down.

- **Plan before you apply.** Always. Read the diff.
- **The TUI never applies.** The `apply` method exists in `cloud-core` but is
  deliberately not bound to a key. Do not add a key binding for it without a
  very good reason and a maintainer conversation.
- **State is precious.** A `terraform.tfstate` in this repo may hold resource
  IDs and IPs for live machines. Do not paste its contents into an issue.
- **The `tailscale/` policy is load-bearing.** The tailnet is default-allow-all
  without `tailnet-policy.hujson`. Editing it can lock you — or everyone —
  out of the runner VM. Read `tailscale/README.md` end to end before changing
  it, and keep the `frontend` → `backend` grant intact.
- **The runner VM has no public ingress by design.** The Azure NSG is
  `DenyAllInBound` and the only way in is Tailscale SSH. Do not open the NSG
  as a debugging shortcut.

---

## Reporting a security issue

Please **do not** open a public issue for a vulnerability. Use
[GitHub's private vulnerability reporting](https://github.com/organicnz/terraform-cloud/security/advisories/new)
instead, or contact the maintainer directly.

You should get an acknowledgement within a few days. Since this is a student
project without a formal SLA, please do not disclose publicly until a fix or
mitigation is in place.

---

## License

This project is licensed under the [MIT License](LICENSE). By contributing, you
agree that your contributions are licensed under the same terms.

All contributors are credited in the git history — that is the record. If you
would like to be named in the README as well, say so in your first PR and it
will be added.

---

## Code of conduct

Be decent to each other. Assume good faith, critique the code and never the
person, and remember that everyone here is learning. Behaviour that is
unacceptable in any project space is also unacceptable here; report concerns
to the maintainers.

Thanks again for contributing! 🙏
