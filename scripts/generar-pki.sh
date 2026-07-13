#!/usr/bin/env bash
set -euo pipefail
umask 077

PKI_DIR="${PKI_DIR:-pki-output}"
DAYS_CA="${DAYS_CA:-3650}"
DAYS_CERT="${DAYS_CERT:-825}"
SUBJECT_BASE="/C=EC/ST=Pichincha/L=Quito/O=EPN/OU=FIS"

mkdir -p "$PKI_DIR"/{ca,certs,csr,private,ext}

CA_KEY="$PKI_DIR/ca/ca.key.pem"
CA_CERT="$PKI_DIR/ca/ca.cert.pem"

openssl ecparam -name prime256v1 -genkey -noout -out "$CA_KEY"
openssl req -new -x509 -sha256 -days "$DAYS_CA"   -key "$CA_KEY" -out "$CA_CERT"   -subj "$SUBJECT_BASE/CN=MiniIdM FIS Root CA ECDSA"

emitir() {
    local name="$1" cn="$2" san="$3"
    local key="$PKI_DIR/private/$name.key.pem"
    local csr="$PKI_DIR/csr/$name.csr.pem"
    local cert="$PKI_DIR/certs/$name.cert.pem"
    local ext="$PKI_DIR/ext/$name.ext"

    openssl ecparam -name prime256v1 -genkey -noout -out "$key"
    openssl req -new -sha256 -key "$key" -out "$csr"       -subj "$SUBJECT_BASE/CN=$cn"

    cat > "$ext" <<EOF
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=serverAuth
subjectAltName=$san
EOF

    openssl x509 -req -sha256 -days "$DAYS_CERT"       -in "$csr" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial       -extfile "$ext" -out "$cert"
}

emitir web-server web.fis.epn.ec   'DNS:web.fis.epn.ec,DNS:idm1.fis.epn.ec,DNS:idm2.fis.epn.ec,IP:192.168.74.100,IP:192.168.74.11,IP:192.168.74.12'
emitir ldap-server ldap.fis.epn.ec   'DNS:ldap.fis.epn.ec,DNS:ldap1.fis.epn.ec,DNS:ldap2.fis.epn.ec,DNS:idm1.fis.epn.ec,DNS:idm2.fis.epn.ec,IP:192.168.74.100,IP:192.168.74.11,IP:192.168.74.12'
emitir kdc1 kdc1.fis.epn.ec   'DNS:kdc1.fis.epn.ec,DNS:idm1.fis.epn.ec,IP:192.168.74.11'
emitir kdc2 kdc2.fis.epn.ec   'DNS:kdc2.fis.epn.ec,DNS:idm2.fis.epn.ec,IP:192.168.74.12'

echo "PKI_DIR=$PKI_DIR"
