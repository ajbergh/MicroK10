#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
printf 'NOTICE: deployK10.sh is deprecated; forwarding to microk10 install-kasten.\n' >&2
exec "${SCRIPT_DIR}/microk10" install-kasten "$@"
