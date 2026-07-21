# Changelog

All notable changes are documented here.

## 1.0.0-rc.1 - 2026-07-21

### Added

- Single idempotent `microk10` lifecycle CLI with testable dry-run planning.
- Validated Ubuntu 22.04, 24.04, and 26.04 host matrix.
- Validated Kubernetes 1.31 through 1.34 matrix for Veeam Kasten 9.0.1.
- Official Kasten primer execution and Helm chart provenance verification.
- Safe loopback dashboard access, status, validation, upgrade, and uninstall commands.
- Non-privileged PVC-backed demo workload.
- CI linting, formatting, tests, current-tree secret checks, six-host smoke coverage, scheduled amd64/arm64 integration, release packaging, and upstream release monitoring.
- Security, architecture, compatibility, and contribution documentation.

### Changed

- Replaced fixed sleeps with readiness, rollout, and health checks.
- Replaced hard-coded Kubernetes 1.21 with versioned supported channels.
- Replaced all legacy scripts with migration wrappers.

### Removed

- Embedded credentials and known default passwords.
- Hard-coded `ens160` netplan modifications.
- Implicit public dashboard exposure.
- In-host MinIO installation and fixed endpoint assumptions.
