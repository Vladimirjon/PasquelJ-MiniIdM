#!/usr/bin/env bash
set -euo pipefail

URI="${LDAP_URI:-ldaps://ldap.fis.epn.ec:636}"
BASE_DN="${BASE_DN:-dc=fis,dc=epn,dc=ec}"
CA="${CA_FILE:-$HOME/miniidm-fis-root-ca.cert.pem}"
ROUNDS="${ROUNDS:-5}"
REQUESTS="${REQUESTS:-50}"
RESULTS_DIR="${RESULTS_DIR:-$HOME}"
OUT="$RESULTS_DIR/metrica_ldap_qps_final.txt"
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
mkdir -p "$RESULTS_DIR"
export LDAPTLS_CACERT="$CA"

{
    echo "=== LDAP QPS ==="
    echo "RONDAS=$ROUNDS"
    echo "CONSULTAS_POR_RONDA=$REQUESTS"
    echo

    for round in $(seq 1 "$ROUNDS"); do
        start=$(date +%s%N)
        ok=0
        fail=0
        for _ in $(seq 1 "$REQUESTS"); do
            if ldapsearch -x -LLL -H "$URI" -b "$BASE_DN" '(uid=emafla)' dn >/dev/null 2>&1; then
                ok=$((ok + 1))
            else
                fail=$((fail + 1))
            fi
        done
        end=$(date +%s%N)
        elapsed=$(awk -v a="$start" -v b="$end" 'BEGIN {printf "%.6f", (b-a)/1000000000}')
        qps=$(awk -v n="$ok" -v t="$elapsed" 'BEGIN {printf "%.2f", n/t}')
        echo "$qps" >> "$TMP"
        echo "RONDA=$round OK=$ok FAIL=$fail TIEMPO=${elapsed}s QPS=$qps"
    done

    python3 - "$TMP" <<'PY2'
import statistics, sys
values=[float(x) for x in open(sys.argv[1], encoding='utf-8') if x.strip()]
print(f"LDAP_QPS_PROMEDIO={statistics.mean(values):.2f}")
print(f"LDAP_QPS_MINIMO={min(values):.2f}")
print(f"LDAP_QPS_MAXIMO={max(values):.2f}")
print(f"LDAP_QPS_DESVIACION={statistics.pstdev(values):.2f}")
PY2
} | tee "$OUT"
