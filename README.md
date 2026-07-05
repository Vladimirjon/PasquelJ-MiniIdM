# PasquelJ-MiniIdM

Infraestructura de Identidad Segura para la FIS.

Entorno: 3 VMs Linux en Oracle VirtualBox
Dominio logico: `fis.epn.ec`
Realm Kerberos: `FIS.EPN.EC`

## Arquitectura

| Nodo           |                 IP | FQDN                                     | Rol                                                                                                     |
| -------------- | -----------------: | ---------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| idm1           |  `192.168.74.11` | `idm1.fis.epn.ec`                      | - LDAP master<br />- KDC primario<br />- Apache backend<br />- HAProxy<br />- Keepalived MASTER      |
| idm2           |  `192.168.74.12` | `idm2.fis.epn.ec`                      | - LDAP réplica<br />- KDC secundario <br />- Apache backend <br />- HAProxy <br />- Keepalived BACKUP |
| client-miniidm |  `192.168.74.20` | `client.fis.epn.ec`                    | - Validación<br />- Prometheus                                                                         |
| VIP            | `192.168.74.100` | `web.fis.epn.ec` / `ldap.fis.epn.ec` | - Punto de acceso HA (Web y LDAPS)                                                                     |

## Mapa de requisitos

| Requisito                        | Carpeta                   |
| -------------------------------- | ------------------------- |
| Servicio de Directorio LDAP      | `ldap/`                 |
| PKI ECDSA y TLS                  | `pki/`                  |
| Kerberos                         | `kerberos/`             |
| Integración LDAP-Kerberos       | `ldap-kerberos/`        |
| Alta disponibilidad              | `HA/`                   |
| Inyeccion de fallos y resultados | `pruebas-resiliencia/`  |
| Prometheus y métricas           | `monitoreo-prometheus/` |
| Configuración por nodo          | `configs/`              |
| Scripts de validacion            | `scripts/`              |

## Resultados principales

| Bloque                  | Resultado                                                          |
| ----------------------- | ------------------------------------------------------------------ |
| LDAPS por VIP           | Certificado válido y`ldapsearch` exitoso                        |
| Web TLS + Kerberos      | `HTTP_CODE=200` con ticket `HTTP/web.fis.epn.ec`               |
| Replicación LDAP       | Entrada creada en master visible en réplica                       |
| KDC secundario          | Con KDC primario detenido, el cliente obtuvo tickets desde`kdc2` |
| HAProxy + Keepalived    | VIP migrada a idm2 ante fallo de HAProxy en MASTER                 |
| Crash Apache            | `OK=12`, `FAIL=0`                                              |
| Crash slapd             | `OK=12`, `FAIL=0`                                              |
| iptables KDC            | `kinit jrueda OK=8/8`                                            |
| Prometheus              | Targets idm1, idm2, client y prometheus local`up`                |
| LDAP qps                | `LDAP_QPS_SUCCESS=3.96`                                          |
| Kerberos qps            | `KERBEROS_QPS_SUCCESS=0.19`                                      |
| Retraso de replicación | `LDAP_REPLICATION_DELAY_MS=10600`                                |

## Makefile

```bash
make help
make check-client
make check-idm1
make check-idm2
make test-web
make test-ldap
make test-prometheus
```
