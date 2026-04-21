#!/bin/bash
set -e

CA_DIR="./certs"
mkdir -p "$CA_DIR"

echo "=== Generating CA certificate ==="
openssl genrsa -out "$CA_DIR/ca.key" 4096
openssl req -x509 -new -nodes -key "$CA_DIR/ca.key" -sha256 -days 3650 \
  -subj "/CN=MyLocalCA/O=MyOrganization/C=CN" -out "$CA_DIR/ca.pem"

echo "=== Generating server certificate ==="
openssl genrsa -out "$CA_DIR/server.key" 2048
openssl req -new -key "$CA_DIR/server.key" -subj "/CN=127.0.0.1/C=CN" -out "$CA_DIR/server.csr"

echo "=== Creating OpenSSL config with SAN ==="
cat > "$CA_DIR/openssl.cnf" << 'EOF'
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = 127.0.0.1

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = IP:127.0.0.1
EOF

echo "=== Signing server certificate with SAN ==="
openssl x509 -req -in "$CA_DIR/server.csr" -CA "$CA_DIR/ca.pem" -CAkey "$CA_DIR/ca.key" \
  -CAcreateserial -days 365 -sha256 -extfile "$CA_DIR/openssl.cnf" -extensions v3_req \
  -out "$CA_DIR/server.pem"

echo "=== Generating client certificate ==="
openssl genrsa -out "$CA_DIR/client.key" 2048
openssl req -new -key "$CA_DIR/client.key" -subj "/CN=mqttx-client/C=CN" -out "$CA_DIR/client.csr"
openssl x509 -req -in "$CA_DIR/client.csr" -CA "$CA_DIR/ca.pem" -CAkey "$CA_DIR/ca.key" \
  -CAcreateserial -days 365 -sha256 -out "$CA_DIR/client.pem"

chmod 600 "$CA_DIR/ca.key" "$CA_DIR/server.key" "$CA_DIR/client.key"
chmod 644 "$CA_DIR/ca.pem" "$CA_DIR/server.pem" "$CA_DIR/client.pem"
rm -f "$CA_DIR/server.csr" "$CA_DIR/client.csr" "$CA_DIR/ca.srl"

echo "========================================"
echo "✅ Certificates generated for mTLS!"
echo "========================================"
echo "CA:       ca.pem, ca.key"
echo "Server:   server.pem, server.key"
echo "Client:   client.pem, client.key"