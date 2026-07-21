# Compatibility policy

MicroK10 is deliberately conservative. The appliance defaults to the newest Kubernetes minor in the configured Veeam Kasten support matrix, not the newest Kubernetes release available from the Snap Store.

## Validated appliance matrix for 1.0.0-rc.2

| Veeam Kasten | Kubernetes / MicroK8s channels | Rocky Linux appliance | Architectures |
|---|---|---|---|
| 9.0.1 | 1.31/stable, 1.32/stable, 1.33/stable, 1.34/stable | 9.8 default; 10.2 build/test | amd64, arm64 lifecycle code; x86_64 OVA first-class |

Rocky Linux is not itself the Kubernetes distribution. MicroK10 installs `snapd` from EPEL and then installs the selected Canonical MicroK8s snap. Canonical documents MicroK8s as usable on Linux systems that support `snapd`, while current Fedora EPEL repositories publish `snapd` packages for EL9 and EL10.2.

Kubernetes 1.35 is intentionally blocked until it enters the configured Kasten support matrix. `--allow-unsupported` exists for deliberate engineering tests only.

## Appliance OS policy

Rocky Linux 9.8 is the default appliance image because it is the conservative enterprise-Linux baseline for the first MicroK10 OVA release.

Rocky Linux 10.2 is built and smoke-tested in parallel. It should become eligible as a default only after the complete appliance workflow passes:

1. ISO installation and OVA export.
2. First-boot network configuration.
3. EPEL/snapd bootstrap.
4. MicroK8s installation.
5. Kasten primer and Kasten installation.
6. MinIO installation and Kasten Location Profile creation.
7. Demo workload deployment.
8. Backup and export to local MinIO.
9. Destructive demo removal and successful recovery.
10. Factory reset and clean reinitialization.

## Updating the matrix

1. Confirm the current Rocky minor releases and support status.
2. Confirm EPEL publishes a working `snapd` build for those Enterprise Linux versions.
3. Confirm the current Kasten release and supported Kubernetes minors.
4. Confirm each selected MicroK8s stable track exists.
5. Update `config/compatibility.env`.
6. Run the Rocky host smoke matrix.
7. Run the live MicroK8s/Kasten matrix on Rocky self-hosted runners.
8. Build and boot both Rocky OVA variants.
9. Update this file and `CHANGELOG.md` in the same pull request.

## Storage qualification

The built-in `microk8s-hostpath` class is intentionally a single-node lab storage class. It is not resilient production storage and does not imply CSI snapshot capability.

Local MinIO is also a lab convenience. It is deliberately outside the MicroK8s cluster so that destructive cluster exercises can retain exported backup data, but it still resides on the same virtual appliance and therefore is not a substitute for an independent production backup repository.

## Architecture-specific limitations

The lifecycle engine continues to support amd64 and arm64 where upstream MicroK8s and Kasten functionality permits. The initial VMware Workstation-oriented OVA pipeline is x86_64-first. arm64 appliance images should use an architecture-appropriate VMware/Fusion build environment and must pass the same end-to-end appliance tests before release.
