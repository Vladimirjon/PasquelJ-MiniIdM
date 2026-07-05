# client-miniidm 

```text
IP: 192.168.74.20
FQDN: client.fis.epn.ec
```

**Usos:**

```text
kinit
klist
curl --negotiate
ldapsearch
openssl s_client
Prometheus :9090
node_exporter :9100
```

**Resolución:**

```text
web.fis.epn.ec  -> 192.168.74.100
ldap.fis.epn.ec -> 192.168.74.100
kdc1.fis.epn.ec -> 192.168.74.11
kdc2.fis.epn.ec -> 192.168.74.12
ldap1.fis.epn.ec -> 192.168.74.11
ldap2.fis.epn.ec -> 192.168.74.12
```
