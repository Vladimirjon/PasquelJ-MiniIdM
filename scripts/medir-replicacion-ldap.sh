#!/usr/bin/env bash
set -euo pipefail
CA="${CA_FILE:-$HOME/miniidm-fis-root-ca.cert.pem}"
RESULTS_DIR="${RESULTS_DIR:-$HOME}"
mkdir -p "$RESULTS_DIR"

DN="uid=replica-test,ou=sem1,ou=sic,dc=fis,dc=epn,dc=ec"
ADMIN_DN="cn=admin,dc=fis,dc=epn,dc=ec"

PROVIDER="ldaps://ldap1.fis.epn.ec:636"
CONSUMER="ldaps://ldap2.fis.epn.ec:636"


ROUNDS=5
RESULTS="/tmp/repdelay_results.txt"

: > "$RESULTS"

export LDAPTLS_CACERT="$CA"

read -s -p "Contraseña LDAP de $ADMIN_DN: " LDAP_PASS
echo

PASSFILE=$(mktemp)
chmod 600 "$PASSFILE"
printf '%s' "$LDAP_PASS" > "$PASSFILE"
unset LDAP_PASS

cleanup() {
    rm -f "$PASSFILE" "$RESULTS"
}

trap cleanup EXIT

OUT="$RESULTS_DIR/metrica_ldap_replication_delay_5rondas.txt"

exec > >(tee "$OUT") 2>&1

echo
echo "=== RETRASO LDAP: MEDICION FINAL ==="
echo "RONDAS=$ROUNDS"
echo "DN=$DN"
echo "PROVIDER=$PROVIDER"
echo "CONSUMER=$CONSUMER"
echo

for ROUND in $(seq 1 "$ROUNDS"); do
    TAG="repdelay-final-$(date +%s%N)"

    START_NS=$(date +%s%N)

    set +e
    MODIFY_OUTPUT=$(
        ldapmodify \
          -x \
          -H "$PROVIDER" \
          -D "$ADMIN_DN" \
          -y "$PASSFILE" \
          -o nettimeout=5 2>&1 <<EOF
dn: $DN
changetype: modify
replace: description
description: $TAG
EOF
    )
    MODIFY_RC=$?
    set -e

    ACK_NS=$(date +%s%N)

    if [ "$MODIFY_RC" -ne 0 ]; then
        echo "RONDA=$ROUND MODIFICACION=FAIL"
        echo "$MODIFY_OUTPUT"
        exit 1
    fi

    FOUND=0
    ATTEMPTS=0

    for ATTEMPT in $(seq 1 200); do
        ATTEMPTS=$ATTEMPT

        SEARCH_OUTPUT=$(
            ldapsearch \
              -x \
              -LLL \
              -H "$CONSUMER" \
              -b "$DN" \
              -s base \
              -o nettimeout=2 \
              description 2>/dev/null || true
        )

        if printf '%s\n' "$SEARCH_OUTPUT" |
            grep -Fq "description: $TAG"
        then
            FOUND=1
            break
        fi

        sleep 0.01
    done

    END_NS=$(date +%s%N)

    if [ "$FOUND" -ne 1 ]; then
        echo "RONDA=$ROUND FOUND=0 TIMEOUT"
        exit 2
    fi

    WRITE_ACK_MS=$(
        awk -v start="$START_NS" -v end="$ACK_NS" \
          'BEGIN {printf "%.2f", (end-start)/1000000}'
    )

    AFTER_ACK_MS=$(
        awk -v start="$ACK_NS" -v end="$END_NS" \
          'BEGIN {printf "%.2f", (end-start)/1000000}'
    )

    TOTAL_MS=$(
        awk -v start="$START_NS" -v end="$END_NS" \
          'BEGIN {printf "%.2f", (end-start)/1000000}'
    )

    printf '%s %s %s\n' \
      "$WRITE_ACK_MS" \
      "$AFTER_ACK_MS" \
      "$TOTAL_MS" >> "$RESULTS"

    echo \
      "RONDA=$ROUND" \
      "FOUND=1" \
      "INTENTOS=$ATTEMPTS" \
      "WRITE_ACK_MS=$WRITE_ACK_MS" \
      "AFTER_ACK_MS=$AFTER_ACK_MS" \
      "TOTAL_MS=$TOTAL_MS"

    sleep 0.20
done

echo

python3 - "$RESULTS" <<'PY'
import statistics
import sys

path = sys.argv[1]

write_ack = []
after_ack = []
total = []

with open(path, encoding="utf-8") as file:
    for line in file:
        values = line.split()

        if len(values) != 3:
            continue

        write_value, after_value, total_value = map(float, values)

        write_ack.append(write_value)
        after_ack.append(after_value)
        total.append(total_value)

print(
    "LDAP_REPLICATION_DELAY_PROMEDIO_MS="
    f"{statistics.mean(total):.2f}"
)
print(
    "LDAP_REPLICATION_DELAY_MINIMO_MS="
    f"{min(total):.2f}"
)
print(
    "LDAP_REPLICATION_DELAY_MAXIMO_MS="
    f"{max(total):.2f}"
)
print(
    "LDAP_REPLICATION_DELAY_DESVIACION_MS="
    f"{statistics.pstdev(total):.2f}"
)
print(
    "REPLICA_AFTER_ACK_PROMEDIO_MS="
    f"{statistics.mean(after_ack):.2f}"
)
print(
    "MASTER_WRITE_ACK_PROMEDIO_MS="
    f"{statistics.mean(write_ack):.2f}"
)
PY

echo
echo "EVIDENCIA_GUARDADA=$OUT"
