#!/usr/bin/env bash
set -Eeuo pipefail

# Remove build-only privilege and authorization only after Packer has connected
# to invoke this final shutdown command.
rm -f /etc/sudoers.d/microk10-build
passwd -l microk10 || true
rm -rf /home/microk10/.ssh

# Regenerate unique identity on first appliance boot.
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
rm -f /etc/ssh/ssh_host_*

# Do not ship transient state or caches.
rm -rf /var/lib/microk10/* /etc/microk10/*
dnf clean all
rm -rf /var/cache/dnf/* /tmp/* /var/tmp/*
sync
shutdown -P now
