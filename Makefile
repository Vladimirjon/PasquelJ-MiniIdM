SHELL := /usr/bin/env bash

.PHONY: help tree syntax check-client check-idm1 check-idm2 test-web test-ldap test-prometheus test-integracion

help:
	@echo "make tree"
	@echo "make syntax"
	@echo "make check-client"
	@echo "make check-idm1"
	@echo "make check-idm2"
	@echo "make test-web"
	@echo "make test-ldap"
	@echo "make test-prometheus"
	@echo "make test-integracion"

tree:
	@find . -path './.git' -prune -o -type f -print | sort

syntax:
	@find scripts -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
	@python3 -c 'from pathlib import Path; [compile(p.read_text(encoding="utf-8"), str(p), "exec") for p in Path("scripts").glob("*.py")]'

check-client:
	@bash scripts/check-client.sh

check-idm1:
	@bash scripts/check-idm1.sh

check-idm2:
	@bash scripts/check-idm2.sh

test-web:
	@bash scripts/test-web.sh

test-ldap:
	@bash scripts/test-ldap.sh

test-prometheus:
	@bash scripts/test-prometheus.sh

test-integracion:
	@bash scripts/verificar-integracion.sh
