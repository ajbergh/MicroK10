# Compatibility policy

MicroK10 is deliberately conservative. The default MicroK8s channel is the newest Kubernetes minor supported by the pinned Veeam Kasten release, not the newest Kubernetes minor available from the Snap Store.

## Validated matrix for 1.0.0-rc.1

| Veeam Kasten | Kubernetes / MicroK8s channels | Ubuntu | Architectures |
|---|---|---|---|
| 9.0.1 | 1.31/stable, 1.32/stable, 1.33/stable, 1.34/stable | 22.04, 24.04, 26.04 | amd64, arm64 |

Kubernetes 1.29 and 1.30 are not included for standard Kubernetes distributions in the Kasten 9.0.1 support matrix. Kubernetes 1.35 is available from MicroK8s but is not yet in the Kasten 9.0.1 support matrix.

## Updating the matrix

1. Confirm the current Kasten version and supported Kubernetes minors in the official Kasten documentation.
2. Confirm each MicroK8s stable track exists in the Snap Store.
3. Update `config/compatibility.env`.
4. Run `make validate`.
5. Run the `MicroK8s integration matrix` workflow for every supported minor.
6. Update this file and `CHANGELOG.md` in the same pull request.

`--allow-unsupported` disables the compatibility guardrail for engineering tests only. It does not make an unsupported combination production-ready or vendor-supported.

## Storage qualification

The built-in `microk8s-hostpath` class is intended for a single-node demonstration. Volumes are node-local and do not provide storage-level snapshot capability. Use a CSI driver with tested snapshot support and run the Kasten CSI primer before treating a cluster as production-capable.

## Architecture-specific limitations

Veeam Kasten supports installation on Linux amd64 and arm64/v8. Some upstream capabilities are architecture-specific; in Kasten 9.0.x, Veeam Repository Exports and vSphere Block Mode Exports are not available on arm64. MicroK10 validates installation and core health on both architectures but does not imply feature parity beyond the upstream support matrix.
