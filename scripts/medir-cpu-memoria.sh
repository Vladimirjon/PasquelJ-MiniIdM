#!/usr/bin/env bash
set -euo pipefail

PROM="${PROMETHEUS_URL:-http://127.0.0.1:9090}"
RESULTS_DIR="${RESULTS_DIR:-$HOME}"
OUT="$RESULTS_DIR/metricas_cpu_memoria.txt"
mkdir -p "$RESULTS_DIR"

python3 - "$PROM" "$OUT" <<'PY'
import json
import subprocess
import sys
import urllib.parse

prom, out = sys.argv[1:]
queries = {
    "CPU_USO_PORCENTAJE": (
        '100 - avg by(instance,node) '
        '(rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100'
    ),
    "MEMORIA_USO_PORCENTAJE": (
        '(1 - node_memory_MemAvailable_bytes / '
        'node_memory_MemTotal_bytes) * 100'
    ),
}
lines = []

for title, query in queries.items():
    url = prom + "/api/v1/query?" + urllib.parse.urlencode({"query": query})
    data = json.loads(
        subprocess.check_output(["curl", "-fsS", url], text=True)
    )
    lines.append(f"=== {title} ===")
    for item in sorted(
        data["data"]["result"],
        key=lambda value: value["metric"].get("node", ""),
    ):
        metric = item["metric"]
        value = float(item["value"][1])
        lines.append(
            f"node={metric.get('node', '-')} "
            f"instance={metric.get('instance', '-')} "
            f"value={value:.2f}%"
        )
    lines.append("")

text = "\n".join(lines)
print(text)
with open(out, "w", encoding="utf-8") as file:
    file.write(text + "\n")
PY
