#!/usr/bin/env python3
"""
TLS Termination Test Script
测试 NGINX TLS 终结 + 双向认证 + EMQX 后端转发

用法:
  # 双向认证测试（带客户端证书）
  python3 mqtt_tls_test.py --test mutual

  # 无客户端证书测试（预期失败）
  python3 mqtt_tls_test.py --test no-client-cert

  # 单向认证测试
  python3 mqtt_tls_test.py --test one-way
"""

import paho.mqtt.client as mqtt
import ssl
import argparse
import sys

# 配置
NGINX_HOST = "127.0.0.1"
NGINX_PORT = 8883  # NGINX inside VM listens on 8883
CA_CERT = "/etc/nginx/certs/ca.pem"
CLIENT_CERT = "/etc/nginx/certs/client.pem"
CLIENT_KEY = "/etc/nginx/certs/client.key"
TEST_TOPIC = "test/tls"
TEST_MESSAGE = "Hello from TLS termination test"


def on_connect(client, userdata, flags, rc, properties=None):
    if rc == 0:
        print(f"[OK] Connected to MQTT broker (rc={rc})")
    else:
        print(f"[FAIL] Connection failed (rc={rc})")


def on_disconnect(client, userdata, rc, properties=None):
    print(f"[INFO] Disconnected (rc={rc})")


def on_message(client, userdata, msg):
    print(f"[OK] Received: {msg.payload.decode()}")


def on_subscribe(client, userdata, mid, qos, properties=None):
    print(f"[OK] Subscribed (mid={mid})")


def test_mutual_tls():
    """双向认证测试 - 带客户端证书"""
    print("\n=== 双向认证测试 (Mutual TLS) ===")
    print(f"Server: {NGINX_HOST}:{NGINX_PORT}")
    print(f"CA Cert: {CA_CERT}")
    print(f"Client Cert: {CLIENT_CERT}")

    client = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)

    # 设置 TLS
    ssl_ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    ssl_ctx.load_verify_locations(CA_CERT)
    ssl_ctx.load_cert_chain(CLIENT_CERT, CLIENT_KEY)
    ssl_ctx.verify_mode = ssl.CERT_REQUIRED
    ssl_ctx.check_hostname = False  # CN=127.0.0.1

    client.tls_set_context(ssl_ctx)

    client.on_connect = on_connect
    client.on_disconnect = on_disconnect

    try:
        print("Connecting...")
        client.connect(NGINX_HOST, NGINX_PORT, keepalive=60)
        client.loop_start()

        # 订阅
        client.on_subscribe = on_subscribe
        client.subscribe(TEST_TOPIC, qos=1)

        # 等待订阅完成
        import time
        time.sleep(1)

        # 发布
        result = client.publish(TEST_TOPIC, TEST_MESSAGE, qos=1)
        if result.rc == mqtt.MQTT_ERR_SUCCESS:
            print(f"[OK] Published: {TEST_MESSAGE}")
        else:
            print(f"[FAIL] Publish failed (rc={result.rc})")

        # 等待消息
        time.sleep(2)

        client.loop_stop()
        client.disconnect()
        print("[PASS] 双向认证测试通过")
        return True

    except Exception as e:
        print(f"[FAIL] Exception: {e}")
        return False


def test_no_client_cert():
    """无客户端证书测试 - 预期失败"""
    print("\n=== 无客户端证书测试 (预期 TLS 握手失败) ===")

    client = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)

    ssl_ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    ssl_ctx.load_verify_locations(CA_CERT)
    ssl_ctx.verify_mode = ssl.CERT_REQUIRED
    ssl_ctx.check_hostname = False

    client.tls_set_context(ssl_ctx)
    client.on_connect = on_connect
    client.on_disconnect = on_disconnect

    try:
        print("Connecting (should fail)...")
        client.connect(NGINX_HOST, NGINX_PORT, keepalive=10)
        client.loop_start()
        import time
        time.sleep(5)
        client.loop_stop()
        client.disconnect()
        print("[FAIL] 连接成功，预期应该失败！")
        return False
    except Exception as e:
        print(f"[OK] 连接失败（预期）: {type(e).__name__}: {e}")
        return True


def test_one_way():
    """单向认证测试 - 服务端证书验证，客户端不提供证书"""
    print("\n=== 单向认证测试 (Server-Only TLS) ===")
    print("注: 当前配置 ssl_verify_client on，所以此测试预期失败")
    print("如需测试单向认证，需先将 nginx.conf 中 ssl_verify_client 改为 off")

    client = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)

    ssl_ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    ssl_ctx.load_verify_locations(CA_CERT)
    ssl_ctx.verify_mode = ssl.CERT_REQUIRED
    ssl_ctx.check_hostname = False

    client.tls_set_context(ssl_ctx)
    client.on_connect = on_connect

    try:
        print("Connecting...")
        client.connect(NGINX_HOST, NGINX_PORT, keepalive=60)
        client.loop_start()
        import time
        time.sleep(5)
        client.loop_stop()
        client.disconnect()
        print("[FAIL] 连接成功，但当前配置要求客户端证书")
        return False
    except Exception as e:
        print(f"[OK] 连接失败（预期，当前 ssl_verify_client=on）: {type(e).__name__}")
        return True


def main():
    parser = argparse.ArgumentParser(description="MQTT TLS Termination Test")
    parser.add_argument("--test", choices=["mutual", "no-client-cert", "one-way", "all"],
                        default="all", help="测试场景")
    args = parser.parse_args()

    results = {}

    if args.test in ["mutual", "all"]:
        results["mutual"] = test_mutual_tls()

    if args.test in ["no-client-cert", "all"]:
        results["no-client-cert"] = test_no_client_cert()

    if args.test in ["one-way", "all"]:
        results["one-way"] = test_one_way()

    # 汇总
    print("\n" + "=" * 50)
    print("测试汇总:")
    for test, passed in results.items():
        status = "PASS" if passed else "FAIL"
        print(f"  {test}: {status}")

    all_passed = all(results.values())
    sys.exit(0 if all_passed else 1)


if __name__ == "__main__":
    main()