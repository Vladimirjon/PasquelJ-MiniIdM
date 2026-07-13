#!/usr/bin/env bash
set -u
CA="${CA_FILE:-$HOME/miniidm-fis-root-ca.cert.pem}"
RESULTS_DIR="${RESULTS_DIR:-$HOME}"
mkdir -p "$RESULTS_DIR"

URL="https://web.fis.epn.ec/"

OUT="$RESULTS_DIR/fallo_stop_apache_idm1.csv"

echo "epoch_ms,timestamp,node,http_code" > "$OUT"

echo "=== MONITOREO DE FALLO PERSISTENTE APACHE IDM1 ==="
echo "Se realizarán 80 peticiones."
echo "Cuando comiencen a aparecer resultados, ejecuta el kill -9 en idm1."
echo

for I in $(seq 1 80); do
    EPOCH_MS=$(date +%s%3N)
    TIMESTAMP=$(date '+%F %T.%3N')
    HEADERS=$(mktemp)

    CODE=$(
        curl -sS \
          --max-time 3 \
          -D "$HEADERS" \
          --negotiate -u : \
          --cacert "$CA" \
          -o /dev/null \
          -w '%{http_code}' \
          "$URL" 2>/dev/null
    )

    CURL_RC=$?

    if [ "$CURL_RC" -ne 0 ] || [ -z "$CODE" ]; then
        CODE="000"
    fi

    NODE=$(
        awk -F': ' '
        tolower($1) == "x-miniidm-node" {
            gsub("\r", "", $2)
            print $2
            exit
        }
        ' "$HEADERS"
    )

    rm -f "$HEADERS"

    if [ -z "$NODE" ]; then
        NODE="NONE"
    fi

    echo "$EPOCH_MS,$TIMESTAMP,$NODE,$CODE" >> "$OUT"

    printf \
      'PETICION=%02d HORA=%s NODE=%s HTTP=%s\n' \
      "$I" "$TIMESTAMP" "$NODE" "$CODE"

    sleep 0.25
done

echo
echo "=== RESUMEN ==="

python3 - "$OUT" <<'PY'
import collections
import csv
import sys

path = sys.argv[1]

with open(path, encoding="utf-8") as file:
    rows = list(csv.DictReader(file))

codes = collections.Counter(row["http_code"] for row in rows)
nodes = collections.Counter(row["node"] for row in rows)

print(f"TOTAL={len(rows)}")
print(f"HTTP_200={codes.get('200', 0)}")
print(f"HTTP_FAIL={len(rows) - codes.get('200', 0)}")

for node, count in sorted(nodes.items()):
    print(f"NODE_{node}={count}")

previous = None

for row in rows:
    node = row["node"]

    if node != previous:
        print(
            "TRANSICION "
            f"HORA={row['timestamp']} "
            f"NODE={node} "
            f"HTTP={row['http_code']}"
        )
        previous = node

print(f"EVIDENCIA={path}")
PY
