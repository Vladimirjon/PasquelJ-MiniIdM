# idm1 (Nodo principal)

```text
IP: 192.168.74.11
FQDN: idm1.fis.epn.ec
```

**Servicios:**

```text
slapd
krb5-kdc
krb5-admin-server
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
749   kadmind
8443  Apache backend
443   HAProxy Web sobre VIP si posee VIP
636   HAProxy LDAPS sobre VIP si posee VIP
9100  node_exporter
```
