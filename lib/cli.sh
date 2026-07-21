#!/usr/bin/env bash
# User-facing command routing and help.

print_compatibility() {
  cat <<EOF_COMPAT
MicroK10 ${MICROK10_RELEASE_VERSION}

Validated host operating systems: Ubuntu ${MICROK10_TESTED_UBUNTU}
Validated architectures:          ${MICROK10_SUPPORTED_ARCHITECTURES}
Validated Kubernetes minors:      ${MICROK10_SUPPORTED_KUBERNETES}
Default MicroK8s channel:         ${MICROK10_DEFAULT_MICROK8S_CHANNEL}
Default Veeam Kasten version:     ${MICROK10_DEFAULT_KASTEN_VERSION}

MicroK8s latest/stable is intentionally not used because it may advance beyond
Veeam Kasten's currently supported Kubernetes matrix.
EOF_COMPAT
}

usage() {
  cat <<EOF_USAGE
MicroK10 ${MICROK10_RELEASE_VERSION}

Usage:
  ${0##*/} <command> [options]

Commands:
  install                 Install MicroK8s and Veeam Kasten.
  install-microk8s        Install and configure MicroK8s only.
  install-kasten          Install or upgrade Veeam Kasten only.
  validate                Validate Kubernetes compatibility and Kasten health.
  status                  Show host, cluster, storage, and Kasten status.
  dashboard               Start a local dashboard port-forward.
  demo install|remove     Manage the backup-ready PVC demo workload.
  upgrade-microk8s        Refresh MicroK8s to the selected supported channel.
  upgrade-kasten          Upgrade Kasten using the selected chart version.
  uninstall               Remove Kasten; optionally purge MicroK8s.
  compatibility           Print the validated release matrix.
  version                 Print the MicroK10 version.
  help                    Show this help.

Options:
  --microk8s-channel CH   Snap channel (default: ${MICROK8S_CHANNEL}).
  --kasten-version VER    Helm chart version (default: ${KASTEN_VERSION}).
  --namespace NAME        Kasten namespace (default: ${KASTEN_NAMESPACE}).
  --release NAME          Helm release name (default: ${KASTEN_RELEASE}).
  --storage-class NAME    Kasten persistence StorageClass (default: ${STORAGE_CLASS}).
  --values FILE           Additional Kasten Helm values file.
  --timeout DURATION      Wait timeout, e.g. 20m (default: ${WAIT_TIMEOUT}).
  --metallb-range RANGE   Enable MetalLB with a range or CIDR.
  --address ADDRESS       Dashboard bind address (default: ${DASHBOARD_ADDRESS}).
  --port PORT             Dashboard local port (default: ${DASHBOARD_PORT}).
  --skip-primer           Skip the official Kasten pre-flight check.
  --skip-chart-verification
                           Do not verify Helm chart provenance.
  --allow-unsupported     Allow unvalidated OS, architecture, or Kubernetes versions.
  --purge-microk8s        With uninstall, also remove MicroK8s and cluster data.
  --yes                    Accept destructive confirmations.
  --dry-run                Print commands without changing the system.
  --verbose                Print executed commands and debug messages.
  --no-color               Disable ANSI color.
  -h, --help               Show this help.
EOF_USAGE
}

parse_options() {
  POSITIONAL=()
  while (($#)); do
    case "$1" in
      --microk8s-channel) [[ $# -ge 2 ]] || fatal "$1 requires a value"; MICROK8S_CHANNEL="$2"; shift 2 ;;
      --kasten-version) [[ $# -ge 2 ]] || fatal "$1 requires a value"; KASTEN_VERSION="$2"; shift 2 ;;
      --namespace) [[ $# -ge 2 ]] || fatal "$1 requires a value"; KASTEN_NAMESPACE="$2"; shift 2 ;;
      --release) [[ $# -ge 2 ]] || fatal "$1 requires a value"; KASTEN_RELEASE="$2"; shift 2 ;;
      --storage-class) [[ $# -ge 2 ]] || fatal "$1 requires a value"; STORAGE_CLASS="$2"; shift 2 ;;
      --values) [[ $# -ge 2 ]] || fatal "$1 requires a value"; VALUES_FILE="$2"; shift 2 ;;
      --timeout) [[ $# -ge 2 ]] || fatal "$1 requires a value"; WAIT_TIMEOUT="$2"; shift 2 ;;
      --metallb-range) [[ $# -ge 2 ]] || fatal "$1 requires a value"; METALLB_RANGE="$2"; shift 2 ;;
      --address) [[ $# -ge 2 ]] || fatal "$1 requires a value"; DASHBOARD_ADDRESS="$2"; shift 2 ;;
      --port) [[ $# -ge 2 ]] || fatal "$1 requires a value"; DASHBOARD_PORT="$2"; shift 2 ;;
      --skip-primer) SKIP_PRIMER=true; shift ;;
      --skip-chart-verification) SKIP_CHART_VERIFICATION=true; shift ;;
      --allow-unsupported) ALLOW_UNSUPPORTED=true; shift ;;
      --purge-microk8s) PURGE_MICROK8S=true; shift ;;
      --yes|-y) YES=true; shift ;;
      --dry-run) DRY_RUN=true; shift ;;
      --verbose|-v) VERBOSE=true; shift ;;
      --no-color) COLOR=false; shift ;;
      -h|--help) POSITIONAL+=(help); shift ;;
      --) shift; POSITIONAL+=("$@"); break ;;
      -*) fatal "Unknown option: $1" ;;
      *) POSITIONAL+=("$1"); shift ;;
    esac
  done
  validate_timeout
  validate_metallb_range
}

main() {
  parse_options "$@"
  local command="${POSITIONAL[0]:-help}"
  local subcommand="${POSITIONAL[1]:-}"
  case "${command}" in
    install) install_microk8s; install_kasten ;;
    install-microk8s) install_microk8s ;;
    install-kasten) install_kasten ;;
    validate) validate_kubernetes_version; validate_kasten; log OK "MicroK10 validation passed." ;;
    status) status ;;
    dashboard) dashboard ;;
    demo)
      case "${subcommand}" in
        install) install_demo ;;
        remove|delete|uninstall) remove_demo ;;
        *) fatal "Usage: ${0##*/} demo install|remove" ;;
      esac
      ;;
    upgrade-microk8s) upgrade_microk8s ;;
    upgrade-kasten) upgrade_kasten ;;
    uninstall) uninstall_kasten ;;
    compatibility) print_compatibility ;;
    version) printf '%s\n' "${MICROK10_RELEASE_VERSION}" ;;
    help) usage ;;
    *) fatal "Unknown command '${command}'. Run '${0##*/} help'." ;;
  esac
}
