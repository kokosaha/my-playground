# 充电桩 TLS 终结测试总结

## 一、测试概述

本次测试验证了 **NGINX TLS 终结 + 双向认证 + EMQX 后端转发** 的完整链路，在 OrbStack Ubuntu VM + Docker 环境中完成。

---

## 二、组网架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Mac 宿主机 (OrbStack)                                                 │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  Docker (OrbStack)                                               │  │
│  │                                                                  │  │
│  │   02-emqx_emqx-net (bridge, 192.168.97.0/24)                   │  │
│  │   ┌──────────────────────────────────────────────┐             │  │
│  │   │  emqx_v57  (EMQX 5.7.1)                       │             │  │
│  │   │  容器 IP: 192.168.97.2                        │             │  │
│  │   │  :1883 (MQTT 明文)                            │             │  │
│  │   │  :18083 (Dashboard)                           │             │  │
│  │   └──────────────────────────────────────────────┘             │  │
│  │                                    ▲                           │  │
│  │                                    │ TCP :1883                 │  │
│  └────────────────────────────────────┼───────────────────────────┘  │
│                                       │                                   │
│  ┌────────────────────────────────────┼───────────────────────────┐  │
│  │  OrbStack Ubuntu VM (192.168.139.225)                           │  │
│  │                                                                  │  │
│  │   eth0 (192.168.139.x) ◄─── 宿主机 bridge (192.168.139.1)     │  │
│  │                                      │                           │  │
│  │   ┌─────────────────────────────┐    │                           │  │
│  │   │  NGINX (TLS 终结)           │    │                           │  │
│  │   │  listen :8883 ssl           │    │                           │  │
│  │   │  ssl_verify_client on       │    │                           │  │
│  │   │  upstream: 192.168.97.2    ├────┼───────────────────────────┘  │
│  │   └─────────────────────────────┘    │                             │
│  │                                      │                             │
│  │   ┌─────────────────────────────┐    │                             │
│  │   │  Python TLS 测试脚本         │    │                             │
│  │   │  (客户端, 作测试用)          │    │                             │
│  │   │  TLS 双向认证               │    │                             │
│  │   │  连接 127.0.0.1:8883       └────┼─────────────────────────►    │
│  │   └─────────────────────────────┘         TLS + MQTT + AUTH        │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 流量走向

```
测试脚本 --[TLS 双向认证]--> 127.0.0.1:8883 (NGINX)
                                        │
                                   TLS 解密
                                        │ TCP 明文
                                        ▼
                              192.168.97.2:1883 (EMQX 容器)
                                        │
                                   MQTT AUTH
                                   (test/Test1234!)
```

### 部署位置对比

| 组件 | 部署位置 | 运行方式 |
|---|---|---|
| NGINX | OrbStack Ubuntu VM (192.168.139.225) | apt 安装，直接运行 |
| EMQX `emqx_v57` | Mac 宿主机 Docker (OrbStack) | `docker compose up -d` |
| Python 测试脚本 | OrbStack Ubuntu VM | 直接在 VM 里执行 |

### 关键配置

| 组件 | 配置 | 值 |
|---|---|---|
| NGINX | listen | `8883 ssl` |
| NGINX | ssl_verify_client | `on` |
| NGINX | upstream | `192.168.97.2:1883` (容器真实IP) |
| EMQX | port | `1883` (MQTT) |
| EMQX | auth | username: `test`, password: `Test1234!` |

---

## 三、问题排查与解决

### 问题：MQTT CONNECT 无响应

**症状**：VM 连接 `emqx_v57:1883` (DNS 解析到 `198.18.0.59`) 后发送 MQTT CONNECT，EMQX 始终不返回 CONNACK。

**排查过程**：

1. `docker inspect emqx_v57` 发现容器真实 IP 是 `192.168.97.2`
2. `emqx_v57` hostname 被 DNS 解析到 `198.18.0.59`（Docker 内部网关 IP）
3. `198.18.0.59` TCP  connect() 成功，但 MQTT 数据包发送后无响应
4. `192.168.97.2` 直接连接正常（CONNACK 秒回）

