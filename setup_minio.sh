#!/usr/bin/env bash
set -Eeuo pipefail
cat >&2 <<'MSG'
ERROR: the legacy MinIO installer was removed because it embedded credentials and assumed a fixed host endpoint.
Deploy and secure an S3-compatible object store separately, then create a Veeam Kasten Location Profile using its supported authentication method.
MSG
exit 2
