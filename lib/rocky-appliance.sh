#!/usr/bin/env bash
# Rocky Linux appliance-specific compatibility helpers.

is_tested_rocky() {
  value_in_space_list "$1" "${MICROK10_TESTED_ROCKY}"
}

print_compatibility() {
  cat <<EOF_COMPAT
MicroK10 ${MICROK10_RELEASE_VERSION}

Validated appliance OS:          Rocky Linux ${MICROK10_TESTED_ROCKY}
Default appliance OS:            Rocky Linux ${MICROK10_DEFAULT_ROCKY}
Validated architectures:         ${MICROK10_SUPPORTED_ARCHITECTURES}
Validated Kubernetes minors:     ${MICROK10_SUPPORTED_KUBERNETES}
Default MicroK8s channel:        ${MICROK10_DEFAULT_MICROK8S_CHANNEL}
Default Veeam Kasten version:    ${MICROK10_DEFAULT_KASTEN_VERSION}

MicroK8s latest/stable is intentionally not used because it may advance beyond
Veeam Kasten's currently supported Kubernetes matrix.
EOF_COMPAT
}
