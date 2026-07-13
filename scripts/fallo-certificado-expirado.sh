#!/usr/bin/env bash
set -u
CA="${CA_FILE:-$HOME/miniidm-fis-root-ca.cert.pem}"
RESULTS_DIR="${RESULTS_DIR:-$HOME}"
mkdir -p "$RESULTS_DIR"

URL="https://web.fis.epn.ec/"

OUT="$RESULTS_DIR/fallo_certificado_expirado_vip.csv"

echo "numero,timestamp,http_code,curl_rc,node,error" > "$OUT"

echo "=== CERTIFICADO EXPIRADO MEDIANTE VIP ==="
echo "Se realizarán 20 solicitudes."
echo

for I in $(seq 1 20); do
    TIMESTAMP=$(date '+%F %T.%3N')
    HEADERS=$(mktemp)
    ERRORS=$(mktemp)

    CODE=$(
        curl -sS \
          --max-time 5 \
          -D "$HEADERS" \
          --cacert "$CA" \
          --negotiate -u : \
          -o /dev/null \
          -w '%{http_code}' \
          "$URL" 2>"$ERRORS"
    )

    RC=$?

    [ -n "$CODE" ] || CODE="000"

    NODE=$(
        awk -F': ' '
        tolower($1) == "x-miniidm-node" {
            gsub("\r", "", $2)
            print $2
            exit
        }
        ' "$HEADERS"
    )

    [ -n "$NODE" ] || NODE="NONE"

    ERROR=$(
        tr '\n' ' ' < "$ERRORS" |
        sed 's/,/;/g; s/[[:space:]]\+/ /g'
    )

    [ -n "$ERROR" ] || ERROR="NONE"

    echo "$I,$TIMESTAMP,$CODE,$RC,$NODE,$ERROR" >> "$OUT"

    printf \
      'PETICION=%02d NODE=%s HTTP=%s CURL_RC=%s ERROR=%s\n' \
      "$I" "$NODE" "$CODE" "$RC" "$ERROR"

    rm -f "$HEADERS" "$ERRORS"
    sleep 0.20
done

echo
echo "=== RESUMEN ==="

python3 - "$OUT" <<'PY'
import csv
import collections
import sys

path = sys.argv[1]

with open(path, encoding="utf-8") as file:
    rows = list(csv.DictReader(file))

success = [r for r in rows if r["http_code"] == "200"]
expired = [
    r for r in rows
    if r["curl_rc"] == "60"
    and "expired" in r["error"].lower()
]

nodes = collections.Counter(r["node"] for r in rows)

print(f"TOTAL={len(rows)}")
print(f"HTTP_200={len(success)}")
print(f"CERT_EXPIRED_FAIL={len(expired)}")
print(f"TASA_EXITO_PORCENTAJE={len(success) * 100 / len(rows):.2f}")

for node, count in sorted(nodes.items()):
    print(f"NODE_{node}={count}")

print(f"EVIDENCIA={path}")
PY
