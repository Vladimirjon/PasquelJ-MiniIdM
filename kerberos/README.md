# Kerberos

Realm

```text
FIS.EPN.EC
```

## Nodos

| Nodo | Rol                                    |
| ---- | -------------------------------------- |
| idm1 | KDC primario y servidor administrativo |
| idm2 | KDC secundario                         |

## Principals 

```text
emafla@FIS.EPN.EC
jrueda@FIS.EPN.EC
jperez@FIS.EPN.EC
malvan@FIS.EPN.EC
dnoboa@FIS.EPN.EC
ldap/ldap1.fis.epn.ec@FIS.EPN.EC
ldap/ldap.fis.epn.ec@FIS.EPN.EC
HTTP/web.fis.epn.ec@FIS.EPN.EC
```

## Validación

```bash
kinit jperez
klist
```

## HA Kerberos

* El cliente conoce `kdc1.fis.epn.ec` y `kdc2.fis.epn.ec`.

* Si el primario cae, el secundario puede emitir tickets.
