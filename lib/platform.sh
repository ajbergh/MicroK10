#!/usr/bin/env bash
# Host and MicroK8s lifecycle functions.

host_architecture() {
  case "$(uname -m)" in
  x86_64) printf 'amd64\n' ;;
  aarch64 | arm64) printf 'arm64\n' ;;
  ppc64le) printf 'ppc64le\n' ;;
  *) uname -m ;;
  esac
}

memory_mib() {
  awk '/MemTotal:/ {print int($2 / 1024)}' /proc/meminfo
}

disk_available_gib() {
  df -Pk /var 2>/dev/null | awk 'NR==2 {print int($4 / 1024 / 1024)}'
}

host_preflight() {
  [[ "$(uname -s)" == Linux ]] || fatal "MicroK10 currently supports Linux hosts only."

  local arch
  arch="$(host_architecture)"
  if ! is_supported_architecture "${arch}"; then
    if [[ "${ALLOW_UNSUPPORTED}" == true ]]; then
      log WARN "Architecture ${arch} has not been validated by MicroK10."
    else
      fatal "Architecture ${arch} is not in the validated set: ${MICROK10_SUPPORTED_ARCHITECTURES}."
    fi
  fi

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" == ubuntu ]]; then
      if ! is_tested_ubuntu "${VERSION_ID:-unknown}"; then
        if [[ "${ALLOW_UNSUPPORTED}" == true ]]; then
          log WARN "Ubuntu ${VERSION_ID:-unknown} has not been validated. Tested releases: ${MICROK10_TESTED_UBUNTU}."
        else
          fatal "Ubuntu ${VERSION_ID:-unknown} is outside the tested release set (${MICROK10_TESTED_UBUNTU})."
        fi
      fi
    else
      log WARN "${PRETTY_NAME:-This Linux distribution} is not in the tested Ubuntu matrix; snap-based MicroK8s may still work."
    fi
  fi

  local mem disk
  mem="$(memory_mib)"
  disk="$(disk_available_gib)"
  if ((mem < MIN_MEMORY_MIB)); then
    log WARN "Only ${mem} MiB RAM detected; at least ${MIN_MEMORY_MIB} MiB is recommended for this lab stack."
  fi
  if ((disk < MIN_DISK_GIB)); then
    log WARN "Only ${disk} GiB is available under /var; at least ${MIN_DISK_GIB} GiB is recommended for installation."
  fi
}

ensure_snap() {
  if command_exists snap; then
    return 0
  fi
  require_root_or_sudo
  command_exists apt-get || fatal "snap is missing and automatic installation is only supported on apt-based systems."
  run_as_root apt-get update
  run_as_root apt-get install -y snapd curl ca-certificates
}

microk8s_installed() {
  command_exists microk8s || { command_exists snap && snap list microk8s >/dev/null 2>&1; }
}

wait_for_microk8s() {
  require_command timeout
  log INFO "Waiting for MicroK8s to become ready."
  run_as_root timeout "${WAIT_TIMEOUT}" microk8s status --wait-ready
}

enable_addon() {
  local addon="$1"
  if run_as_root microk8s status --format short 2>/dev/null | grep -Eq "(^|[[:space:]])${addon}(:|[[:space:]])"; then
    log DEBUG "MicroK8s addon already enabled: ${addon}"
    return 0
  fi
  log INFO "Enabling MicroK8s addon: ${addon}"
  run_as_root microk8s enable "${addon}"
}

configure_microk8s_user() {
  local target_user="${SUDO_USER:-${USER:-root}}"
  if [[ "${target_user}" == root || -z "${target_user}" ]]; then
    return 0
  fi
  if getent group microk8s >/dev/null 2>&1; then
    run_as_root usermod -a -G microk8s "${target_user}"
  fi
  local home_dir
  home_dir="$(getent passwd "${target_user}" | cut -d: -f6)"
  if [[ -n "${home_dir}" ]]; then
    run_as_root mkdir -p "${home_dir}/.kube"
    run_as_root chown -R "${target_user}:$(id -gn "${target_user}")" "${home_dir}/.kube"
  fi
}

install_microk8s() {
  validate_channel
  host_preflight
  require_root_or_sudo
  ensure_snap

  if ! microk8s_installed; then
    log INFO "Installing MicroK8s from ${MICROK8S_CHANNEL}."
    run_as_root snap install microk8s --classic --channel="${MICROK8S_CHANNEL}"
  else
    log INFO "MicroK8s is already installed; preserving the installed revision."
  fi

  wait_for_microk8s
  configure_microk8s_user
  enable_addon dns
  enable_addon hostpath-storage

  if ! run_as_root microk8s helm3 version --short >/dev/null 2>&1; then
    enable_addon helm3
  fi

  if [[ -n "${METALLB_RANGE}" ]]; then
    log INFO "Enabling MetalLB with address range ${METALLB_RANGE}."
    run_as_root microk8s enable "metallb:${METALLB_RANGE}"
  fi

  if [[ "${DRY_RUN}" == true ]]; then
    log OK "MicroK8s dry run completed; live server validation was skipped."
    return 0
  fi

  validate_kubernetes_version
  log OK "MicroK8s is ready."
}

server_git_version() {
  local version_output
  version_output="$(run_as_root microk8s kubectl version -o json)"
  sed -n 's/.*"gitVersion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' <<<"${version_output}" | tail -n1
}

validate_kubernetes_version() {
  microk8s_installed || fatal "MicroK8s is not installed."
  wait_for_microk8s
  local git_version minor
  git_version="$(server_git_version)"
  [[ -n "${git_version}" ]] || fatal "Unable to determine the Kubernetes server version."
  minor="$(version_minor "${git_version}")" || fatal "Unable to parse Kubernetes version '${git_version}'."
  if ! is_supported_kubernetes "${minor}"; then
    if [[ "${ALLOW_UNSUPPORTED}" == true ]]; then
      log WARN "Kubernetes ${git_version} is outside the validated Kasten ${KASTEN_VERSION} matrix."
    else
      fatal "Kubernetes ${git_version} is unsupported by the validated Kasten ${KASTEN_VERSION} matrix (${MICROK10_SUPPORTED_KUBERNETES})."
    fi
  fi
  log OK "Kubernetes ${git_version} is compatible with the configured matrix."
}
