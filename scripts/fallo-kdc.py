#!/usr/bin/env python3

import csv
import getpass
import os
import statistics
import subprocess
import time
from datetime import datetime
from pathlib import Path

PRINCIPAL = os.environ.get("TEST_PRINCIPAL", "emafla@FIS.EPN.EC")
ROUNDS = int(os.environ.get("ROUNDS", "40"))
RESULTS_DIR = Path(os.environ.get("RESULTS_DIR", str(Path.home())))
RESULTS_DIR.mkdir(parents=True, exist_ok=True)
OUT = str(RESULTS_DIR / "fallo_stop_kdc1.csv")

password = getpass.getpass(f"Contraseña Kerberos de {PRINCIPAL}: ")

rows = []

print()
print("=== MONITOREO DE FALLO DEL KDC PRINCIPAL ===")
print(f"Se realizarán {ROUNDS} solicitudes de TGT.")
print("Cuando comiencen los resultados, detén krb5-kdc en idm1.")
print()

for attempt in range(1, ROUNDS + 1):
    epoch_ms = time.time_ns() // 1_000_000
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]

    cache = f"/tmp/krb5cc_failover_{os.getpid()}_{attempt}"

    env = os.environ.copy()
    env["KRB5_CONFIG"] = "/etc/krb5.conf"
    env["KRB5CCNAME"] = f"FILE:{cache}"

    try:
        os.remove(cache)
    except FileNotFoundError:
        pass

    start_ns = time.perf_counter_ns()

    try:
        result = subprocess.run(
            ["kinit", PRINCIPAL],
            input=password + "\n",
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
            timeout=8,
            check=False,
        )

        status = "OK" if result.returncode == 0 else "FAIL"
        error = result.stderr.strip().replace(",", ";")

    except subprocess.TimeoutExpired:
        status = "FAIL"
        error = "TIMEOUT"

    end_ns = time.perf_counter_ns()
    duration_ms = (end_ns - start_ns) / 1_000_000

    rows.append(
        {
            "epoch_ms": epoch_ms,
            "timestamp": timestamp,
            "status": status,
            "duration_ms": f"{duration_ms:.2f}",
            "error": error,
        }
    )

    print(
        f"TGT={attempt:02d} "
        f"HORA={timestamp} "
        f"STATUS={status} "
        f"DURACION={duration_ms:.2f}ms"
    )

    try:
        os.remove(cache)
    except FileNotFoundError:
        pass

    time.sleep(0.25)

with open(OUT, "w", newline="", encoding="utf-8") as file:
    writer = csv.DictWriter(
        file,
        fieldnames=[
            "epoch_ms",
            "timestamp",
            "status",
            "duration_ms",
            "error",
        ],
    )
    writer.writeheader()
    writer.writerows(rows)

ok_rows = [row for row in rows if row["status"] == "OK"]
fail_rows = [row for row in rows if row["status"] == "FAIL"]
durations = [float(row["duration_ms"]) for row in rows]

print()
print("=== RESUMEN ===")
print(f"TOTAL={len(rows)}")
print(f"TGT_OK={len(ok_rows)}")
print(f"TGT_FAIL={len(fail_rows)}")
print(f"TASA_EXITO_PORCENTAJE={len(ok_rows) * 100 / len(rows):.2f}")
print(f"LATENCIA_PROMEDIO_MS={statistics.mean(durations):.2f}")
print(f"LATENCIA_MAXIMA_MS={max(durations):.2f}")

for row in fail_rows:
    print(
        f"FALLO HORA={row['timestamp']} "
        f"DURACION_MS={row['duration_ms']} "
        f"ERROR={row['error']}"
    )

print(f"EVIDENCIA={OUT}")
