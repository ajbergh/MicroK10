# Changelog

All notable changes are documented here.

## 1.0.0-rc.2 - 2026-07-21

### Added

- Rocky Linux 9.8 default virtual-appliance target with Rocky Linux 10.2 build/test coverage.
- `dialog`-based first-boot and ongoing appliance console on `tty1`.
- NetworkManager-based DHCP/static IPv4 configuration and connectivity validation.
- Rocky EPEL + `snapd` bootstrap for MicroK8s.
- Local MinIO service outside Kubernetes using Podman/systemd.
- Runtime-generated MinIO administrative credentials and automatic backup bucket creation.
- Automatic Kasten MinIO Location Profile integration.
- Guided Kasten backup/export lab using real Policy and RunAction APIs.
- Appliance initialization state and destructive factory reset.
- Reproducible Rocky ISO-to-OVA Packer build with templated Kickstart and ephemeral SSH-key-only build access.
- Rocky 9.8/10.2 host smoke matrix and self-hosted Rocky MicroK8s/Kasten integration workflow.
- Self-hosted VMware OVA build workflow.

### Changed

- Repositioned MicroK10 from a generic Linux installer into a self-contained single-node Kubernetes + Veeam Kasten lab appliance.
- Replaced Ubuntu host compatibility policy with Rocky Linux appliance compatibility policy.
- Moved appliance networking into an explicit Rocky/NetworkManager layer rather than generic netplan mutation.
- Extended linting, formatting, and plaintext-secret scanning across appliance and Packer sources.

### Security

- Removed fixed build credentials from the active appliance image definition.
- Packer uses ephemeral SSH keys that are removed before OVA export.
- Build-only sudo authorization, machine ID, and SSH host keys are removed during final image shutdown.
- MinIO username and password are generated on the appliance rather than embedded in source.
- SELinux remains enforcing in the Rocky image.

## 1.0.0-rc.1 - 2026-07-21

### Added

- Single idempotent `microk10` lifecycle CLI with testable dry-run planning.
- Validated Ubuntu 22.04, 24.04, and 26.04 host matrix for the initial lifecycle-engine modernization.
- Validated Kubernetes 1.31 through 1.34 matrix for Veeam Kasten 9.0.1.
- Official Kasten primer execution and Helm chart provenance verification.
- Safe loopback dashboard access, status, validation, upgrade, and uninstall commands.
- Non-privileged PVC-backed demo workload.
- CI linting, formatting, tests, current-tree secret checks, host smoke coverage, integration, release packaging, and upstream release monitoring.
- Security, architecture, compatibility, and contribution documentation.

### Changed

- Replaced fixed sleeps with readiness, rollout, and health checks.
- Replaced hard-coded Kubernetes 1.21 with versioned supported channels.
- Replaced all legacy scripts with migration wrappers.

### Removed

- Embedded credentials and known default passwords from the active tree.
- Hard-coded `ens160` netplan modifications.
- Implicit public dashboard exposure.
