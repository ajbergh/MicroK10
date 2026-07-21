#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

output="$(./microk10 install \
  --dry-run \
  --skip-primer \
  --skip-chart-verification \
  --no-color 2>&1)"

grep -Fq 'snap install microk8s --classic --channel=1.34/stable' <<<"${output}"
grep -Fq 'microk8s helm3 upgrade --install k10 kasten/k10' <<<"${output}"
grep -Fq 'MicroK8s dry run completed' <<<"${output}"
grep -Fq 'Veeam Kasten dry run completed' <<<"${output}"

if ./microk10 install-microk8s \
  --dry-run \
  --microk8s-channel 1.35/stable \
  --no-color >/dev/null 2>&1; then
  printf 'Unsupported Kubernetes 1.35 channel was not blocked.\n' >&2
  exit 1
fi

printf 'Dry-run lifecycle and compatibility guard passed.\n'
