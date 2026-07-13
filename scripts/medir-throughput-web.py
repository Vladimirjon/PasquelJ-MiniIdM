#!/usr/bin/env python3

import concurrent.futures
import csv
import os
import re
import statistics
import subprocess
import sys
import time
from collections import Counter
from pathlib import Path

URL = "https://web.fis.epn.ec/"
CA = os.environ.get("CA_FILE", str(Path.home() / "miniidm-fis-root-ca.cert.pem"))

ROUNDS = 5
REQUESTS_PER_ROUND = 100
CONCURRENCY = 20

MODE = sys.argv[1] if len(sys.argv) > 1 else "SIN_ETIQUETA"
SAFE_MODE = re.sub(r"[^A-Za-z0-9_-]", "_", MODE)

RESULTS_DIR = Path(os.environ.get("RESULTS_DIR", str(Path.home())))
RESULTS_DIR.mkdir(parents=True, exist_ok=True)
OUT = str(RESULTS_DIR / f"metrica_throughput_{SAFE_MODE}.csv")

if subprocess.run(
    ["klist", "-s"],
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
).returncode != 0:
    print("ERROR: no existe un TGT Kerberos válido.")
    print("Ejecuta: kinit emafla@FIS.EPN.EC")
    sys.exit(1)

environment = os.environ.copy()


def request_web(request_number: int) -> dict:
    command = [
        "curl",
        "-sS",
        "--http1.1",
        "--max-time",
        "10",
        "--cacert",
        CA,
        "--negotiate",
        "-u",
        ":",
        "-D",
        "-",
        "-o",
        "/dev/null",
        "-w",
        "\n__METRICS__:%{http_code}\n",
        URL,
    ]

    start = time.perf_counter()

    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
        env=environment,
        check=False,
    )

    elapsed_ms = (
        time.perf_counter() - start
    ) * 1000

    output = result.stdout

    codes = re.findall(
        r"__METRICS__:(\d{3})",
        output,
    )

    nodes = re.findall(
        r"(?im)^X-MiniIdM-Node:\s*([^\r\n]+)",
        output,
    )

    http_code = codes[-1] if codes else "000"
    node = nodes[-1].strip() if nodes else "NONE"

    status = (
        "OK"
        if result.returncode == 0 and http_code == "200"
        else "FAIL"
    )

    error = result.stderr.strip().replace(",", ";")

    return {
        "request": request_number,
        "status": status,
        "node": node,
        "http_code": http_code,
        "curl_rc": result.returncode,
        "duration_ms": round(elapsed_ms, 3),
        "error": error,
    }


print("=== THROUGHPUT WEB TLS + KERBEROS ===")
print(f"MODO={MODE}")
print(f"RONDAS={ROUNDS}")
print(f"SOLICITUDES_POR_RONDA={REQUESTS_PER_ROUND}")
print(f"CONCURRENCIA={CONCURRENCY}")
print()

# Solicitud de calentamiento para disponer del ticket de servicio.
warmup = request_web(0)

if warmup["status"] != "OK":
    print("ERROR: la solicitud de calentamiento falló.")
    print(warmup)
    sys.exit(2)

all_rows = []
round_throughputs = []

for round_number in range(1, ROUNDS + 1):
    start_round = time.perf_counter()

    with concurrent.futures.ThreadPoolExecutor(
        max_workers=CONCURRENCY
    ) as executor:
        futures = [
            executor.submit(request_web, request_number)
            for request_number in range(
                1,
                REQUESTS_PER_ROUND + 1,
            )
        ]

        rows = [
            future.result()
            for future in concurrent.futures.as_completed(
                futures
            )
        ]

    elapsed_seconds = time.perf_counter() - start_round

    ok_rows = [
        row
        for row in rows
        if row["status"] == "OK"
    ]

    throughput = len(ok_rows) / elapsed_seconds
    round_throughputs.append(throughput)

    nodes = Counter(
        row["node"]
        for row in ok_rows
    )

    for row in rows:
        row["round"] = round_number
        all_rows.append(row)

    nodes_text = " ".join(
        f"{node}={count}"
        for node, count in sorted(nodes.items())
    )

    print(
        f"RONDA={round_number} "
        f"OK={len(ok_rows)} "
        f"FAIL={len(rows) - len(ok_rows)} "
        f"TIEMPO={elapsed_seconds:.3f}s "
        f"THROUGHPUT={throughput:.2f}_req_s "
        f"{nodes_text}"
    )

with open(
    OUT,
    "w",
    newline="",
    encoding="utf-8",
) as file:
    fieldnames = [
        "round",
        "request",
        "status",
        "node",
        "http_code",
        "curl_rc",
        "duration_ms",
        "error",
    ]

    writer = csv.DictWriter(
        file,
        fieldnames=fieldnames,
    )

    writer.writeheader()
    writer.writerows(all_rows)

success_rows = [
    row
    for row in all_rows
    if row["status"] == "OK"
]

fail_rows = [
    row
    for row in all_rows
    if row["status"] == "FAIL"
]

durations = [
    float(row["duration_ms"])
    for row in success_rows
]

nodes = Counter(
    row["node"]
    for row in success_rows
)

print()
print("=== RESUMEN ===")
print(f"MODO={MODE}")
print(f"TOTAL={len(all_rows)}")
print(f"HTTP_200={len(success_rows)}")
print(f"HTTP_FAIL={len(fail_rows)}")
print(
    "TASA_EXITO_PORCENTAJE="
    f"{len(success_rows) * 100 / len(all_rows):.2f}"
)
print(
    "THROUGHPUT_PROMEDIO_REQ_S="
    f"{statistics.mean(round_throughputs):.2f}"
)
print(
    "THROUGHPUT_MINIMO_REQ_S="
    f"{min(round_throughputs):.2f}"
)
print(
    "THROUGHPUT_MAXIMO_REQ_S="
    f"{max(round_throughputs):.2f}"
)
print(
    "LATENCIA_PROMEDIO_MS="
    f"{statistics.mean(durations):.2f}"
)
print(
    "LATENCIA_MAXIMA_MS="
    f"{max(durations):.2f}"
)

for node, count in sorted(nodes.items()):
    print(f"NODE_{node}={count}")

print(f"EVIDENCIA={OUT}")
