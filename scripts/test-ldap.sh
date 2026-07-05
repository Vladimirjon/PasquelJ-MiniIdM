#!/usr/bin/env bash
set -u

echo "=== LDAPS TEST ==="
date '+%F %T'
hostname -f

LDAPTLS_CACERT=/home/johann_client/miniidm-fis-root-ca.cert.pem ldapsearch -x -LLL \
  -H ldaps://ldap.fis.epn.ec:636 \
  -b dc=fis,dc=epn,dc=ec \
  "(uid=emafla)" dn uid cn mail
