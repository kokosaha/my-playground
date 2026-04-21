# MQTT 单向认证测试总结

## 测试环境

- EMQX 版本: 5.7.1
- MQTT 客户端: MQTTX
- SSL 端口: 8883

## 遇到的问题及解决方案

### 问题 1: SSL 握手失败 - KEY_USAGE_BIT_INCORRECT

**错误信息:**

```
Error: write EPROTO ... KEY_USAGE_BIT_INCORRECT
```

**原因:** 证书的 Key Usage 扩展不符合 TLS 1.3 要求

**解决:** 移除证书的自定义扩展，使用 OpenSSL 默认扩展

原理：

TLS协商过程

1. 客户端发送 ClientHello
   → 列出支持的 TLS 版本列表（如 1.3, 1.2）
2. 服务端收到后
   → 从客户端提供的版本中，选择服务端支持的**最高版本**
3. 服务端发送 ServerHello
   → 告知客户端选择的 TLS 版本

---

### 问题 2: 证书 hostname 验证失败

**错误信息:**

```
ERR_TLS_CERT_ALTNAME_INVALID: IP: 127.0.0.1 is not in the cert's list
```

**原因:** 证书缺少 Subject Alternative Name (SAN) 扩展

**解决:** 在证书中添加 SAN 扩展

原理：

客户端连接服务器时，会验证服务端证书的域名/IP是否与连接的地址匹配，防止中间人攻击。
客户端连接: 127.0.0.1:8883
↓
检查证书: CN=127.0.0.1, SAN=IP:127.0.0.1
↓
匹配 ✅ 连接成功

```
subjectAltName = IP:127.0.0.1
```

---

## 最终正确的证书配置

### OpenSSL 配置 (openssl.cnf)

```ini
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
```

### EMQX 配置 (cluster.hocon)

```hocon
ssl_options {
  cacertfile = "data/certs/ca.pem"
  certfile = "data/certs/server.pem"
  keyfile = "data/certs/server.key"
  verify = verify_none
  versions = ["tlsv1.3", "tlsv1.2"]
}
```

**注意：** 删除证书配置后，EMQX 会自动加载内置默认证书（CN=Server），需手动复制证书到 `data/certs/` 并重启。

原理：

要生成包含 SAN 的证书，而 SAN 只能通过配置文件方式添加

- 单独使用命令行无法添加拓展字段，例如SAN、keyUsage
- 使用命令生产的证书没有 subjectAltName

---

## 测试结果

- 单向认证 ✅ 连接成功
- SSL/TLS 验证 ✅ 正常工作
- MQTT 消息收发 ✅ 正常

---

## 文件清单

| 文件                       | 用途                        |
| -------------------------- | --------------------------- |
| certs/ca.pem               | CA 证书（MQTTX 客户端使用） |
| certs/server.pem           | 服务器证书                  |
| certs/server.key           | 服务器私钥                  |
| gen_cert.sh                | 证书生成脚本                |
| data/certs/\*              | 容器内使用的证书副本        |
| data/configs/cluster.hocon | EMQX 配置文件               |
