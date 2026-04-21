#!/bin/bash
# generate-server-csr.sh - 生成服务端证书 CSR（业务系统侧执行）
# 用法: ./generate-server-csr.sh <CN> [SAN列表...]
# 示例: ./generate-server-csr.sh 127.0.0.1 IP:127.0.0.1
# 示例: ./generate-server-csr.sh emqx.internal DNS:emqx.internal

set -e

if [ -z "$1" ]; then
  echo "用法: $0 <CN> [SAN列表...]"
  echo "示例: $0 127.0.0.1 IP:127.0.0.1"
  echo "示例: $0 emqx.internal DNS:emqx.internal"
  exit 1
fi

CN="$1"
shift
SAN_LIST=("$@")

CERTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/certs/servers"

echo "=== 生成服务端 CSR ==="
echo "CN:   ${CN}"
if [ ${#SAN_LIST[@]} -gt 0 ]; then
  echo "SAN:  ${SAN_LIST[*]}"
fi

mkdir -p "${CERTS_DIR}/private" "${CERTS_DIR}/csr"

# 1. 生成私钥
openssl ecparam -name prime256v1 -genkey -out "${CERTS_DIR}/private/server.key"
chmod 600 "${CERTS_DIR}/private/server.key"

# 2. 生成 CSR
openssl req -new \
  -key "${CERTS_DIR}/private/server.key" \
  -subj "/C=CN/ST=hunan/L=zhuzhou/O=株洲中车时代电气股份有限公司绿能分公司/CN=${CN}" \
  -out "${CERTS_DIR}/csr/server.csr"

echo ""
echo "CSR 生成完成:"
echo "  私钥: ${CERTS_DIR}/private/server.key"
echo "  CSR:  ${CERTS_DIR}/csr/server.csr"
openssl req -in "${CERTS_DIR}/csr/server.csr" -noout -subject
echo ""
echo "请将 CSR 文件和 SAN 配置提交给 CA 签发，私钥请妥善保管。"
