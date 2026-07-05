# Monitoreo Prometheus

Prometheus se instaló en `client-miniidm` 

## Componentes

| Componente    | Nodo           | Puerto |
| ------------- | -------------- | -----: |
| Prometheus    | client-miniidm |   9090 |
| node_exporter | idm1           |   9100 |
| node_exporter | idm2           |   9100 |
| node_exporter | client-miniidm |   9100 |

## Targets

```text
192.168.74.11:9100 idm1 -> up
192.168.74.12:9100 idm2 -> up
192.168.74.20:9100 client -> up
127.0.0.1:9090 prometheus -> up
```

## Métricas

| Metrica                | Metodo                                                   | Resultado |
| ---------------------- | -------------------------------------------------------- | --------: |
| CPU y memoria          | Prometheus + node_exporter                               |   visible |
| LDAP queries/sec       | 50`ldapsearch` contra LDAPS VIP                        |      3.96 |
| Kerberos queries/sec   | 5`kinit` manuales con `emafla`                       |      0.19 |
| Retraso de replicacion | cambio en`replica-test` desde ldap1 observado en ldap2 |  10600 ms |
