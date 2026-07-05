# LDAP

La raiz del DIT es:

```text
dc=fis,dc=epn,dc=ec
```

## Nodos

| Nodo | Rol                     |
| ---- | ----------------------- |
| idm1 | LDAP master / provider  |
| idm2 | LDAP replica / consumer |

## Replicación

- idm1 usa `syncprov`.
- idm2 usa `syncrepl refreshAndPersist`.
- La comunicación de réplica usa LDAPS y valida la CA.

# LDAPS en OpenLDAP

**Archivos TLS:**

```text
/etc/ldap/tls/ca.cert.pem
/etc/ldap/tls/ldap-server.cert.pem
/etc/ldap/tls/ldap-server.key.pem
```

**Servicios**:

```text
idm1 slapd: ldaps://192.168.74.11:636
idm2 slapd: ldaps://192.168.74.12:636
VIP/HAProxy: ldaps://ldap.fis.epn.ec:636
```
