#!/bin/bash
# generate-intermediate-ca.sh - 生成中间 CA

set -e

CA_DIR="$(cd "$(dirname "$0")/.." && pwd)/ca"
TEMPLATE_DIR="$(cd "$(dirname "$0")/../templates" && pwd)"
DAYS=36135

echo "=== 生成中间 CA ==="

mkdir -p "${CA_DIR}/intermediate-ca/private" "${CA_DIR}/intermediate-ca/certs" "${CA_DIR}/intermediate-ca/csr"

# 生成私钥
openssl ecparam -name prime256v1 -genkey -out "${CA_DIR}/intermediate-ca/private/intermediate-ca.key"
chmod 600 "${CA_DIR}/intermediate-ca/private/intermediate-ca.key"

# 生成 CSR
openssl req -new -key "${CA_DIR}/intermediate-ca/private/intermediate-ca.key" \
  -subj "/C=CN/ST=hunan/L=zhuzhou/O=株洲中车时代电气股份有限公司绿能分公司/CN=ZZCQC Intermediate CA" \
  -out "${CA_DIR}/intermediate-ca/csr/intermediate-ca.csr"

# 签发证书（需使用根 CA）
openssl x509 -req \
  -in "${CA_DIR}/intermediate-ca/csr/intermediate-ca.csr" \
  -CA "${CA_DIR}/root-ca/certs/root-ca.crt" \
  -CAkey "${CA_DIR}/root-ca/private/ca.key" \
  -CAcreateserial \
  -days $DAYS -sha256 \
  -extfile "${TEMPLATE_DIR}/intermediate-ca.cnf" \
  -out "${CA_DIR}/intermediate-ca/certs/intermediate-ca.crt"

echo "中间 CA 生成完成:"
openssl x509 -in "${CA_DIR}/intermediate-ca/certs/intermediate-ca.crt" -noout -subject -dates
