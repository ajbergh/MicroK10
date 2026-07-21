# MicroK10 Rocky Linux virtual appliance

## Product definition

MicroK10 is an import-and-boot single-node Kubernetes lab appliance centered on Veeam Kasten. The downloadable artifact is an OVA built from a Rocky Linux minimal ISO. Users should not need to install Linux, MicroK8s, Kasten, or MinIO manually.

The appliance console is the primary user experience. The `microk10` CLI remains the underlying lifecycle engine so every console operation can also be executed, tested, and diagnosed from a maintenance shell.

## Layered architecture

```text
Rocky Linux VM
├── NetworkManager / nmcli
├── open-vm-tools
├── MicroK10 appliance console (dialog TUI)
│   ├── first-boot wizard
│   ├── network setup
│   ├── component status
│   ├── MinIO management
│   ├── guided Kasten labs
│   └── factory reset
├── MicroK10 lifecycle CLI
│   ├── MicroK8s lifecycle
│   ├── Kasten lifecycle
│   ├── compatibility guardrails
│   ├── validation
│   └── demo workload
├── MicroK8s
│   ├── Kubernetes
│   ├── hostpath storage
│   ├── DNS / Helm
│   ├── Veeam Kasten
│   └── demo workloads
└── Podman/systemd
    └── MinIO object storage
```

## Why Rocky Linux

Rocky Linux provides an enterprise-Linux appliance base while allowing MicroK10 to keep MicroK8s. The image installs EPEL and `snapd`, then installs MicroK8s from Canonical's selected snap channel.

The default image is Rocky Linux 9.8. Rocky Linux 10.2 is an additional current-release target that must pass the same end-to-end appliance tests before it is promoted to the default.

## First boot

The appliance console owns `tty1` through `microk10-console.service`. When no initialized state exists under `/var/lib/microk10`, the console enters first-boot mode.

The wizard performs:

1. DHCP or static IPv4 selection.
2. Network route, DNS, and HTTPS validation.
3. Optional MicroK8s + Kasten installation.
4. Optional MinIO installation.
5. Optional Kasten MinIO Location Profile creation.
6. Optional demo workload installation.
7. Persistent appliance initialization state.

A failed or skipped step does not brick the appliance; every function remains available from the main console afterward.

## Networking

Rocky Linux NetworkManager is authoritative. MicroK10 detects the primary interface from the default route and uses `nmcli` rather than assuming VMware interface names such as `ens160`.

Static configuration requires:

- IPv4 address including CIDR;
- default gateway;
- one or more DNS servers.

Connectivity validation checks:

- default route availability;
- DNS resolution;
- outbound HTTPS access to the Kasten chart endpoint.

## MinIO

MinIO runs outside MicroK8s in a Podman container managed by `microk10-minio.service`.

Persistent data:

```text
/var/lib/microk10/minio
```

Credentials:

```text
/etc/microk10/minio.env
```

Credentials are generated locally with OpenSSL and are not baked into the OVA.

The appliance creates the `k10-backups` bucket and can automatically create/update the Kasten `microk10-local-minio` Location Profile.

## Guided Kasten labs

The console can create a real Kasten backup/export Policy for the `microk10-demo` namespace. The policy performs a backup and an export to local MinIO.

A manual lab run is triggered through the Kasten `RunAction` API and monitored until completion or failure. The user can then delete the demo namespace and restore it from Kasten to demonstrate application recovery.

This is intentionally a real API workflow rather than a simulated tutorial.

## Factory reset

Factory reset removes:

- Kasten and MicroK8s;
- local MinIO container/service configuration;
- MinIO data;
- generated MinIO credentials;
- MicroK10 appliance state.

The system then reboots and returns to first-boot mode.

Network configuration is currently retained by factory reset. A later enhancement may offer a separate 'reset networking' choice to avoid disconnecting a remotely managed appliance unexpectedly.

## OVA build pipeline

Packer's VMware ISO builder installs Rocky from official minimal media and exports an OVA.

Build sequence:

```text
Rocky minimal ISO
  -> Packer HTTP server
  -> templated Kickstart
  -> SSH-key-only temporary build access
  -> copy MicroK10 source
  -> provision EPEL/snapd/Podman/open-vm-tools
  -> install systemd appliance console
  -> remove build authorization
  -> lock build account
  -> remove SSH host keys
  -> clear machine-id
  -> clean caches
  -> shutdown
  -> OVA export
```

No fixed build password is committed or shipped. The Packer caller provides an ephemeral SSH key pair and the public key is injected into the Kickstart with `templatefile()`.

## Image identity

The build clears machine-specific identity before export:

- `/etc/machine-id`;
- `/var/lib/dbus/machine-id`;
- `/etc/ssh/ssh_host_*`.

Rocky/systemd regenerates machine identity and SSH host keys when the imported appliance boots.

## Build targets

Current x86_64 profiles:

- `appliance/packer/rocky-9.8.pkrvars.hcl`
- `appliance/packer/rocky-10.2.pkrvars.hcl`

Both use official Rocky minimal ISOs and published checksum files.

## CI strategy

Three validation tiers are intended:

### Tier 1: source validation

- Bash parser
- ShellCheck
- shfmt
- unit tests
- lifecycle dry run
- plaintext secret scan

### Tier 2: Rocky host compatibility

Rocky Linux 9.8 and 10.2 containers are tested on x86_64 and arm64 runners for source portability and compatibility policy behavior.

### Tier 3: appliance integration

Self-hosted VMware builders perform the authoritative appliance validation:

1. Build OVA.
2. Import and boot VM.
3. Complete first-boot networking.
4. Install MicroK8s.
5. Install Kasten.
6. Install MinIO.
7. Create Kasten Location Profile.
8. Deploy demo workload.
9. Run backup + export.
10. Delete demo namespace.
11. Restore and validate data.
12. Factory reset.

Tier 3 is the release gate for publishing an OVA.
