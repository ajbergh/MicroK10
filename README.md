# MicroK10

MicroK10 provisions a small, support-aware MicroK8s lab and installs Veeam Kasten with secure defaults, pre-flight validation, chart provenance verification, deterministic versions, and repeatable lifecycle commands.

The original 2021 proof of concept pinned Kubernetes 1.21, modified a hard-coded `ens160` interface, embedded credentials, suppressed errors, and relied on fixed sleeps. The modern implementation replaces those scripts with one idempotent CLI and preserves the old filenames only as compatibility wrappers.

## Current compatibility

| Component | Validated releases |
|---|---|
| Ubuntu | 22.04 LTS, 24.04 LTS, 26.04 LTS |
| Host architecture | amd64, arm64 |
| MicroK8s / Kubernetes | 1.31, 1.32, 1.33, 1.34 stable channels |
| Veeam Kasten | 9.0.1 |

MicroK8s `latest/stable` currently resolves to Kubernetes 1.35. MicroK10 intentionally defaults to `1.34/stable` because Veeam Kasten 9.0.1 supports standard Kubernetes 1.31 through 1.34. Unsupported combinations are blocked unless `--allow-unsupported` is supplied deliberately.

## Requirements

Use a clean Linux VM or host with:

- Ubuntu 22.04, 24.04, or 26.04
- amd64 or arm64 CPU
- root or passwordless/current-session sudo access
- at least 6 GiB RAM and 20 GiB free under `/var` for a lab installation
- outbound HTTPS access to the Snap Store, Kasten chart repository, Kasten documentation downloads, and container registries

Hostpath storage is suitable for a single-node lab, not resilient production storage. Kasten backup/export operations need materially more capacity than a basic installation.

## Quick start

```bash
git clone https://github.com/ajbergh/MicroK10.git
cd MicroK10
sudo ./microk10 install
```

Then open the dashboard through a loopback-only port forward:

```bash
sudo ./microk10 dashboard
```

Browse to `http://127.0.0.1:8080/k10/#/`.

## Common commands

```bash
# Show the compatibility matrix
./microk10 compatibility

# Install another currently supported Kubernetes minor
sudo ./microk10 install --microk8s-channel 1.31/stable

# Install Kasten with an additional values file
sudo ./microk10 install-kasten --values ./my-values.yaml

# Enable MetalLB for a lab network
sudo ./microk10 install-microk8s --metallb-range 192.168.50.220-192.168.50.230

# Install a small PVC-backed workload for backup testing
sudo ./microk10 demo install

# Validate the cluster and Kasten release
sudo ./microk10 validate

# Show cluster status
sudo ./microk10 status

# Upgrade after updating the pinned compatibility file/release
sudo ./microk10 upgrade-microk8s --microk8s-channel 1.34/stable
sudo ./microk10 upgrade-kasten --kasten-version 9.0.1
```

Run `./microk10 help` for every option.

## Security model

- No credentials are embedded or generated with known defaults.
- The Kasten dashboard binds to `127.0.0.1` by default and is not exposed as a public service.
- The Kasten chart is installed with provenance verification unless explicitly disabled.
- The official Kasten primer runs before installation unless explicitly skipped.
- MicroK10 does not modify netplan or host network interfaces.
- Destructive actions require confirmation or `--yes`.

The old repository history contains demo credentials. Treat every historical credential as compromised; do not reuse it anywhere.

## Development

```bash
make validate
```

CI performs Bash syntax checks, ShellCheck, shfmt verification, unit tests, a current-tree plaintext-secret check, a six-runner Ubuntu/architecture smoke matrix, and scheduled MicroK8s/Kasten integration across Kubernetes 1.31–1.34 on amd64 and arm64.

See [Compatibility](docs/COMPATIBILITY.md), [Architecture](docs/ARCHITECTURE.md), [Contributing](CONTRIBUTING.md), and [Security](SECURITY.md).
