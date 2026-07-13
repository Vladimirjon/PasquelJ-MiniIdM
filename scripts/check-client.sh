#!/usr/bin/env bash
set -u
CA="${CA_FILE:-$HOME/miniidm-fis-root-ca.cert.pem}"

echo "=== CLIENT CHECK ==="
date '+%F %T'
hostname -f

echo "=== DNS/local resolution ==="
getent hosts web.fis.epn.ec || true
getent hosts ldap.fis.epn.ec || true
getent hosts kdc1.fis.epn.ec || true
getent hosts kdc2.fis.epn.ec || true

echo "=== KDC connectivity ==="
timeout 3 bash -c '</dev/tcp/kdc1.fis.epn.ec/88' && echo "kdc1 TCP 88 OK" || echo "kdc1 TCP 88 FAIL"
timeout 3 bash -c '</dev/tcp/kdc2.fis.epn.ec/88' && echo "kdc2 TCP 88 OK" || echo "kdc2 TCP 88 FAIL"

echo "=== Web TLS certificate ==="
openssl s_client -connect web.fis.epn.ec:443 -servername web.fis.epn.ec \
  -CAfile $CA \
  -verify_hostname web.fis.epn.ec </dev/null 2>/dev/null \
  | grep -E 'subject=|issuer=|Verify return code' || true

echo "=== LDAPS certificate ==="
openssl s_client -connect ldap.fis.epn.ec:636 -servername ldap.fis.epn.ec \
  -CAfile $CA \
  -verify_hostname ldap.fis.epn.ec </dev/null 2>/dev/null \
  | grep -E 'subject=|issuer=|Verify return code' || true

echo "=== LDAP query ==="
LDAPTLS_CACERT=$CA ldapsearch -x -LLL \
  -H ldaps://ldap.fis.epn.ec:636 \
  -b dc=fis,dc=epn,dc=ec \
  "(uid=emafla)" dn uid cn mail || true
