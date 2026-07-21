# Architecture

## Design goals

MicroK10 is a thin lifecycle layer, not a Kubernetes distribution or a replacement for Helm. It provides deterministic compatibility, safe host checks, repeatable installation, actionable failures, and a small backup-ready demo workload.

## Components

- `microk10`: small CLI entrypoint and configuration bootstrap.
- `lib/`: focused core, platform, Kasten, and command-routing modules.
- `config/compatibility.env`: reviewed release and platform matrix.
- `manifests/demo-pvc.yaml`: non-privileged PVC-backed test workload.
- `tests/unit.sh`: unit coverage for version and compatibility logic.
- `.github/workflows`: linting, host smoke tests, release packaging, upstream release monitoring, and release-matrix validation.
- legacy `*.sh` files: thin migration wrappers with no embedded implementation.

## Lifecycle

1. Validate Linux, architecture, Ubuntu release, resources, and the requested MicroK8s channel.
2. Install MicroK8s from a versioned stable track.
3. Wait for readiness and enable CoreDNS and hostpath storage.
4. Verify the Kubernetes server minor against the Kasten matrix.
5. Verify the requested StorageClass.
6. Run the official Kasten primer.
7. Download the Kasten signing key and verify Helm chart provenance.
8. Perform an atomic `helm upgrade --install` and wait for workloads.
9. Validate rollout state and reject unhealthy pods.

## Explicit non-goals

- Editing netplan or selecting host interfaces.
- Creating known/default passwords.
- Exposing the Kasten dashboard publicly.
- Pretending hostpath storage is resilient production storage.
- Automatically crossing unsupported Kubernetes version boundaries.
- Bundling or managing an object-storage appliance on the Kubernetes host.
