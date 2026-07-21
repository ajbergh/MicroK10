# Architecture

## Design goals

MicroK10 is a virtual appliance product built around a scriptable lifecycle engine. The appliance should feel turnkey at the VM console while keeping Kubernetes, Kasten, MinIO, networking, and recovery workflows observable and automatable underneath.

The design separates presentation from lifecycle logic:

- the appliance TUI handles user interaction;
- appliance libraries handle Rocky host functions such as networking, state, MinIO, and guided labs;
- the `microk10` CLI handles MicroK8s and Kasten lifecycle operations;
- Packer creates a reproducible OVA from official Rocky Linux media.

## Components

- `microk10`: lifecycle CLI entrypoint and configuration bootstrap.
- `lib/`: core, Rocky platform, Kasten, command-routing, and appliance compatibility modules.
- `appliance/microk10-tui`: console UI presented on `tty1`.
- `appliance/lib/network.sh`: NetworkManager-based DHCP/static configuration and validation.
- `appliance/lib/state.sh`: first-boot and factory-reset state management.
- `appliance/lib/minio.sh`: local MinIO service, bucket, credentials, and Kasten Profile integration.
- `appliance/lib/labs.sh`: guided Kasten Policy/RunAction backup and recovery lab automation.
- `appliance/systemd/`: console service units.
- `appliance/packer/`: Rocky Linux ISO-to-OVA build definitions.
- `config/compatibility.env`: reviewed Rocky/Kubernetes/Kasten matrix.
- `manifests/demo-pvc.yaml`: non-privileged PVC-backed recovery workload.
- `.github/workflows`: linting, Rocky host smoke tests, OVA builds, release packaging, and upstream monitoring.

## Appliance lifecycle

1. Import and power on the Rocky Linux OVA.
2. systemd starts the MicroK10 console on `tty1`.
3. First-boot state launches the setup wizard.
4. NetworkManager configures DHCP or static IPv4 without assuming a NIC name.
5. Connectivity is verified before installation.
6. EPEL and `snapd` are bootstrapped when needed.
7. MicroK8s is installed from the selected versioned stable track.
8. Kubernetes is checked against the configured Kasten matrix.
9. The Kasten primer is executed.
10. Kasten chart provenance is verified and Kasten is installed atomically.
11. Optional MinIO is deployed outside Kubernetes through Podman/systemd.
12. A Kasten Location Profile can be wired automatically to local MinIO.
13. Optional demo workloads and guided backup/export/recovery labs become available.
14. Factory reset returns the appliance to an uninitialized lab state.

## OVA build lifecycle

1. Packer downloads official Rocky Linux minimal media and verifies its published checksum.
2. A Kickstart is rendered with an ephemeral SSH public key.
3. Rocky is installed with SELinux enforcing and open-vm-tools enabled.
4. MicroK10 source is copied into `/opt/microk10`.
5. EPEL, snapd, Podman, dialog, and appliance dependencies are provisioned.
6. The console service is enabled.
7. Build-only SSH/sudo authorization is removed.
8. Machine and SSH host identities are cleared.
9. Package caches are removed.
10. The VM is shut down and exported as an OVA.

## Networking boundary

The generic lifecycle engine does not blindly rewrite arbitrary Linux networking. Network mutation belongs specifically to the virtual appliance layer, where Rocky Linux NetworkManager is an explicit product dependency and the interface can be safely managed through `nmcli`.

## Storage boundary

`microk8s-hostpath` is intentionally a single-node lab StorageClass.

Local MinIO provides a durable-enough independent service boundary for destructive Kubernetes exercises because it is outside MicroK8s, but it still shares the same VM and virtual disk unless additional disks are configured. It is not presented as production-safe backup isolation.

## Security boundaries

- No known default credentials are shipped.
- Packer build access is SSH-key-only and removed before export.
- MinIO credentials are generated on the appliance.
- SELinux remains enforcing.
- Kasten dashboard access remains loopback-bound by default.
- Unsupported Kubernetes version crossings require explicit override.
- Factory reset is explicit and destructive.

## Future architecture extensions

- dedicated second virtual disk for MinIO repository data;
- automatic restore execution from the most recent Kasten restore point;
- vSphere-native Packer builder alongside VMware Workstation/Fusion;
- appliance update bundles with signed manifests;
- optional web management UI backed by the same appliance service layer;
- offline/air-gapped image bundle support.
