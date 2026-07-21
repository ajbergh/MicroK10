#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../microk10
source "${ROOT_DIR}/microk10"

failures=0
assert_eq() {
  local expected="$1" actual="$2" message="$3"
  if [[ "${expected}" != "${actual}" ]]; then
    printf 'not ok - %s (expected=%q actual=%q)\n' "${message}" "${expected}" "${actual}" >&2
    failures=$((failures + 1))
  else
    printf 'ok - %s\n' "${message}"
  fi
}

assert_true() {
  local message="$1"
  shift
  if "$@"; then
    printf 'ok - %s\n' "${message}"
  else
    printf 'not ok - %s\n' "${message}" >&2
    failures=$((failures + 1))
  fi
}

assert_false() {
  local message="$1"
  shift
  if "$@"; then
    printf 'not ok - %s\n' "${message}" >&2
    failures=$((failures + 1))
  else
    printf 'ok - %s\n' "${message}"
  fi
}

assert_eq "1.34" "$(version_minor v1.34.7)" "parse Kubernetes git version"
assert_eq "1.31" "$(channel_minor 1.31/stable)" "parse stable MicroK8s channel"
assert_eq "1.34" "$(channel_minor 1.34/candidate)" "parse candidate MicroK8s channel"
assert_true "1.31 is supported" is_supported_kubernetes 1.31
assert_true "1.34 is supported" is_supported_kubernetes 1.34
assert_false "1.35 is blocked" is_supported_kubernetes 1.35
assert_true "Ubuntu 22.04 is tested" is_tested_ubuntu 22.04
assert_true "Ubuntu 26.04 is tested" is_tested_ubuntu 26.04
assert_false "Ubuntu 20.04 is no longer tested" is_tested_ubuntu 20.04
assert_true "amd64 is supported" is_supported_architecture amd64
assert_true "arm64 is supported" is_supported_architecture arm64

if (( failures > 0 )); then
  printf '%d test(s) failed\n' "${failures}" >&2
  exit 1
fi
printf 'all tests passed\n'
