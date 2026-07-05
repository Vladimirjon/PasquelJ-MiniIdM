# Pruebas de resiliencia

| Prueba                | Fallo inducido                                 | Resultado                                  |
| --------------------- | ---------------------------------------------- | ------------------------------------------ |
| Apache idm1           | `pkill -9 apache2`                           | Web por VIP`OK=12`, `FAIL=0`           |
| slapd idm1            | `pkill -9 slapd`                             | LDAPS por VIP`OK=12`, `FAIL=0`         |
| Partición backends   | `iptables DROP` idm1 -> idm2 en 8443/636     | Web`12/12`, LDAP `12/12`               |
| Partición KDC        | `iptables DROP` client -> kdc1:88 TCP/UDP    | `kinit jrueda OK=8/8`                    |
| Certificado expirado  | Reemplazo temporal del certificado Web en idm1 | Cliente rechazó certificado expirado      |
| KDC primario caído   | `systemctl stop krb5-kdc` en idm1            | kdc2 emitió tickets; Web`HTTP_CODE=200` |
| HAProxy MASTER caído | `systemctl stop haproxy` en idm1             | Keepalived movió VIP a idm2               |