**根本原因**：`emqx_v57` hostname 解析到错误的 IP（Docker 内部网关），导致网络路由到错误的容器或网关，MQTT 包无法到达 EMQX。

**解决方案**：修改 `nginx.conf` 中 upstream 为容器真实 IP：

```diff
upstream mqtt_backend {
-   server emqx_v57:1883;
+   server 192.168.97.2:1883;
}
```

---

## 四、测试结果

| 测试项 | 结果 | 说明 |
|---|---|---|
| NGINX master 进程 (root) | ✅ PASS | 以 root 运行 |
| NGINX worker 进程 (nobody) | ✅ PASS | 非 root 安全运行 |
| 8883 端口监听 | ✅ PASS | `0.0.0.0:8883 LISTEN` |
| 私钥权限 600 | ✅ PASS | `server.key`, `client.key` |
| 证书权限 644 | ✅ PASS | `*.pem` 文件 |
| 目录权限 750 | ✅ PASS | `/etc/nginx/certs` |
| `ssl_verify_client on` | ✅ PASS | 配置生效 |
| TLS 双向认证 (openssl) | ✅ PASS | TLSv1.3 + TLS_AES_256_GCM_SHA384 |
| MQTT + TLS + 认证 | ✅ PASS | CONNACK rc=0 |

---

## 五、验证命令

```bash
# 1. NGINX 进程状态
ps aux | grep nginx | grep -v grep
# root ... nginx: master process
# nobody ... nginx: worker process

# 2. TLS 双向认证测试
echo | openssl s_client -connect 127.0.0.1:8883 \
  -CAfile /etc/nginx/certs/ca.pem \
  -cert /etc/nginx/certs/client.pem \
  -key /etc/nginx/certs/client.key

# 3. MQTT over TLS + 认证测试 (Python)
python3 -c "
import socket, ssl, struct, time
sock = socket.socket()
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
ctx.load_verify_locations('/etc/nginx/certs/ca.pem')
ctx.load_cert_chain('/etc/nginx/certs/client.pem', '/etc/nginx/certs/client.key')
ctx.verify_mode = ssl.CERT_REQUIRED
ctx.check_hostname = False
ssock = ctx.wrap_socket(sock, server_hostname='127.0.0.1')
ssock.connect(('127.0.0.1', 8883))
var_header = struct.pack('!H', 4) + b'MQTT' + bytes([4]) + bytes([0xC2]) + struct.pack('!H', 60)
payload = struct.pack('!H', 4) + b'test' + struct.pack('!H', 9) + b'Test1234!'
packet = bytes([0x10, len(var_header) + len(payload)]) + var_header + payload
ssock.sendall(packet)
time.sleep(0.5)
data = ssock.recv(1024)
print('MQTT CONNACK:', data.hex() if data else 'FAIL')
ssock.close()
"
```

---

## 六、关键文件路径

| 文件 | 路径 | 用途 |
|---|---|---|
| nginx.conf | `deploy/04-nginx-lb/nginx.conf` | NGINX 配置（含 load_module） |
| mqtt_tls_test.py | `deploy/04-nginx-lb/mqtt_tls_test.py` | Python MQTT TLS 测试脚本 |
| server.pem | `deploy/04-nginx-lb/certs/server.pem` | 服务端证书 |
| server.key | `deploy/04-nginx-lb/certs/server.key` | 服务端私钥 |
| ca.pem | `deploy/04-nginx-lb/certs/ca.pem` | CA 证书 |
| client.pem | `deploy/00-certs/archive/20260420-historical/client.pem` | 客户端证书 |
| client.key | `deploy/00-certs/archive/20260420-historical/client.key` | 客户端私钥 |

---

## 七、测试环境信息

- **OS**: OrbStack Ubuntu VM (amd64, Ubuntu Noble)
- **NGINX**: 1.24.0 (via apt install + libnginx-mod-stream)
- **EMQX**: 5.7.1 (Docker container `emqx_v57`)
- **Python**: 3.12 (with paho-mqtt)
- **测试日期**: 2026-04-21
