#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
printf 'NOTICE: the interactive menu was replaced by the microk10 CLI.\n' >&2
if (($# == 0)); then
  set -- help
fi
exec "${SCRIPT_DIR}/microk10" "$@"
