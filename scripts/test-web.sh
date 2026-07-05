#!/usr/bin/env bash
set -u

echo "=== WEB TLS + KERBEROS TEST ==="
date '+%F %T'
hostname -f

echo "Este script requiere un TGT valido. Ejecutar antes: kinit emafla"
klist || exit 1

curl -sS -D - \
  --negotiate -u : \
  --cacert /home/johann_client/miniidm-fis-root-ca.cert.pem \
  -w "\nHTTP_CODE=%{http_code}\n" \
  https://web.fis.epn.ec/ \
  | grep -E 'X-MiniIdM-Node|Nodo activo|MiniIdM FIS|HTTP_CODE|curl:'
