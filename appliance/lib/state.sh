#!/usr/bin/env bash
set -Eeuo pipefail

MICROK10_STATE_DIR="${MICROK10_STATE_DIR:-/var/lib/microk10}"
MICROK10_STATE_FILE="${MICROK10_STATE_DIR}/appliance.env"

ensure_state_dir() {
  install -d -m 0750 "${MICROK10_STATE_DIR}"
}

state_get() {
  local key="$1"
  [[ -r "${MICROK10_STATE_FILE}" ]] || return 1
  awk -F= -v key="${key}" '$1==key {sub(/^[^=]*=/, ""); print; exit}' "${MICROK10_STATE_FILE}"
}

state_set() {
  local key="$1" value="$2" tmp
  ensure_state_dir
  tmp="$(mktemp)"
  if [[ -r "${MICROK10_STATE_FILE}" ]]; then
    awk -F= -v key="${key}" '$1!=key {print}' "${MICROK10_STATE_FILE}" >"${tmp}"
  fi
  printf '%s=%s\n' "${key}" "${value}" >>"${tmp}"
  install -m 0640 "${tmp}" "${MICROK10_STATE_FILE}"
  rm -f "${tmp}"
}

appliance_initialized() {
  [[ "$(state_get initialized 2>/dev/null || true)" == true ]]
}

mark_initialized() {
  state_set initialized true
  state_set initialized_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

factory_reset() {
  systemctl disable --now microk10-minio.service 2>/dev/null || true
  podman rm -f microk10-minio 2>/dev/null || true
  /opt/microk10/microk10 uninstall --yes --purge-microk8s 2>/dev/null || true
  rm -rf /var/lib/microk10 /etc/microk10
  install -d -m 0750 /var/lib/microk10 /etc/microk10
}
