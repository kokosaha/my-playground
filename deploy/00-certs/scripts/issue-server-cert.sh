#!/bin/bash
# issue-server-cert.sh - 签发服务端证书（CSR 模式，动态 SAN 配置）
# 用法: ./issue-server-cert.sh <CSR文件路径> <CN> [SAN列表...]
# 示例: ./issue-server-cert.sh /path/to/server.csr 127.0.0.1 IP:127.0.0.1
# 示例: ./issue-server-cert.sh /path/to/server.csr emqx.internal DNS:emqx.internal

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "用法: $0 <CSR文件路径> <CN> [SAN列表...]"
  echo "示例: $0 /path/to/server.csr 127.0.0.1 IP:127.0.0.1"
  echo "示例: $0 /path/to/server.csr emqx.internal DNS:emqx.internal"
  exit 1
fi

CSR_FILE="$1"
CN="$2"
shift 2
SAN_LIST=("$@")

CERTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/certs/servers"
CA_DIR="$(cd "$(dirname "$0")/.." && pwd)/ca"
TEMPLATE_DIR="$(cd "$(dirname "$0")/../templates" && pwd)"

echo "=== 签发服务端证书 (CSR 模式) ==="
echo "CSR 文件: ${CSR_FILE}"
echo "CN:       ${CN}"
if [ ${#SAN_LIST[@]} -gt 0 ]; then
  echo "SAN:      ${SAN_LIST[*]}"
fi

mkdir -p "${CERTS_DIR}/csr"

# 1. 验证 CSR 合法性
echo ""
echo "CSR 信息:"
openssl req -in "${CSR_FILE}" -noout -subject

# 2. 动态生成带 SAN 的配置文件
TEMP_CNF=$(mktemp)
cat > "${TEMP_CNF}" << 'TPL'
basicConstraints = CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = critical,serverAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
subjectAltName = @alt_names

[alt_names]
TPL

# 追加 SAN 条目
SAN_IDX=1
for SAN in "${SAN_LIST[@]}"; do
  KEY=$(echo "$SAN" | cut -d: -f1)
  VAL=$(echo "$SAN" | cut -d: -f2-)
  echo "${KEY} = ${VAL}" >> "${TEMP_CNF}"
  ((SAN_IDX++))
done

# 3. 使用中间 CA 签发证书
openssl x509 -req \
  -in "${CSR_FILE}" \
  -CA "${CA_DIR}/intermediate-ca/certs/intermediate-ca.crt" \
  -CAkey "${CA_DIR}/intermediate-ca/private/intermediate-ca.key" \
  -CAcreateserial \
  -days 36135 -sha256 \
  -extfile "${TEMP_CNF}" \
  -out "${CERTS_DIR}/cert.pem"

rm -f "${TEMP_CNF}"

# 4. 归档 CSR
DEST_CSR="${CERTS_DIR}/csr/$(basename "${CSR_FILE}")"
if [ "${CSR_FILE}" != "${DEST_CSR}" ] && ! cmp -s "${CSR_FILE}" "${DEST_CSR}"; then
  cp "${CSR_FILE}" "${DEST_CSR}"
fi

echo ""
echo "服务端证书签发完成:"
openssl x509 -in "${CERTS_DIR}/cert.pem" -noout -subject -dates
echo "证书指纹: $(openssl x509 -in "${CERTS_DIR}/cert.pem" -noout -fingerprint -sha256)"
echo "SAN: $(openssl x509 -in "${CERTS_DIR}/cert.pem" -noout -text | grep -A1 "X509v3 Subject Alternative Name" | tail -1)"
