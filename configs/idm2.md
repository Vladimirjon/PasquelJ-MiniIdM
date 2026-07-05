# idm2 (Nodo secundario)

```text
IP: 192.168.74.12
FQDN: idm2.fis.epn.ec
```

**Servicios:**

```text
slapd
krb5-kdc
krb5-kpropd
apache2
haproxy
keepalived
prometheus-node-exporter
```

**Puertos:**

```text
88    Kerberos
389   LDAP
636   LDAPS backend en IP real
754   kpropd
8443  Apache backend
9100  node_exporter
```
