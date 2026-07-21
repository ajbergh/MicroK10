#!/usr/bin/env bash
# Veeam Kasten and demo-workload lifecycle functions.

ensure_storage_class() {
  if ! run_as_root microk8s kubectl get storageclass "${STORAGE_CLASS}" >/dev/null 2>&1; then
    fatal "StorageClass '${STORAGE_CLASS}' was not found. Specify --storage-class or enable an appropriate MicroK8s storage addon."
  fi
}

download_kasten_key() {
  local output="$1"
  require_command curl
  run curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 "${KASTEN_KEY_URL}" --output "${output}"
}

run_kasten_primer() {
  local primer_url="${KASTEN_DOCS_BASE}/${KASTEN_VERSION}/tools/k10_primer.sh"
  local primer_file wrapper_dir
  primer_file="$(mktemp)"
  wrapper_dir="$(mktemp -d)"
  trap 'rm -f "${primer_file}"; rm -rf "${wrapper_dir}"' RETURN

  cat >"${wrapper_dir}/kubectl" <<'EOF_KUBECTL'
#!/usr/bin/env bash
exec microk8s kubectl "$@"
EOF_KUBECTL
  cat >"${wrapper_dir}/helm" <<'EOF_HELM'
#!/usr/bin/env bash
exec microk8s helm3 "$@"
EOF_HELM
  chmod 0700 "${wrapper_dir}/kubectl" "${wrapper_dir}/helm"

  log INFO "Downloading the Veeam Kasten ${KASTEN_VERSION} pre-flight tool."
  run curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 "${primer_url}" --output "${primer_file}"
  run chmod 0700 "${primer_file}"
  log INFO "Running Veeam Kasten pre-flight checks."
  if [[ "${DRY_RUN}" == true ]]; then
    run env PATH="${wrapper_dir}:${PATH}" bash "${primer_file}"
  else
    run_as_root env PATH="${wrapper_dir}:${PATH}" KUBECONFIG="${KUBECONFIG:-}" bash "${primer_file}"
  fi
  rm -f "${primer_file}"
  rm -rf "${wrapper_dir}"
  trap - RETURN
}

install_kasten() {
  require_root_or_sudo
  require_command curl
  if [[ "${DRY_RUN}" == true ]]; then
    log INFO "Dry run: skipping live MicroK8s, Kubernetes, and StorageClass checks."
  else
    microk8s_installed || fatal "MicroK8s is not installed. Run '${0##*/} install-microk8s' first."
    validate_kubernetes_version
    ensure_storage_class
  fi

  log INFO "Configuring the Veeam Kasten Helm repository."
  run_as_root microk8s helm3 repo add kasten "${KASTEN_CHART_REPOSITORY}" --force-update
  run_as_root microk8s helm3 repo update kasten

  if [[ "${SKIP_PRIMER}" != true ]]; then
    run_kasten_primer
  else
    log WARN "Skipping Veeam Kasten pre-flight checks by request."
  fi

  run_as_root microk8s kubectl create namespace "${KASTEN_NAMESPACE}" --dry-run=client -o yaml | run_as_root microk8s kubectl apply -f -

  local helm_args=(
    upgrade --install "${KASTEN_RELEASE}" kasten/k10
    --namespace "${KASTEN_NAMESPACE}"
    --version "${KASTEN_VERSION}"
    --set-string "global.persistence.storageClass=${STORAGE_CLASS}"
    --wait
    --wait-for-jobs
    --atomic
    --timeout "${WAIT_TIMEOUT}"
  )

  local keyring=""
  if [[ "${SKIP_CHART_VERIFICATION}" != true ]]; then
    keyring="$(mktemp)"
    download_kasten_key "${keyring}"
    helm_args+=(--verify --keyring "${keyring}")
  else
    log WARN "Helm chart signature verification is disabled by request."
  fi

  if [[ -n "${VALUES_FILE}" ]]; then
    [[ -r "${VALUES_FILE}" ]] || fatal "Values file is not readable: ${VALUES_FILE}"
    helm_args+=(--values "${VALUES_FILE}")
  fi

  log INFO "Installing Veeam Kasten ${KASTEN_VERSION} as ${KASTEN_NAMESPACE}/${KASTEN_RELEASE}."
  run_as_root microk8s helm3 "${helm_args[@]}"
  [[ -z "${keyring}" ]] || rm -f "${keyring}"

  if [[ "${DRY_RUN}" == true ]]; then
    log OK "Veeam Kasten dry run completed; live release validation was skipped."
    return 0
  fi

  validate_kasten
  log OK "Veeam Kasten ${KASTEN_VERSION} is ready."
  log INFO "Open the dashboard with: ${0##*/} dashboard"
}

