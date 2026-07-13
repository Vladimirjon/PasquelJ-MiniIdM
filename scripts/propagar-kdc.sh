#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-idm2.fis.epn.ec}"
DUMP="${DUMP_FILE:-/var/lib/krb5kdc/slave_datatrans}"

if [ "$(id -u)" -ne 0 ]; then
    echo "Ejecutar como root."
    exit 1
fi

kdb5_util dump "$DUMP"
kprop -f "$DUMP" "$TARGET"
echo "PROPAGACION=OK TARGET=$TARGET"
