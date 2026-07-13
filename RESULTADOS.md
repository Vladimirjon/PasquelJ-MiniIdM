# Resultados

## Configuración

| Componente | Resultado |
|---|---|
| LDAP | 18 entradas, 6 cuentas POSIX y 3 grupos; mismo contenido en la réplica |
| PKI | CA y certificados ECDSA P-256 para LDAP, Web, KDC y nodos |
| LDAP-Kerberos | 6/6 identidades sincronizadas, sin diferencias |

## Disponibilidad

| Prueba | Resultado |
|---|---|
| Crash de Apache en `idm1` (`kill -9`) | 80/80 respuestas HTTP 200; reinicio local en 295.829 ms |
| Apache detenido en `idm1` | 78/80 respuestas HTTP 200; failover estable en 7.263 s |
| LDAP detenido en `idm1` | 78/80 consultas correctas; failover estable en 7.500 s |
| KDC primario detenido | 40/40 TGT; respuesta desde `idm2`; latencia media 452.74 ms y máxima 1035.74 ms |
| Partición LDAP con `iptables` | El cambio no llegó durante el bloqueo; recuperación en 6.637 s desde el desbloqueo, sin pérdida |
| Certificado Web expirado en `idm1` | 10/20 solicitudes HTTP 200; 10/20 rechazadas por TLS; el chequeo TCP no retiró el backend |

## Rendimiento

| Métrica | Resultado |
|---|---:|
| LDAP | 27.82 consultas/s; 250/250 correctas |
| Kerberos | 28.97 TGT/s; latencia media 34.43 ms |
| Replicación LDAP | 72.59 ms de extremo a extremo; 38.06 ms después del ACK del principal |
| Overhead TLS | 8.056 ms de media; 50/50 solicitudes HTTP 200 |
| Web con dos backends | 73.37 solicitudes/s; 250 en `idm1` y 250 en `idm2` |
| Web con un backend | 74.15 solicitudes/s; 500 en `idm2` |

La carga de 20 solicitudes concurrentes no saturó un backend. El balanceo mantuvo una distribución 50/50 y la continuidad del servicio, sin una mejora medible de throughput.

## Monitoreo

| Nodo | CPU | Memoria |
|---|---:|---:|
| `client` | 10.39 % | 20.10 % |
| `idm1` | 5.62 % | 18.37 % |
| `idm2` | 13.87 % | 18.43 % |

Los cuatro targets de Prometheus estuvieron en estado `up=1`.
