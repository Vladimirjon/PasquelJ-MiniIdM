# HA: Alta disponibilidad

La alta disponibilidad se implementó con dos nodos y una **VIP.**

## Componentes

| Componente            | Funcion                                                              |
| --------------------- | -------------------------------------------------------------------- |
| Keepalived            | Mueve la VIP`192.168.74.100` entre **idm1** e **idm2** |
| HAProxy               | Balancea Web y LDAPS en modo**TCP passthrough**                |
| OpenLDAP réplica     | Permite lecturas LDAP si cae el master                               |
| KDC secundario        | Permite autenticación si cae el KDC primario                        |
| Apache en ambos nodos | Permite mantener Web si cae un backend                               |

## Servicios

```text
web.fis.epn.ec:443  -> HAProxy -> idm1:8443 / idm2:8443
ldap.fis.epn.ec:636 -> HAProxy -> ldap1:636 / ldap2:636
```

## Keepalived

```text
idm1: MASTER, priority 110
idm2: BACKUP, priority 100
VIP: 192.168.74.100/24 dev enp0s8
```
