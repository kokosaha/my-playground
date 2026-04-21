#!/bin/bash
# generate-root-ca.sh - 生成根 CA（离线环境执行）

set -e

CA_DIR="$(cd "$(dirname "$0")/.." && pwd)/ca/root-ca"
DAYS=36135

echo "=== 生成根 CA（请在离线环境执行）==="

mkdir -p "${CA_DIR}/private" "${CA_DIR}/certs" "${CA_DIR}/archive"

# 生成私钥
openssl ecparam -name prime256v1 -genkey -out "${CA_DIR}/private/ca.key"
chmod 600 "${CA_DIR}/private/ca.key"

# 生成自签名证书
openssl req -x509 -new -nodes -key "${CA_DIR}/private/ca.key" \
  -sha256 -days $DAYS \
  -subj "/C=CN/ST=hunan/L=zhuzhou/O=株洲中车时代电气股份有限公司绿能分公司/CN=ZZCQC Root CA" \
  -out "${CA_DIR}/certs/root-ca.crt"

echo "根 CA 生成完成:"
openssl x509 -in "${CA_DIR}/certs/root-ca.crt" -noout -subject -dates

echo ""
echo "警告：请将私钥备份至加密 U 盘并离线保管"
