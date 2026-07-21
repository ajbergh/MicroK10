#!/usr/bin/env bash
set -Eeuo pipefail

MINIO_STATE_DIR="${MINIO_STATE_DIR:-/var/lib/microk10/minio}"
MINIO_ENV="${MINIO_ENV:-/etc/microk10/minio.env}"
MINIO_BUCKET="${MINIO_BUCKET:-k10-backups}"
MINIO_REGION="${MINIO_REGION:-us-east-1}"

load_minio_env() {
  [[ -r "${MINIO_ENV}" ]] || {
    echo 'MinIO is not configured.' >&2
    return 1
  }
  # shellcheck disable=SC1090
  source "${MINIO_ENV}"
}

configure_minio_firewall() {
  command -v firewall-cmd >/dev/null 2>&1 || return 0
  systemctl is-active --quiet firewalld || return 0
  firewall-cmd --permanent --add-port=9000/tcp >/dev/null
  firewall-cmd --permanent --add-port=9001/tcp >/dev/null
  firewall-cmd --reload >/dev/null
}

install_minio() {
  install -d -m 0700 /etc/microk10 "${MINIO_STATE_DIR}"
  if [[ ! -f "${MINIO_ENV}" ]]; then
    umask 077
    cat >"${MINIO_ENV}" <<EOF
MINIO_ROOT_USER=$(printf 'mk10-%s' "$(openssl rand -hex 8)")
MINIO_ROOT_PASSWORD=$(openssl rand -base64 36 | tr -d '\n')
EOF
  fi
  podman pull quay.io/minio/minio:latest
  cat >/etc/systemd/system/microk10-minio.service <<EOF
[Unit]
Description=MicroK10 local MinIO
After=network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=${MINIO_ENV}
ExecStart=/usr/bin/podman run --rm --name microk10-minio --network host -v ${MINIO_STATE_DIR}:/data:Z quay.io/minio/minio:latest server /data --address :9000 --console-address :9001
ExecStop=/usr/bin/podman stop -t 15 microk10-minio
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  configure_minio_firewall
  systemctl daemon-reload
  systemctl enable --now microk10-minio.service
  for _ in {1..30}; do
    curl --fail --silent http://127.0.0.1:9000/minio/health/live >/dev/null && break
    sleep 2
  done
  curl --fail --silent http://127.0.0.1:9000/minio/health/live >/dev/null
  create_minio_bucket
}

create_minio_bucket() {
  load_minio_env
  podman pull quay.io/minio/mc:latest
  podman run --rm --network host quay.io/minio/mc:latest \
    alias set microk10 http://127.0.0.1:9000 "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" >/dev/null
  podman run --rm --network host quay.io/minio/mc:latest \
    mb --ignore-existing "microk10/${MINIO_BUCKET}"
}

appliance_ipv4() {
  ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="src") {print $(i+1); exit}}'
}

configure_kasten_minio() {
  load_minio_env
  command -v microk8s >/dev/null || {
    echo 'MicroK8s must be installed first.' >&2
    return 1
  }
  microk8s kubectl get namespace kasten-io >/dev/null 2>&1 || {
    echo 'Kasten must be installed first.' >&2
    return 1
  }
  local endpoint_ip
  endpoint_ip="$(appliance_ipv4)"
  [[ -n "${endpoint_ip}" ]] || {
    echo 'Unable to determine appliance IPv4 address.' >&2
    return 1
  }

  microk8s kubectl -n kasten-io create secret generic microk10-minio \
    --type secrets.kanister.io/aws \
    --from-literal=aws_access_key_id="${MINIO_ROOT_USER}" \
    --from-literal=aws_secret_access_key="${MINIO_ROOT_PASSWORD}" \
    --dry-run=client -o yaml | microk8s kubectl apply -f -

  cat <<EOF | microk8s kubectl apply -f -
apiVersion: config.kio.kasten.io/v1alpha1
kind: Profile
metadata:
  name: microk10-local-minio
  namespace: kasten-io
spec:
  type: Location
  locationSpec:
    type: ObjectStore
    objectStore:
      objectStoreType: S3
      endpoint: http://${endpoint_ip}:9000
      name: ${MINIO_BUCKET}
      region: ${MINIO_REGION}
      skipSSLVerify: true
    credential:
      secretType: AwsAccessKey
      secret:
        apiVersion: v1
        kind: secret
        name: microk10-minio
        namespace: kasten-io
EOF
}

minio_credentials() {
  load_minio_env
  printf 'MINIO_ROOT_USER=%s\nMINIO_ROOT_PASSWORD=%s\n' "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"
}

minio_status() {
  systemctl --no-pager --full status microk10-minio.service
}
