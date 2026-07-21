#!/usr/bin/env bash
set -Eeuo pipefail

LAB_NAMESPACE="microk10-demo"
LAB_POLICY="microk10-demo-backup-export"
LAB_PROFILE="microk10-local-minio"

create_lab_policy() {
  microk8s kubectl get namespace "${LAB_NAMESPACE}" >/dev/null 2>&1 || /opt/microk10/microk10 demo install
  microk8s kubectl -n kasten-io get profile.config.kio.kasten.io "${LAB_PROFILE}" >/dev/null 2>&1 || {
    echo "Kasten MinIO profile ${LAB_PROFILE} does not exist." >&2
    return 1
  }
  cat <<EOF | microk8s kubectl apply -f -
apiVersion: config.kio.kasten.io/v1alpha1
kind: Policy
metadata:
  name: ${LAB_POLICY}
  namespace: kasten-io
spec:
  comment: MicroK10 guided backup and MinIO export lab
  frequency: '@daily'
  retention:
    daily: 3
  actions:
    - action: backup
    - action: export
      exportParameters:
        frequency: '@daily'
        profile:
          name: ${LAB_PROFILE}
          namespace: kasten-io
        exportData:
          enabled: true
      retention:
        daily: 3
  selector:
    matchLabels:
      k10.kasten.io/appNamespace: ${LAB_NAMESPACE}
EOF
  microk8s kubectl -n kasten-io wait --for=jsonpath='{.status.status}=Success' "policy.config.kio.kasten.io/${LAB_POLICY}" --timeout=180s
}

run_lab_backup() {
  create_lab_policy
  local run_name state
  run_name="$(
    cat <<EOF | microk8s kubectl create -f - -o jsonpath='{.metadata.name}'
apiVersion: actions.kio.kasten.io/v1alpha1
kind: RunAction
metadata:
  generateName: microk10-run-
  namespace: kasten-io
spec:
  subject:
    kind: Policy
    name: ${LAB_POLICY}
    namespace: kasten-io
EOF
  )"
  echo "Started Kasten run ${run_name}."
  for _ in {1..120}; do
    state="$(microk8s kubectl -n kasten-io get runaction.actions.kio.kasten.io "${run_name}" -o jsonpath='{.status.state}' 2>/dev/null || true)"
    case "${state}" in
    Complete)
      echo "Backup/export completed successfully."
      return 0
      ;;
    Failed | Error)
      echo "Backup/export failed with state ${state}." >&2
      return 1
      ;;
    esac
    sleep 10
  done
  echo "Timed out waiting for ${run_name}." >&2
  return 1
}

show_demo_data() {
  microk8s kubectl -n "${LAB_NAMESPACE}" exec deployment/microk10-demo -- sh -c 'printf "created-at: "; cat /data/created-at; printf "recent activity:\n"; tail -n 5 /data/activity.log'
}

delete_demo_for_restore_lab() {
  microk8s kubectl delete namespace "${LAB_NAMESPACE}" --wait=true
  echo "Demo namespace deleted. Restore it from the latest restore point in the Kasten dashboard."
}

list_demo_restore_points() {
  microk8s kubectl get restorepoints.apps.kio.kasten.io --all-namespaces \
    -l "k10.kasten.io/appNamespace=${LAB_NAMESPACE}" -o wide
}
