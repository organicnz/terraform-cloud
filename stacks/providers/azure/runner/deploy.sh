#!/usr/bin/env bash
#
# One-command deploy for the GitHub Actions runner.
#
#   ./deploy.sh          plan only (uses existing terraform.tfvars, no churn)
#   ./deploy.sh --apply  fetch a fresh registration token, then apply
#
# Registration tokens expire in ~1h, so --apply always regenerates one. Because
# the token is baked into the VM's custom_data, a changed token forces Terraform
# to replace the VM — that is expected, not a bug. It re-registers and is back
# online in about a minute.
#
set -euo pipefail
cd "$(dirname "$0")"

APPLY=false
[[ " ${*:-} " == *" --apply "* ]] && APPLY=true

SUBSCRIPTION_ID="97e7954d-922c-49e9-b244-68753e6b316c"
REPO="${GITHUB_REPO:-organicnz/terraform-cloud}"

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI not found. Install it with: brew install gh" >&2
  exit 1
fi

if $APPLY; then
  echo "Fetching runner registration token for $REPO ..."
  TOKEN=$(gh api --method POST "repos/$REPO/actions/runners/registration-token" --jq .token)
  if [[ -z "$TOKEN" ]]; then
    echo "ERROR: could not fetch a registration token. Is gh authenticated?" >&2
    exit 1
  fi

  SSH_PUB=""
  if [[ -f "$HOME/.ssh/azure_id_rsa.pub" ]]; then
    SSH_PUB=$(cat "$HOME/.ssh/azure_id_rsa.pub")
  fi

  cat > terraform.tfvars <<EOF
subscription_id = "$SUBSCRIPTION_ID"

github_repo   = "$REPO"
github_token  = "$TOKEN"

runner_name   = "ghrunner-eastasia"
runner_labels = "self-hosted,linux,x64,ghrunner"

admin_username = "runneradmin"
location       = "eastasia"
vm_size        = "Standard_B2ats_v2"
ssh_public_key = "$SSH_PUB"
EOF
  chmod 600 terraform.tfvars
  echo "terraform.tfvars refreshed (token length ${#TOKEN})."
else
  if [[ ! -f terraform.tfvars ]]; then
    echo "ERROR: terraform.tfvars missing. Run: ./deploy.sh --apply" >&2
    exit 1
  fi
  echo "Using existing terraform.tfvars (run with --apply to refresh the token)."
fi

if [[ ! -d .terraform ]]; then
  terraform init -input=false
fi

echo
if $APPLY; then
  echo "--- Applying (VM will be replaced to bake in the fresh token) ---"
  terraform apply -input=false -auto-approve
  echo
  echo "--- Verifying registration with GitHub ---"
  sleep 60
  gh api "repos/$REPO/actions/runners" \
    --jq '"runners online: \(.total_count) | \([.runners[] | "\(.name) \(.status)"] | join(", "))"'
else
  echo "--- Plan ---"
  terraform plan -input=false
fi
