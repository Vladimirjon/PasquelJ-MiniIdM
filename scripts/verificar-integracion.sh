#!/usr/bin/env bash
set -euo pipefail

LDAP_URI="${LDAP_URI:-ldap://127.0.0.1:389}"
BASE_DN="${BASE_DN:-dc=fis,dc=epn,dc=ec}"
REALM="${REALM:-FIS.EPN.EC}"

TMP_LDAP=$(mktemp)
TMP_KRB=$(mktemp)
trap 'rm -f "$TMP_LDAP" "$TMP_KRB"' EXIT

ldapsearch -x -LLL -H "$LDAP_URI" -b "$BASE_DN" '(objectClass=posixAccount)' uid   | awk '/^uid: / {print $2}' | sort -u > "$TMP_LDAP"

kadmin.local -q listprincs 2>/dev/null   | sed '/^Authenticating as principal /d'   | awk -F@ -v realm="$REALM" '$2 == realm && $1 !~ /\// && $1 != "K" {print $1}'   | sort -u > "$TMP_KRB"

echo "LDAP=$(wc -l < "$TMP_LDAP")"
echo "KERBEROS=$(wc -l < "$TMP_KRB")"

echo "SOLO_LDAP"
comm -23 "$TMP_LDAP" "$TMP_KRB" || true

echo "SOLO_KERBEROS"
comm -13 "$TMP_LDAP" "$TMP_KRB" || true

if cmp -s "$TMP_LDAP" "$TMP_KRB"; then
    echo "SINCRONIZACION=OK"
else
    echo "SINCRONIZACION=FAIL"
    exit 1
fi
