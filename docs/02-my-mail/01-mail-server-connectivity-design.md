# 邮件服务器连通性与登录测试方案设计

## 一、目标

在配置邮件客户端前，确认：

1. **网络连通**：IMAP、POP3、SMTP 的地址与端口是否可达；
2. **协议与 TLS**：端口是否按预期提供 IMAP/POP3/SMTP 服务，是否使用 SSL/TLS；
3. **登录可用**：使用你提供的「客户端专用密码」能否成功认证（IMAP 登录、POP3 登录、SMTP 认证）。

测试通过后再在客户端中填写相同地址、端口与密码，可避免反复试错。

---

## 二、本次测试的服务器与账号信息

> **安全提示**：下文含真实密码。若仓库会推送到公共或共享环境，请勿提交本文档，或将「账号与密码」整段移至 `.env`（已加入 `.gitignore`）后再提交。

| 项目 | 取值 |
|------|------|
| **收信（IMAP）** | `imap.csrzic.com`，SSL 端口 **993**，非 SSL 端口 143 |
| **收信（POP3）** | `pop.csrzic.com`，SSL 端口 **995**，非 SSL 端口 110 |
| **发信（SMTP）** | `smtp.csrzic.com`，SSL 端口 **465**，非 SSL 端口 25 |
| **收发件地址** | 可能为以下其一，测试时分别尝试：`yejingtian@csrzic.com`、`20251013@csrzic.com` |
| **客户端专用密码** | `2gUff7BFUEmY7qbG` |

建议测试时优先使用 SSL 端口（993 / 995 / 465），与常见邮件客户端配置一致。

---

## 三、本次测试执行步骤（csrzic 可直接执行）

以下命令按「端口 → TLS → 登录」顺序执行，可直接复制到终端运行（登录步骤需先设置环境变量中的邮箱与密码）。

### Layer 1：端口连通

```bash
nc -zv -w 5 imap.csrzic.com 993
nc -zv -w 5 pop.csrzic.com  995
nc -zv -w 5 smtp.csrzic.com 465
```

### Layer 2：协议与 TLS

```bash
openssl s_client -connect imap.csrzic.com:993 -servername imap.csrzic.com -brief </dev/null
openssl s_client -connect pop.csrzic.com:995  -servername pop.csrzic.com  -brief </dev/null
openssl s_client -connect smtp.csrzic.com:465 -servername smtp.csrzic.com -brief </dev/null
```

### Layer 3：登录认证

先设置环境变量（`MAIL_USER` 取其一：`yejingtian@csrzic.com` 或 `20251013@csrzic.com`，不确定时可分别试一次）：

```bash
export MAIL_USER="yejingtian@csrzic.com"   # 或 20251013@csrzic.com
export MAIL_PASSWORD="2gUff7BFUEmY7qbG"
```

再运行 Python 检查脚本（见下一节「四、Layer 3 检查脚本」），或使用一次性命令验证 IMAP 登录：

```bash
python3 -c "
import imaplib, os
c = imaplib.IMAP4_SSL('imap.csrzic.com', 993)
c.login(os.environ['MAIL_USER'], os.environ['MAIL_PASSWORD'])
print('IMAP 登录成功')
c.logout()
"
```

POP3、SMTP 的类似命令见下方脚本。

---

## 四、Layer 3 检查脚本（可选）

将以下内容保存为 `scripts/02-my-mail/check-mail-login.py`，在项目根目录执行：  
`MAIL_USER=yejingtian@csrzic.com MAIL_PASSWORD=2gUff7BFUEmY7qbG python3 scripts/02-my-mail/check-mail-login.py`（若失败可改用 `MAIL_USER=20251013@csrzic.com` 再试）

```python
#!/usr/bin/env python3
"""检查 IMAP/POP3/SMTP 登录（从环境变量读取 MAIL_USER、MAIL_PASSWORD）。"""
import os
import sys

def main():
    user = os.environ.get("MAIL_USER", "").strip()
    password = os.environ.get("MAIL_PASSWORD", "")
    if not user or not password:
        print("请设置环境变量 MAIL_USER 和 MAIL_PASSWORD", file=sys.stderr)
        sys.exit(1)

    # IMAP
    try:
        import imaplib
        c = imaplib.IMAP4_SSL("imap.csrzic.com", 993)
        c.login(user, password)
        c.logout()
        print("IMAP 登录成功")
    except Exception as e:
        print("IMAP 登录失败:", e)
        sys.exit(1)

    # POP3
    try:
        import poplib
        c = poplib.POP3_SSL("pop.csrzic.com", 995)
        c.user(user)
        c.pass_(password)
        c.quit()
        print("POP3 登录成功")
    except Exception as e:
        print("POP3 登录失败:", e)
        sys.exit(1)

    # SMTP
    try:
        import smtplib
        c = smtplib.SMTP_SSL("smtp.csrzic.com", 465)
        c.login(user, password)
        c.quit()
        print("SMTP 认证成功")
    except Exception as e:
        print("SMTP 认证失败:", e)
        sys.exit(1)

if __name__ == "__main__":
    main()
```

---

## 五、前置信息（通用说明）

以下为通用说明，其他邮箱服务商可参考。

| 项目 | 说明 | 示例 |
|------|------|------|
| IMAP 服务器 | 地址 + 端口（如 993 为 IMAPS） | `imap.example.com:993` |
| POP3 服务器 | 地址 + 端口（如 995 为 POP3S） | `pop.example.com:995` |
| SMTP 服务器 | 地址 + 端口（如 465/587） | `smtp.example.com:465` 或 `:587` |
| 邮箱账号 | 完整邮箱或用户名 | `you@example.com` |
| 客户端专用密码 | 建议通过环境变量传入，不写进仓库 | `MAIL_PASSWORD` |

