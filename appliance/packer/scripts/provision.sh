#!/usr/bin/env bash
set -Eeuo pipefail

sudo dnf install -y epel-release
sudo dnf install -y snapd curl ca-certificates podman openssl dialog git open-vm-tools
sudo systemctl enable --now snapd.socket vmtoolsd
[[ -e /snap ]] || sudo ln -s /var/lib/snapd/snap /snap

sudo chown -R root:root /opt/microk10
sudo chmod +x \
  /opt/microk10/microk10 \
  /opt/microk10/appliance/microk10-tui \
  /opt/microk10/appliance/lib/*.sh \
  /opt/microk10/appliance/packer/scripts/*.sh

sudo install -d -m 0750 /etc/microk10 /var/lib/microk10
sudo install -m 0644 /opt/microk10/appliance/systemd/microk10-console.service /etc/systemd/system/microk10-console.service
sudo systemctl daemon-reload
sudo systemctl enable microk10-console.service

# Keep the ephemeral build key alive until Packer invokes finalize-image.sh as
# its shutdown command. The finalizer removes the key and locks the build user.
sudo dnf clean all
sudo rm -rf /var/cache/dnf/*
