.PHONY: help  tree check-client check-idm1 check-idm2 test-web test-ldap test-prometheus

help:
	@echo "MiniIdM - Makefile"
	@echo "  make tree             Muestra estructura del repositorio"
	@echo "  make check-client     Validaciones desde client-miniidm"
	@echo "  make check-idm1       Validaciones locales en idm1"
	@echo "  make check-idm2       Validaciones locales en idm2"
	@echo "  make test-web         Prueba Web TLS + Kerberos desde client"
	@echo "  make test-ldap        Prueba LDAPS por VIP desde client"
	@echo "  make test-prometheus  Verifica targets Prometheus desde client"


tree:
	@find . -maxdepth 3 -type f | sort

check-client:
	bash scripts/check-client.sh

check-idm1:
	bash scripts/check-idm1.sh

check-idm2:
	bash scripts/check-idm2.sh

test-web:
	bash scripts/test-web.sh

test-ldap:
	bash scripts/test-ldap.sh

test-prometheus:
	bash scripts/test-prometheus.sh
