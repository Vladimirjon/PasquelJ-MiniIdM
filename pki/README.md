# PKI ECDSA

## CA

```text
MiniIdM FIS Root CA ECDSA
```

La CA se generó en idm1:

```text
/home/johann_ha1/miniidm/pki
```

```text
ca/miniidm-fis-root-ca.cert.pem       # CA pública
ca/miniidm-fis-root-ca.key.pem        # CA privada, NO publicar
certs/ldap-server.cert.pem
certs/web-server.cert.pem
private/ldap-server.key.pem           # NO publicar
private/web-server.key.pem            # NO publicar
```

## Validación

```bash
openssl verify -CAfile ca/miniidm-fis-root-ca.cert.pem certs/ldap-server.cert.pem
openssl verify -CAfile ca/miniidm-fis-root-ca.cert.pem certs/web-server.cert.pem
```
