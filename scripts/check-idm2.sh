#!/usr/bin/env bash
set -u

echo "=== IDM2 CHECK ==="
date '+%F %T'
hostname -f

echo "=== services ==="
for svc in slapd krb5-kdc krb5-kpropd apache2 haproxy keepalived prometheus-node-exporter; do
  printf "%-32s" "$svc"
  systemctl is-active "$svc" || true
done

echo "=== IP addresses ==="
ip -br addr show enp0s8 || true

echo "=== ports ==="
ss -lntup | grep -E ':(88|389|443|636|754|8443|9100)\b' || true
ss -lnup | grep -E ':(88)\b' || true
