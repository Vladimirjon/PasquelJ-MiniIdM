# MiniIdM FIS

Infraestructura de identidad con OpenLDAP, Kerberos, PKI ECDSA, Apache, HAProxy, Keepalived y Prometheus.

## Arquitectura

| Nodo                  |                 IP | Función                                                           |
| --------------------- | -----------------: | ------------------------------------------------------------------ |
| `idm1.fis.epn.ec`   |  `192.168.74.11` | LDAP principal, KDC primario, Apache, HAProxy y Keepalived MASTER  |
| `idm2.fis.epn.ec`   |  `192.168.74.12` | LDAP réplica, KDC secundario, Apache, HAProxy y Keepalived BACKUP |
| `client.fis.epn.ec` |  `192.168.74.20` | Pruebas y Prometheus                                               |
| VIP                   | `192.168.74.100` | `web.fis.epn.ec:443` y `ldap.fis.epn.ec:636`                   |

LDAP usa `dc=fis,dc=epn,dc=ec`. Kerberos usa el realm `FIS.EPN.EC`. La base del KDC se propaga desde `idm1` hacia `idm2` con `kdb5_util dump` y `kprop`.

## Estructura

| Ruta              | Contenido                                                    |
| ----------------- | ------------------------------------------------------------ |
| `config/`       | Configuración de LDAP, Kerberos, PKI, Web, HA y Prometheus |
| `scripts/`      | Validaciones, métricas e inyección de fallos               |
| `resultados/`   | Datos obtenidos en las pruebas                               |
| `RESULTADOS.md` | Resumen de disponibilidad y rendimiento                      |

## Uso

```bash
make help
make syntax
make check-client
make check-idm1
make check-idm2
make test-web
make test-ldap
make test-prometheus
make test-integracion
```

Los scripts del cliente buscan la CA en `$HOME/miniidm-fis-root-ca.cert.pem`. La ruta puede cambiarse con `CA_FILE`.