validate_kasten() {
  if ! run_as_root microk8s helm3 status "${KASTEN_RELEASE}" --namespace "${KASTEN_NAMESPACE}" >/dev/null 2>&1; then
    fatal "Veeam Kasten Helm release ${KASTEN_NAMESPACE}/${KASTEN_RELEASE} is not installed."
  fi

  local workload
  while IFS= read -r workload; do
    [[ -n "${workload}" ]] || continue
    run_as_root microk8s kubectl rollout status "${workload}" --namespace "${KASTEN_NAMESPACE}" --timeout="${WAIT_TIMEOUT}"
  done < <(run_as_root microk8s kubectl get deployment,statefulset --namespace "${KASTEN_NAMESPACE}" -o name)

  local unhealthy
  unhealthy="$(run_as_root microk8s kubectl get pods --namespace "${KASTEN_NAMESPACE}" --no-headers 2>/dev/null | awk '$3 ~ /CrashLoopBackOff|Error|ImagePullBackOff|ErrImagePull|CreateContainerConfigError|Pending/ {print}')"
  if [[ -n "${unhealthy}" ]]; then
    printf '%s\n' "${unhealthy}" >&2
    fatal "One or more Veeam Kasten pods are unhealthy."
  fi
}

status() {
  host_preflight
  if ! microk8s_installed; then
    log WARN "MicroK8s is not installed."
    return 1
  fi
  wait_for_microk8s
  printf '\nMicroK10 %s\n' "${MICROK10_RELEASE_VERSION}"
  printf 'Configured MicroK8s channel: %s\n' "${MICROK8S_CHANNEL}"
  printf 'Configured Kasten version:   %s\n\n' "${KASTEN_VERSION}"
  run_as_root microk8s status
  printf '\nKubernetes nodes:\n'
  run_as_root microk8s kubectl get nodes -o wide
  printf '\nStorage classes:\n'
  run_as_root microk8s kubectl get storageclass
  printf '\nKasten release:\n'
  if run_as_root microk8s helm3 status "${KASTEN_RELEASE}" --namespace "${KASTEN_NAMESPACE}" >/dev/null 2>&1; then
    run_as_root microk8s helm3 list --namespace "${KASTEN_NAMESPACE}"
    run_as_root microk8s kubectl get pods --namespace "${KASTEN_NAMESPACE}"
  else
    printf 'Not installed\n'
  fi
}

dashboard() {
  validate_port
  validate_kasten
  log INFO "Forwarding http://${DASHBOARD_ADDRESS}:${DASHBOARD_PORT}/${KASTEN_RELEASE}/#/ to ${KASTEN_NAMESPACE}/service/gateway. Press Ctrl+C to stop."
  run_as_root microk8s kubectl --namespace "${KASTEN_NAMESPACE}" port-forward service/gateway "${DASHBOARD_PORT}:80" --address "${DASHBOARD_ADDRESS}"
}

install_demo() {
  microk8s_installed || fatal "MicroK8s is not installed."
  local manifest="${SCRIPT_DIR}/manifests/demo-pvc.yaml"
  [[ -r "${manifest}" ]] || fatal "Demo manifest not found: ${manifest}"
  sed "s/__STORAGE_CLASS__/${STORAGE_CLASS}/g" "${manifest}" | run_as_root microk8s kubectl apply -f -
  run_as_root microk8s kubectl rollout status deployment/microk10-demo --namespace microk10-demo --timeout="${WAIT_TIMEOUT}"
  log OK "Backup-ready demo workload installed in namespace microk10-demo."
}

remove_demo() {
  if run_as_root microk8s kubectl get namespace microk10-demo >/dev/null 2>&1; then
    run_as_root microk8s kubectl delete namespace microk10-demo --wait=true --timeout="${WAIT_TIMEOUT}"
  else
    log INFO "Demo namespace is not present."
  fi
}

confirm() {
  local prompt="$1"
  if [[ "${YES}" == true ]]; then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    fatal "Confirmation required in non-interactive mode. Re-run with --yes."
  fi
  local response
  read -r -p "${prompt} [y/N] " response
  [[ "${response}" =~ ^[Yy]$ ]]
}

uninstall_kasten() {
  microk8s_installed || fatal "MicroK8s is not installed."
  confirm "Remove Veeam Kasten release ${KASTEN_NAMESPACE}/${KASTEN_RELEASE}?" || fatal "Cancelled."
  if run_as_root microk8s helm3 status "${KASTEN_RELEASE}" --namespace "${KASTEN_NAMESPACE}" >/dev/null 2>&1; then
    run_as_root microk8s helm3 uninstall "${KASTEN_RELEASE}" --namespace "${KASTEN_NAMESPACE}" --wait --timeout "${WAIT_TIMEOUT}"
  fi
  run_as_root microk8s kubectl delete namespace "${KASTEN_NAMESPACE}" --ignore-not-found --wait=true --timeout="${WAIT_TIMEOUT}"

  if [[ "${PURGE_MICROK8S}" == true ]]; then
    confirm "Also remove the MicroK8s snap and all cluster data?" || fatal "MicroK8s purge cancelled."
    run_as_root snap remove microk8s --purge
  fi
  log OK "Uninstall completed."
}

upgrade_microk8s() {
  validate_channel
  require_root_or_sudo
  microk8s_installed || fatal "MicroK8s is not installed."
  confirm "Refresh MicroK8s to ${MICROK8S_CHANNEL}?" || fatal "Cancelled."
  run_as_root snap refresh microk8s --channel="${MICROK8S_CHANNEL}"
  wait_for_microk8s
  validate_kubernetes_version
}

upgrade_kasten() {
  install_kasten
}
