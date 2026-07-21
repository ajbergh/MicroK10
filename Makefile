SHELL := /usr/bin/env bash

APPLIANCE_SHELL := appliance/microk10-tui appliance/lib/*.sh appliance/packer/scripts/*.sh
APPLIANCE_FORMAT := appliance/lib/*.sh appliance/packer/scripts/*.sh

.PHONY: test security lint format-check packer-check appliance-validate validate

test:
	bash tests/unit.sh
	bash tests/dry-run.sh

security:
	bash tests/no-plaintext-secrets.sh

lint:
	bash -n microk10 lib/*.sh tests/*.sh *.sh $(APPLIANCE_SHELL)
	shellcheck microk10 lib/*.sh tests/*.sh *.sh $(APPLIANCE_SHELL)

format-check:
	shfmt -d -i 2 microk10 lib/*.sh tests/*.sh *.sh $(APPLIANCE_FORMAT)

packer-check:
	@if command -v packer >/dev/null 2>&1; then \
		packer fmt -check appliance/packer/rocky-microk10.pkr.hcl appliance/packer/*.pkrvars.hcl; \
		packer init appliance/packer/rocky-microk10.pkr.hcl; \
		packer validate -syntax-only appliance/packer/rocky-microk10.pkr.hcl; \
	else \
		echo "packer not installed; skipping HCL validation"; \
	fi

appliance-validate: lint format-check packer-check test security

validate: appliance-validate
