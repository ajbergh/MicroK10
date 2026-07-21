# Contributing

1. Create a focused branch from `main`.
2. Keep shell code compatible with Bash 5.x on supported Ubuntu releases.
3. Run `make validate` before opening a pull request.
4. Add or update tests for compatibility and parsing changes.
5. Update `docs/COMPATIBILITY.md` and `CHANGELOG.md` when changing pinned releases.
6. Never commit passwords, tokens, kubeconfigs, private keys, or customer environment data.

Pull requests should explain the tested Ubuntu release, architecture, MicroK8s channel, Kasten version, and storage class.
