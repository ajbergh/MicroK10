# Security policy

## Supported versions

Security fixes are applied to the current default branch and the latest tagged release.

## Reporting a vulnerability

Open a private GitHub security advisory for this repository. Do not place credentials, exploit details, customer data, or sensitive environment output in a public issue.

For vulnerabilities in Veeam Kasten, MicroK8s, Kubernetes, Helm, or a container image, use the upstream vendor's disclosure process as well.

## Historical credential warning

The original 2021 scripts committed static MinIO and application credentials. Those values remain visible in Git history even though the current branch removes them. Treat them as permanently compromised and never reuse them. Purging public Git history is disruptive and is intentionally not performed by this modernization change.

## Operational guidance

- Use a dedicated clean VM for evaluation.
- Keep the dashboard bound to loopback unless a supported authentication and TLS design is configured.
- Do not use `--skip-chart-verification`, `--skip-primer`, or `--allow-unsupported` in production.
- Use a production CSI storage system and validate snapshot/export capabilities.
- Review Kasten and MicroK8s release notes before upgrades.
