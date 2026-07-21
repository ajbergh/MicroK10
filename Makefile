SHELL := /usr/bin/env bash

.PHONY: test security lint format-check validate

test:
	bash tests/unit.sh
	bash tests/dry-run.sh

security:
	bash tests/no-plaintext-secrets.sh

lint:
	bash -n microk10 lib/*.sh tests/*.sh *.sh
	shellcheck microk10 lib/*.sh tests/*.sh *.sh

format-check:
	shfmt -d -i 2 microk10 lib/*.sh tests/*.sh *.sh

validate: lint format-check test security