若使用 STARTTLS（先明文再升级），需明确端口（常见 IMAP 143、POP3 110、SMTP 587）。

---

## 六、测试层次

建议按「端口 → 协议握手 → 登录」三层依次测，便于定位问题。

```
┌─────────────────────────────────────────────────────────┐
│  Layer 1: 端口连通（nc / telnet）                         │
│  → 确认地址、端口可达，无防火墙/网络阻断                    │
└─────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────┐
│  Layer 2: 协议与 TLS（openssl s_client）                 │
│  → 确认端口返回 IMAP/POP3/SMTP 欢迎信息，TLS 握手正常     │
└─────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────┐
│  Layer 3: 登录认证（脚本：Python imaplib/poplib/smtplib）│
│  → 使用账号 + 客户端专用密码，验证 IMAP/POP3/SMTP 登录     │
└─────────────────────────────────────────────────────────┘
```

---

## 七、Layer 1：端口连通测试（说明）

**目的**：确认本机到各服务器地址、端口的 TCP 是否可达。

**命令示例**（将 `HOST`、`PORT` 换成你的 IMAP/POP3/SMTP 地址与端口）：

```bash
# 方式一：nc（推荐）
nc -zv IMAP_HOST IMAP_PORT    # 例如 nc -zv imap.example.com 993
nc -zv POP3_HOST POP3_PORT    # 例如 nc -zv pop.example.com 995
nc -zv SMTP_HOST SMTP_PORT    # 例如 nc -zv smtp.example.com 465

# 方式二：超时 5 秒，避免长时间挂起
nc -zv -w 5 IMAP_HOST IMAP_PORT
```

**结果判断**：

- 输出含 `succeeded` 或 `open` → 端口可达；
- `Connection refused` → 端口未开放或防火墙拒绝；
- `Timeout` / 无输出 → 网络不通或中间设备阻断。

---

## 八、Layer 2：协议与 TLS 测试（说明）

**目的**：确认端口上跑的是 IMAP/POP3/SMTP，且 TLS 握手正常（适用于 993/995/465 等隐式 SSL 端口）。

**命令示例**（以 IMAP 993 为例，POP3/SMTP 仅改端口与 `-connect`）：

```bash
# IMAP（常见 993）
openssl s_client -connect IMAP_HOST:IMAP_PORT -servername IMAP_HOST -brief </dev/null

# POP3（常见 995）
openssl s_client -connect POP3_HOST:POP3_PORT -servername POP3_HOST -brief </dev/null

# SMTP（常见 465 或 587；587 多为 STARTTLS，见下）
openssl s_client -connect SMTP_HOST:SMTP_PORT -servername SMTP_HOST -brief </dev/null
```

**结果判断**：

- 能建立连接并看到证书/握手信息 → 该端口 TLS 正常；
- 若端口为 587（STARTTLS），可先裸连接再发 `STARTTLS`，或直接用脚本在 Layer 3 测。

---

## 九、Layer 3：登录认证测试（说明）

**目的**：使用你的「邮箱账号 + 客户端专用密码」实际执行 IMAP 登录、POP3 登录、SMTP 认证，确认服务器允许该密码。

**推荐方式**：用 Python 的 `imaplib`、`poplib`、`smtplib` 写一个小脚本，从环境变量读取密码（例如 `MAIL_PASSWORD`），不把密码写进代码或仓库。

**脚本逻辑概要**：

1. **IMAP 登录**  
   - 连接：`imaplib.IMAP4_SSL(host, port)` 或先 `IMAP4` 再 `.starttls()`（视端口而定）。  
   - 登录：`.login(user, password)`。  
   - 成功则视为 IMAP 可达且可登录。

2. **POP3 登录**  
   - 连接：`poplib.POP3_SSL(host, port)` 或先 `POP3` 再 `.stls()`。  
   - 登录：`.user(user)`、`.pass_(password)`。  
   - 成功则视为 POP3 可达且可登录。

3. **SMTP 认证**  
   - 连接：`smtplib.SMTP_SSL(host, port)` 或 `SMTP` + `starttls()`（如 587）。  
   - 登录：`.login(user, password)`。  
   - 成功则视为 SMTP 可达且认证通过。

**安全约定**：

- 密码只从环境变量读取（如 `os.environ['MAIL_PASSWORD']`）；
- 不在文档、脚本或提交记录中写真实密码；
- 若使用 `.env`，将 `.env` 加入 `.gitignore`。

---

## 十、实施顺序建议

1. **你先提供**：IMAP/POP3/SMTP 的地址与端口（以及是否为 SSL/STARTTLS），无需在文档里写密码。
2. **执行 Layer 1**：在本地终端对上述地址和端口执行 `nc -zv`，确认端口均可达。
3. **执行 Layer 2**：对 993/995/465（及需测的 587）执行 `openssl s_client`，确认协议与 TLS 正常。
4. **编写/运行 Layer 3 脚本**：从环境变量读取账号与客户端专用密码，依次测 IMAP、POP3、SMTP 登录；全部通过后再在邮件客户端中配置相同参数。

---

## 十一、可选：检查脚本与文档索引

- 可将上述三层测试整理为一个脚本（如 `scripts/02-my-mail/check-mail-server.sh` 或 Python 版），通过参数或环境变量传入地址、端口、账号，密码仅通过环境变量传入。
- 在 `docs/00-readme.md` 的「当前文档索引」中增加本方案条目，便于后续查阅。

---

## 十二、后续可补充

若更换邮箱或服务器，只需更新「二、本次测试的服务器与账号信息」中的表格，并相应修改第三节中的主机名、端口及脚本中的常量。
