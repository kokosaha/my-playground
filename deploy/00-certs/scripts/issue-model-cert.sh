#!/bin/bash
# issue-model-cert.sh - 签发型号证书（CSR 模式）
# 用法: ./issue-model-cert.sh <CSR文件路径>
# 示例: ./issue-model-cert.sh /path/to/csr.pem

set -e

if [ -z "$1" ]; then
  echo "用法: $0 <CSR文件路径>"
  exit 1
fi

CSR_FILE="$1"
CERTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/certs/models"
CA_DIR="$(cd "$(dirname "$0")/.." && pwd)/ca"
TEMPLATE_DIR="$(cd "$(dirname "$0")/../templates" && pwd)"
MODEL_NAME="CZ-EVSE"

echo "=== 签发型号证书 (CSR 模式) ==="
echo "CSR 文件: ${CSR_FILE}"

mkdir -p "${CERTS_DIR}/${MODEL_NAME}/csr"

# 1. 验证 CSR 合法性
echo "CSR 信息:"
openssl req -in "${CSR_FILE}" -noout -subject

# 2. 使用中间 CA 签发证书
openssl x509 -req \
  -in "${CSR_FILE}" \
  -CA "${CA_DIR}/intermediate-ca/certs/intermediate-ca.crt" \
  -CAkey "${CA_DIR}/intermediate-ca/private/intermediate-ca.key" \
  -CAcreateserial \
  -days 36135 -sha256 \
  -extfile "${TEMPLATE_DIR}/model-cert.cnf" \
  -out "${CERTS_DIR}/${MODEL_NAME}/cert.pem"

# 3. 归档 CSR
if [ "${CSR_FILE}" != "${CERTS_DIR}/${MODEL_NAME}/csr/$(basename "${CSR_FILE}")" ]; then
  cp "${CSR_FILE}" "${CERTS_DIR}/${MODEL_NAME}/csr/"
fi

echo "型号证书签发完成:"
openssl x509 -in "${CERTS_DIR}/${MODEL_NAME}/cert.pem" -noout -subject -dates
echo "证书指纹: $(openssl x509 -in "${CERTS_DIR}/${MODEL_NAME}/cert.pem" -noout -fingerprint -sha256)"
