#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
printf 'NOTICE: MicroK10_deployment.sh is deprecated; forwarding to microk10 install.\n' >&2
exec "${SCRIPT_DIR}/microk10" install "$@"
