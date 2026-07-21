#!/usr/bin/env bash
# Shared logging, execution, parsing, and validation helpers.

color_code() {
  local code="$1"
  if [[ "${COLOR}" == true ]]; then
    printf '\033[%sm' "${code}"
  fi
}

log() {
  local level="$1"
  shift
  local code="0"
  case "${level}" in
    INFO) code="1;34" ;;
    WARN) code="1;33" ;;
    ERROR) code="1;31" ;;
    OK) code="1;32" ;;
    DEBUG) code="0;36" ;;
  esac
  if [[ "${level}" == DEBUG && "${VERBOSE}" != true ]]; then
    return 0
  fi
  printf '%s[%s] %-5s%s %s\n' "$(color_code "${code}")" "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "${level}" "$(color_code 0)" "$*" >&2
}

fatal() {
  log ERROR "$*"
  exit 1
}

on_error() {
  local exit_code=$?
  local line_no="${1:-unknown}"
  local command="${2:-unknown}"
  log ERROR "Command failed (exit ${exit_code}) at line ${line_no}: ${command}"
  exit "${exit_code}"
}
trap 'on_error "${LINENO}" "${BASH_COMMAND}"' ERR

shell_join() {
  local output=""
  local item
  for item in "$@"; do
    printf -v item '%q' "${item}"
    output+="${item} "
  done
  printf '%s' "${output% }"
}

run() {
  if [[ "${DRY_RUN}" == true ]]; then
    printf '+ %s\n' "$(shell_join "$@")" >&2
    return 0
  fi
  if [[ "${VERBOSE}" == true ]]; then
    printf '+ %s\n' "$(shell_join "$@")" >&2
  fi
  "$@"
}

run_as_root() {
  if (( EUID == 0 )); then
    run "$@"
  else
    run sudo "$@"
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_command() {
  command_exists "$1" || fatal "Required command not found: $1"
}

require_root_or_sudo() {
  if [[ "${DRY_RUN}" == true ]]; then
    return 0
  fi
  if (( EUID != 0 )); then
    command_exists sudo || fatal "Run as root or install sudo."
    sudo -n true 2>/dev/null || fatal "Root privileges are required. Re-run with sudo or configure sudo access."
  fi
}

version_minor() {
  local version="${1#v}"
  if [[ "${version}" =~ ^([0-9]+)\.([0-9]+) ]]; then
    printf '%s.%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
  else
    return 1
  fi
}

channel_minor() {
  local channel="$1"
  if [[ "${channel}" =~ ^([0-9]+\.[0-9]+)/(stable|candidate|beta|edge)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  else
    return 1
  fi
}

value_in_space_list() {
  local candidate="$1"
  local values="$2"
  local value
  while IFS= read -r value; do
    if [[ "${candidate}" == "${value}" ]]; then
      return 0
    fi
  done < <(tr ' ' '\n' <<<"${values}")
  return 1
}

is_supported_kubernetes() {
  value_in_space_list "$1" "${MICROK10_SUPPORTED_KUBERNETES}"
}

is_tested_ubuntu() {
  value_in_space_list "$1" "${MICROK10_TESTED_UBUNTU}"
}

is_supported_architecture() {
  value_in_space_list "$1" "${MICROK10_SUPPORTED_ARCHITECTURES}"
}

validate_channel() {
  local minor
  minor="$(channel_minor "${MICROK8S_CHANNEL}")" || fatal "Invalid MicroK8s channel '${MICROK8S_CHANNEL}'. Expected <major.minor>/<risk>, for example 1.34/stable."
  if ! is_supported_kubernetes "${minor}" && [[ "${ALLOW_UNSUPPORTED}" != true ]]; then
    fatal "Kubernetes ${minor} is outside the validated Veeam Kasten ${KASTEN_VERSION} matrix (${MICROK10_SUPPORTED_KUBERNETES}). Use --allow-unsupported only for deliberate testing."
  fi
}

validate_timeout() {
  [[ "${WAIT_TIMEOUT}" =~ ^[1-9][0-9]*(s|m|h)$ ]] || fatal "Invalid timeout '${WAIT_TIMEOUT}'. Use a duration such as 900s, 20m, or 1h."
}

validate_metallb_range() {
  if [[ -z "${METALLB_RANGE}" ]]; then
    return 0
  fi
  [[ "${METALLB_RANGE}" =~ ^[0-9a-fA-F:.,/-]+$ ]] || fatal "Invalid MetalLB address range '${METALLB_RANGE}'."
}

validate_port() {
  [[ "${DASHBOARD_PORT}" =~ ^[0-9]+$ ]] || fatal "Dashboard port must be numeric."
  (( DASHBOARD_PORT >= 1 && DASHBOARD_PORT <= 65535 )) || fatal "Dashboard port must be between 1 and 65535."
}
