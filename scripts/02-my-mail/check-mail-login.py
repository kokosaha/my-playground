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
