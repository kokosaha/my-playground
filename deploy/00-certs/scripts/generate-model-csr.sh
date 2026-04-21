#!/bin/bash
# generate-model-csr.sh - 生成型号证书 CSR（业务系统侧执行）
# 用法: ./generate-model-csr.sh <输出目录>
# 示例: ./generate-model-csr.sh ./csr-output

set -e

OUTPUT_DIR="${1:-./csr-output}"
MODEL_NAME="CZ-EVSE"

echo "=== 生成型号 CSR (CZ-EVSE) ==="

mkdir -p "${OUTPUT_DIR}/private"

# 1. 生成私钥
openssl ecparam -name prime256v1 -genkey -out "${OUTPUT_DIR}/private/${MODEL_NAME}.key"
chmod 600 "${OUTPUT_DIR}/private/${MODEL_NAME}.key"

# 2. 生成 CSR
openssl req -new \
  -key "${OUTPUT_DIR}/private/${MODEL_NAME}.key" \
  -subj "/C=CN/ST=hunan/L=zhuzhou/O=株洲中车时代电气股份有限公司绿能分公司/CN=${MODEL_NAME}" \
  -out "${OUTPUT_DIR}/${MODEL_NAME}.csr"

echo "CSR 生成完成:"
echo "  私钥: ${OUTPUT_DIR}/private/${MODEL_NAME}.key"
echo "  CSR:  ${OUTPUT_DIR}/${MODEL_NAME}.csr"
openssl req -in "${OUTPUT_DIR}/${MODEL_NAME}.csr" -noout -subject
echo ""
echo "请将 CSR 文件提交给 CA 签发，私钥请妥善保管。"
