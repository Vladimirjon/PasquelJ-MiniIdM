#!/usr/bin/env bash
set -u
CA="${CA_FILE:-$HOME/miniidm-fis-root-ca.cert.pem}"

echo "=== LDAPS TEST ==="
date '+%F %T'
hostname -f

LDAPTLS_CACERT=$CA ldapsearch -x -LLL \
  -H ldaps://ldap.fis.epn.ec:636 \
  -b dc=fis,dc=epn,dc=ec \
  "(uid=emafla)" dn uid cn mail
