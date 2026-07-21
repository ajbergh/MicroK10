#!/usr/bin/env bash
set -Eeuo pipefail
printf 'ERROR: host network modification was removed from MicroK10. Configure networking with your platform or netplan tooling, then run ./microk10 status.\n' >&2
exit 2
