# 01-gitlab：GitLab CE

GitLab CE Docker Compose 部署，数据目录 `data/01-gitlab/`。

## 文档

- `01-backup.md`：备份方案（GitLab 内置备份 / Docker volume 打包）

## 部署

```bash
# 从项目根执行依赖检查（可选）
./scripts/check-gitlab-deps.sh

# 进入本目录并启动
cd deploy/01-gitlab
docker compose up -d
```

## 常用命令

- 查看日志：`docker logs -f gitlab`
- 获取 root 初始密码：`docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password`
- 停止：`docker compose down`

## 访问

- Web：http://localhost:8080
- Git SSH：`ssh://git@localhost:2222/...`（端口 2222）
- Macos tailscale：http://100.114.1.96:8080

详见 [docs/01-gitlab/01-docker-install-plan.md](../../docs/01-gitlab/01-docker-install-plan.md)。
