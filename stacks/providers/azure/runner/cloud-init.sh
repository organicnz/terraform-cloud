#!/bin/bash
set -euo pipefail

RUNNER_HOME="/opt/actions-runner"
RUNNER_USER="runner"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y curl jq docker.io
systemctl enable --now docker

# The free-tier B2ats_v2 has 1 GB RAM, which is too small for Docker builds.
# A 2 GB swapfile keeps the runner from being OOM-killed mid-job.
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile >/dev/null
  swapon /swapfile
  grep -q "^/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
fi

# Install Tailscale so the box is reachable over the tailnet without a public IP.
# The auth key is applied manually after provisioning and is never stored here.
curl -fsSL https://tailscale.com/install.sh | sh

# The Actions runner refuses to run as root, so it needs an unprivileged user.
id -u "$RUNNER_USER" >/dev/null 2>&1 || useradd -m -s /bin/bash "$RUNNER_USER"
usermod -aG docker "$RUNNER_USER"

RUNNER_VERSION="$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/^v//')"
echo "Installing GitHub Actions runner v$RUNNER_VERSION"

mkdir -p "$RUNNER_HOME"
cd "$RUNNER_HOME"
curl -fsSL -o runner.tar.gz "https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz"
tar xzf runner.tar.gz
rm -f runner.tar.gz
chown -R "$RUNNER_USER":"$RUNNER_USER" "$RUNNER_HOME"

%{ if github_org != "" }
RUNNER_URL="https://github.com/${github_org}"
%{ else }
RUNNER_URL="https://github.com/${github_repo}"
%{ endif }

# Register as the unprivileged user.
sudo -u "$RUNNER_USER" -H ./config.sh \
  --url "$RUNNER_URL" \
  --token "${github_token}" \
  --name "${runner_name}" \
  --labels "${runner_labels}" \
  --work "_work" \
  --unattended

# Install the systemd unit as root but have it execute the runner as that user.
sudo ./svc.sh install "$RUNNER_USER"
sudo ./svc.sh start

echo "GitHub Actions runner '${runner_name}' registered to $RUNNER_URL and started."
