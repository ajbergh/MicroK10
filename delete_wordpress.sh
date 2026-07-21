#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
printf 'NOTICE: forwarding legacy demo removal to microk10 demo remove.\n' >&2
exec "${SCRIPT_DIR}/microk10" demo remove "$@"
