#!/usr/bin/env bash
set -u
CA="${CA_FILE:-$HOME/miniidm-fis-root-ca.cert.pem}"
RESULTS_DIR="${RESULTS_DIR:-$HOME}"
mkdir -p "$RESULTS_DIR"

URL="ldaps://ldap.fis.epn.ec:636"
BASE="dc=fis,dc=epn,dc=ec"

OUT="$RESULTS_DIR/fallo_stop_ldap_idm1.csv"

export LDAPTLS_CACERT="$CA"

echo "epoch_ms,timestamp,status,duration_ms" > "$OUT"

echo "=== MONITOREO DE FALLO PERSISTENTE LDAP IDM1 ==="
echo "Se realizarán 80 consultas."
echo "Cuando comiencen los resultados, detén slapd en idm1."
echo

for I in $(seq 1 80); do
    EPOCH_MS=$(date +%s%3N)
    TIMESTAMP=$(date '+%F %T.%3N')
    START_NS=$(date +%s%N)

    RESULT=$(
        ldapsearch \
          -x \
          -LLL \
          -H "$URL" \
          -b "$BASE" \
          -o nettimeout=3 \
          '(uid=emafla)' \
          dn 2>/dev/null
    )

    RC=$?
    END_NS=$(date +%s%N)

    DURATION_MS=$(
        awk -v start="$START_NS" -v end="$END_NS" \
          'BEGIN {printf "%.2f", (end-start)/1000000}'
    )

    if [ "$RC" -eq 0 ] &&
       printf '%s\n' "$RESULT" |
       grep -Fq 'uid=emafla'
    then
        STATUS="OK"
    else
        STATUS="FAIL"
    fi

    echo \
      "$EPOCH_MS,$TIMESTAMP,$STATUS,$DURATION_MS" \
      >> "$OUT"

    printf \
      'CONSULTA=%02d HORA=%s STATUS=%s DURACION=%sms\n' \
      "$I" "$TIMESTAMP" "$STATUS" "$DURATION_MS"

    sleep 0.25
done

echo
echo "=== RESUMEN ==="

python3 - "$OUT" <<'PY'
import csv
import statistics
import sys

path = sys.argv[1]

with open(path, encoding="utf-8") as file:
    rows = list(csv.DictReader(file))

ok_rows = [r for r in rows if r["status"] == "OK"]
fail_rows = [r for r in rows if r["status"] == "FAIL"]
durations = [float(r["duration_ms"]) for r in rows]

print(f"TOTAL={len(rows)}")
print(f"LDAP_OK={len(ok_rows)}")
print(f"LDAP_FAIL={len(fail_rows)}")
print(
    f"TASA_EXITO_PORCENTAJE="
    f"{len(ok_rows) * 100 / len(rows):.2f}"
)

if durations:
    print(
        f"LATENCIA_PROMEDIO_MS="
        f"{statistics.mean(durations):.2f}"
    )
    print(
        f"LATENCIA_MAXIMA_MS="
        f"{max(durations):.2f}"
    )

for row in fail_rows:
    print(
        "FALLO "
        f"HORA={row['timestamp']} "
        f"DURACION_MS={row['duration_ms']}"
    )

print(f"EVIDENCIA={path}")
PY
