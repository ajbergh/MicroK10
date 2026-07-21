#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
printf 'NOTICE: the insecure WordPress demo was removed; installing the PVC demo instead.\n' >&2
exec "${SCRIPT_DIR}/microk10" demo install "$@"
