#!/usr/bin/env bash
set -euo pipefail
CA="${CA_FILE:-$HOME/miniidm-fis-root-ca.cert.pem}"
RESULTS_DIR="${RESULTS_DIR:-$HOME}"
mkdir -p "$RESULTS_DIR"

DN="uid=replica-test,ou=sem1,ou=sic,dc=fis,dc=epn,dc=ec"
ADMIN_DN="cn=admin,dc=fis,dc=epn,dc=ec"

PROVIDER="ldaps://ldap1.fis.epn.ec:636"
CONSUMER="ldaps://ldap2.fis.epn.ec:636"


OUT="$RESULTS_DIR/fallo_particion_ldap.txt"

export LDAPTLS_CACERT="$CA"

read -s -p "Contraseña LDAP de $ADMIN_DN: " LDAP_PASS
echo

PASSFILE=$(mktemp)
chmod 600 "$PASSFILE"
printf '%s' "$LDAP_PASS" > "$PASSFILE"
unset LDAP_PASS

cleanup() {
    rm -f "$PASSFILE"
}

trap cleanup EXIT

exec > >(tee "$OUT") 2>&1

TAG="partition-final-$(date +%s%N)"

START_NS=$(date +%s%N)
START_EPOCH_MS=$(date +%s%3N)

echo
echo "=== PRUEBA DE PARTICION LDAP ==="
echo "TAG=$TAG"
echo "WRITE_START_EPOCH_MS=$START_EPOCH_MS"

ldapmodify \
  -x \
  -H "$PROVIDER" \
  -D "$ADMIN_DN" \
  -y "$PASSFILE" \
  -o nettimeout=5 <<EOF
dn: $DN
changetype: modify
replace: description
description: $TAG
EOF

ACK_NS=$(date +%s%N)
ACK_EPOCH_MS=$(date +%s%3N)

echo "MASTER_WRITE=OK"
echo "MASTER_ACK_EPOCH_MS=$ACK_EPOCH_MS"

echo
echo "Verificando que el cambio NO llegue durante la particion..."

for ATTEMPT in $(seq 1 12); do
    RESULT=$(
        ldapsearch \
          -x \
          -LLL \
          -H "$CONSUMER" \
          -b "$DN" \
          -s base \
          -o nettimeout=2 \
          description 2>/dev/null || true
    )

    CHECK_EPOCH_MS=$(date +%s%3N)

    if printf '%s\n' "$RESULT" |
        grep -Fq "description: $TAG"
    then
        echo "PARTICION=FAIL"
        echo "El cambio apareció en idm2 mientras las reglas seguían activas."
        exit 2
    fi

    echo \
      "PARTICION_CHECK=$ATTEMPT" \
      "EPOCH_MS=$CHECK_EPOCH_MS" \
      "VISIBLE=0"

    sleep 0.25
done

echo
echo "PARTICION_CONFIRMADA=1"
echo "El cambio todavía NO está visible en idm2."
echo "AHORA_RETIRAR_REGLAS_IPTABLES_EN_IDM2=1"
echo
echo "Esperando recuperación de la replicación..."

for ATTEMPT in $(seq 1 600); do
    RESULT=$(
        ldapsearch \
          -x \
          -LLL \
          -H "$CONSUMER" \
          -b "$DN" \
          -s base \
          -o nettimeout=2 \
          description 2>/dev/null || true
    )

    if printf '%s\n' "$RESULT" |
        grep -Fq "description: $TAG"
    then
        END_NS=$(date +%s%N)
        END_EPOCH_MS=$(date +%s%3N)

        WRITE_ACK_MS=$(
            awk -v start="$START_NS" -v end="$ACK_NS" \
              'BEGIN {printf "%.2f", (end-start)/1000000}'
        )

        TOTAL_DELAY_MS=$(
            awk -v start="$ACK_NS" -v end="$END_NS" \
              'BEGIN {printf "%.2f", (end-start)/1000000}'
        )

        echo
        echo "REPLICA_VISIBLE=1"
        echo "REPLICA_VISIBLE_EPOCH_MS=$END_EPOCH_MS"
        echo "INTENTOS_RECUPERACION=$ATTEMPT"
        echo "MASTER_WRITE_ACK_MS=$WRITE_ACK_MS"
        echo "DELAY_DESDE_ACK_HASTA_REPLICA_MS=$TOTAL_DELAY_MS"
        echo "EVIDENCIA=$OUT"

        exit 0
    fi

    sleep 0.10
done

echo "REPLICA_VISIBLE=0"
echo "TIMEOUT_RECUPERACION=1"
exit 3
