# MicroK10

MicroK10 is a self-contained **Rocky Linux single-node Kubernetes + Veeam Kasten lab appliance**. The intended user experience is simple: import the OVA, boot the VM, configure networking from the graphical console menu, then deploy and manage MicroK8s, Veeam Kasten, local MinIO object storage, demo workloads, and guided backup/recovery labs from one appliance.

The modern `microk10` CLI remains the lifecycle engine underneath the appliance console. The console is presentation and orchestration; installation, validation, upgrade, and uninstall behavior stays scriptable and testable.

## Appliance compatibility

| Component | Current target |
|---|---|
| Appliance OS | Rocky Linux 9.8 default; Rocky Linux 10.2 build/test target |
| OVA architecture | x86_64 first-class build target |
| MicroK8s / Kubernetes | 1.31, 1.32, 1.33, 1.34 stable channels |
| Default Kubernetes | 1.34/stable |
| Veeam Kasten | 9.0.1 |
| Local object storage | MinIO running outside Kubernetes via Podman/systemd |
| Virtualization | VMware Workstation/Fusion OVA build path; vSphere import compatible |

MicroK8s `latest/stable` is intentionally not used because it may advance beyond Veeam Kasten's supported Kubernetes matrix. Unsupported Kubernetes combinations remain blocked unless `--allow-unsupported` is supplied deliberately.

## Appliance experience

At boot, MicroK10 owns the VM console on `tty1` and starts a `dialog`-based appliance interface. First boot walks through:

1. Network configuration using Rocky Linux NetworkManager.
2. Connectivity validation.
3. MicroK8s installation.
4. Veeam Kasten installation and validation.
5. Optional local MinIO installation.
6. Automatic Kasten MinIO Location Profile creation.
7. Optional PVC-backed demo workload deployment.

After setup, the same console provides:

- network configuration and testing;
- Kubernetes/Kasten install and status;
- Kasten dashboard port-forwarding;
- MinIO lifecycle, credentials, and Location Profile management;
- demo workload deployment;
- guided Kasten backup/export/recovery labs;
- validation and diagnostics;
- maintenance shell access;
- factory reset;
- reboot and shutdown.

## Guided Kasten lab

The appliance can prepare and run a real Kasten backup/export workflow for the `microk10-demo` namespace:

1. Deploy a PVC-backed application that continuously writes data.
2. Create a Kasten Policy selecting the demo namespace.
3. Back up the application and export it to local MinIO.
4. Trigger the policy immediately through a Kasten `RunAction`.
5. Wait for the run to complete.
6. Inspect restore points.
7. Delete the demo namespace to simulate application loss.
8. Restore the application through the Kasten dashboard and verify its persistent data.

## Local MinIO design

MinIO deliberately runs **outside the MicroK8s cluster** as a Podman container managed by systemd. Its data lives under `/var/lib/microk10/minio`.

This makes the appliance useful for destructive Kubernetes lab exercises: removing or rebuilding the MicroK8s cluster does not automatically remove the object-storage repository.

Credentials are randomly generated on first MinIO installation and written with restricted permissions under `/etc/microk10/minio.env`. No known default password is embedded in the active source tree or appliance image.

## Build the OVA

The OVA is produced with Packer and the VMware ISO builder.

Prerequisites on the build workstation:

- VMware Workstation Pro or VMware Fusion Pro;
- VMware OVF Tool;
- Packer;
- `ssh-keygen`;
- Internet access to Rocky Linux repositories and the Snap Store.

Example Rocky Linux 9.8 build:

```powershell
ssh-keygen -t ed25519 -N "" -f $env:TEMP\microk10-packer
$pub = Get-Content "$env:TEMP\microk10-packer.pub" -Raw

packer init appliance/packer/rocky-microk10.pkr.hcl
packer build `
  -var-file=appliance/packer/rocky-9.8.pkrvars.hcl `
  -var "ssh_public_key=$pub" `
  -var "ssh_private_key_file=$env:TEMP\microk10-packer" `
  appliance/packer/rocky-microk10.pkr.hcl
```

Use `rocky-10.2.pkrvars.hcl` for the Rocky Linux 10.2 build/test image.

The Packer build uses a templated Kickstart and an ephemeral SSH key. The provisioning stage removes the build authorization, locks the build account, deletes SSH host keys, truncates machine identity, cleans package caches, and exports an uninitialized appliance OVA.

## Development from a Rocky Linux host

The CLI can also be used without building an OVA:

```bash
git clone https://github.com/ajbergh/MicroK10.git
cd MicroK10
sudo ./microk10 install
```

On Rocky Linux, MicroK10 bootstraps EPEL and `snapd`, enables classic snap support, and installs the selected MicroK8s channel.

Common commands:

```bash
./microk10 compatibility
sudo ./microk10 install
sudo ./microk10 status
sudo ./microk10 validate
sudo ./microk10 demo install
sudo ./microk10 dashboard
```

## Security model

- No fixed appliance, MinIO, Kasten, or demo credentials are shipped.
- Packer build access is SSH-key-only and removed before image export.
- SELinux remains enforcing in the Rocky image.
- The Kasten dashboard binds to loopback by default.
- The Kasten chart is installed with provenance verification unless explicitly disabled.
- The official Kasten primer runs before installation unless explicitly skipped.
- MinIO secrets are generated locally and stored with restricted filesystem permissions.
- Factory reset is an explicit destructive operation.
- The old public repository history contains obsolete demo credentials; treat all of them as permanently compromised.

## Repository layout

```text
appliance/
  lib/                  Appliance network, state, MinIO, and lab functions
  packer/               Rocky Linux OVA build definitions
  systemd/              Appliance console systemd units
  microk10-tui          Graphical console interface
config/                 Release compatibility policy
lib/                    MicroK10 lifecycle engine
manifests/              Demo Kubernetes resources
tests/                  Unit, dry-run, and security validation
microk10                Lifecycle CLI entrypoint
```

See `docs/APPLIANCE.md`, `docs/ARCHITECTURE.md`, `docs/COMPATIBILITY.md`, `SECURITY.md`, and `CONTRIBUTING.md` for additional implementation details.
