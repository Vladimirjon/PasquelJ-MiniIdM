#!/usr/bin/env bash
set -u
CA="${CA_FILE:-$HOME/miniidm-fis-root-ca.cert.pem}"

echo "=== WEB TLS + KERBEROS TEST ==="
date '+%F %T'
hostname -f

echo "Este script requiere un TGT valido. Ejecutar antes: kinit emafla"
klist || exit 1

curl -sS -D - \
  --negotiate -u : \
  --cacert $CA \
  -w "\nHTTP_CODE=%{http_code}\n" \
  https://web.fis.epn.ec/ \
  | grep -E 'X-MiniIdM-Node|Nodo activo|MiniIdM FIS|HTTP_CODE|curl:'
