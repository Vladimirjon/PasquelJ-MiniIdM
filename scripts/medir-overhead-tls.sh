#!/usr/bin/env bash
set -euo pipefail
CA="${CA_FILE:-$HOME/miniidm-fis-root-ca.cert.pem}"
RESULTS_DIR="${RESULTS_DIR:-$HOME}"
mkdir -p "$RESULTS_DIR"

URL="https://web.fis.epn.ec/"

OUT="$RESULTS_DIR/metrica_overhead_tls.csv"
ROUNDS=50

klist -s || {
    echo "ERROR: no existe un TGT Kerberos válido."
    echo "Ejecuta: kinit emafla@FIS.EPN.EC"
    exit 1
}

echo \
"ronda,node,http_code,tcp_connect_ms,tls_handshake_ms,after_tls_ms,total_ms" \
> "$OUT"

echo "=== OVERHEAD TLS ==="
echo "SOLICITUDES=$ROUNDS"
echo "URL=$URL"
echo

# Solicitud previa para disponer del ticket de servicio.
curl -sS \
  --http1.1 \
  --cacert "$CA" \
  --negotiate -u : \
  -o /dev/null \
  "$URL"

for ROUND in $(seq 1 "$ROUNDS"); do
    HEADERS=$(mktemp)

    VALUES=$(
        curl -sS \
          --http1.1 \
          --max-time 5 \
          -D "$HEADERS" \
          --cacert "$CA" \
          --negotiate -u : \
          -o /dev/null \
          -w '%{http_code} %{time_connect} %{time_appconnect} %{time_starttransfer} %{time_total}' \
          "$URL"
    )

    read -r \
      HTTP_CODE \
      TIME_CONNECT \
      TIME_APPCONNECT \
      TIME_STARTTRANSFER \
      TIME_TOTAL <<< "$VALUES"

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

    [ -n "$NODE" ] || NODE="NONE"

    TCP_MS=$(
        awk -v value="$TIME_CONNECT" \
          'BEGIN {printf "%.3f", value * 1000}'
    )

    TLS_MS=$(
        awk \
          -v connect="$TIME_CONNECT" \
          -v appconnect="$TIME_APPCONNECT" \
          'BEGIN {printf "%.3f", (appconnect-connect) * 1000}'
    )

    AFTER_TLS_MS=$(
        awk \
          -v appconnect="$TIME_APPCONNECT" \
          -v starttransfer="$TIME_STARTTRANSFER" \
          'BEGIN {printf "%.3f", (starttransfer-appconnect) * 1000}'
    )

    TOTAL_MS=$(
        awk -v value="$TIME_TOTAL" \
          'BEGIN {printf "%.3f", value * 1000}'
    )

    echo \
      "$ROUND,$NODE,$HTTP_CODE,$TCP_MS,$TLS_MS,$AFTER_TLS_MS,$TOTAL_MS" \
      >> "$OUT"

    printf \
      'RONDA=%02d NODE=%s HTTP=%s TCP=%sms TLS=%sms TOTAL=%sms\n' \
      "$ROUND" \
      "$NODE" \
      "$HTTP_CODE" \
      "$TCP_MS" \
      "$TLS_MS" \
      "$TOTAL_MS"
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

success = [row for row in rows if row["http_code"] == "200"]

tcp = [float(row["tcp_connect_ms"]) for row in success]
tls = [float(row["tls_handshake_ms"]) for row in success]
after_tls = [float(row["after_tls_ms"]) for row in success]
total = [float(row["total_ms"]) for row in success]

print(f"TOTAL={len(rows)}")
print(f"HTTP_200={len(success)}")
print(f"HTTP_FAIL={len(rows) - len(success)}")

if success:
    print(f"TCP_PROMEDIO_MS={statistics.mean(tcp):.3f}")
    print(f"TLS_OVERHEAD_PROMEDIO_MS={statistics.mean(tls):.3f}")
    print(f"TLS_OVERHEAD_MINIMO_MS={min(tls):.3f}")
    print(f"TLS_OVERHEAD_MAXIMO_MS={max(tls):.3f}")
    print(
        "TLS_OVERHEAD_DESVIACION_MS="
        f"{statistics.pstdev(tls):.3f}"
    )
    print(
        "PROCESAMIENTO_POST_TLS_PROMEDIO_MS="
        f"{statistics.mean(after_tls):.3f}"
    )
    print(
        "LATENCIA_TOTAL_PROMEDIO_MS="
        f"{statistics.mean(total):.3f}"
    )

print(f"EVIDENCIA={path}")
PY
