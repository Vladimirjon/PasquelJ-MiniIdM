#!/usr/bin/env python3
import getpass
import os
import statistics
import subprocess
import tempfile
import time
from pathlib import Path

principal = os.environ.get("TEST_PRINCIPAL", "emafla@FIS.EPN.EC")
rounds = int(os.environ.get("ROUNDS", "20"))
results_dir = Path(os.environ.get("RESULTS_DIR", str(Path.home())))
results_dir.mkdir(parents=True, exist_ok=True)
out = results_dir / "metrica_kerberos_qps_final.txt"
password = getpass.getpass(f"Contraseña Kerberos de {principal}: ")
lines = [
    "=== KERBEROS TGT QPS ===",
    f"PRINCIPAL={principal}",
    f"AUTENTICACIONES={rounds}",
    "",
]
times = []
ok = 0
start_total = time.perf_counter()

for attempt in range(1, rounds + 1):
    cache = tempfile.NamedTemporaryFile(prefix="krb5cc_qps_", delete=True).name
    env = os.environ.copy()
    env["KRB5CCNAME"] = f"FILE:{cache}"
    start = time.perf_counter()
    result = subprocess.run(
        ["kinit", principal],
        input=password + "\n",
        text=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        env=env,
        check=False,
    )
    elapsed = time.perf_counter() - start
    times.append(elapsed)
    state = "OK" if result.returncode == 0 else "FAIL"
    ok += result.returncode == 0
    lines.append(
        f"INTENTO={attempt:02d} ESTADO={state} TIEMPO={elapsed:.6f}s"
    )
    try:
        os.remove(cache)
    except FileNotFoundError:
        pass

elapsed_total = time.perf_counter() - start_total
lines += [
    "",
    f"TOTAL={rounds}",
    f"OK={ok}",
    f"FAIL={rounds - ok}",
    f"ELAPSED_SECONDS={elapsed_total:.6f}",
    f"KERBEROS_TGT_QPS_SUCCESS={ok / elapsed_total:.2f}",
    f"LATENCIA_PROMEDIO_MS={statistics.mean(times) * 1000:.2f}",
    f"LATENCIA_MINIMA_MS={min(times) * 1000:.2f}",
    f"LATENCIA_MAXIMA_MS={max(times) * 1000:.2f}",
]
text = "\n".join(lines) + "\n"
print(text, end="")
out.write_text(text, encoding="utf-8")
