#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

mapfile -t files < <(find . -type f \
  \( -name '*.sh' -o -name '*.env' -o -name '*.yaml' -o -name '*.yml' -o -name '*.hcl' -o -name 'microk10' -o -name 'microk10-tui' \) \
  -not -path './.git/*' -print)

patterns=(
  "MINIO_(ACCESS_KEY|SECRET_KEY|ROOT_USER|ROOT_PASSWORD)=[\"'][^$]"
  "(wordpressPassword|rootPassword|aws_secret_access_key|htpasswd)=[\"']?[[:alnum:]+/=._-]+"
  "--from-literal=(aws_access_key_id|aws_secret_access_key)=[\"']?[[:alnum:]+/=._-]+"
  "(password|passwd)[[:space:]]*=[[:space:]]*[\"'][[:alnum:]+/=._-]{8,}[\"']"
)

failed=0
for pattern in "${patterns[@]}"; do
  if grep -En -- "${pattern}" "${files[@]}"; then
    failed=1
  fi
done

if ((failed)); then
  printf 'Potential plaintext secret detected in the current working tree.\n' >&2
  exit 1
fi
printf 'No obvious plaintext secrets found in executable configuration.\n'
