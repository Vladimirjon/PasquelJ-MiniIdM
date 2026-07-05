#!/usr/bin/env bash
set -u

echo "=== PROMETHEUS TARGETS TEST ==="
date '+%F %T'
hostname -f

systemctl is-active prometheus || true
ss -lntup | grep -E ':9090\b' || true

curl -s 'http://127.0.0.1:9090/api/v1/query?query=up' \
  | grep -oE '"instance":"[^"]+"|"job":"[^"]+"|"node":"[^"]+"|"value":\[[^]]+\]' \
  | sed 's/","/\n/g'
