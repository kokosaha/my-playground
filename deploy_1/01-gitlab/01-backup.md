# 01-backup：GitLab 备份方案（Docker named volumes）

适用前提：当前部署采用 **Docker named volumes**（`gitlab_config`、`gitlab_logs`、`gitlab_data`）。

## 方案A：GitLab 内置备份（推荐，易迁移/易恢复）

### 备份内容

- **应用数据备份包**：通过 `gitlab-backup` 生成（默认在 `/var/opt/gitlab/backups/`）
- **关键配置与密钥**（必须备份，否则恢复后可能出现 token/加密数据不可用）：
  - `/etc/gitlab/gitlab.rb`
  - `/etc/gitlab/gitlab-secrets.json`

### 备份步骤

1. 生成备份包：

```bash
docker exec -t gitlab gitlab-backup create
```

2. 查看备份文件（确认生成成功）：

```bash
docker exec -t gitlab ls -lh /var/opt/gitlab/backups
```

3. 拷贝备份包到宿主机目录：

```bash
mkdir -p ./gitlab-backups
docker cp gitlab:/var/opt/gitlab/backups ./gitlab-backups
```

4. 拷贝配置与密钥到宿主机目录：

```bash
mkdir -p ./gitlab-config-backup
docker cp gitlab:/etc/gitlab/gitlab.rb ./gitlab-config-backup/
docker cp gitlab:/etc/gitlab/gitlab-secrets.json ./gitlab-config-backup/
```

### 备份产物建议

- `gitlab-backups/*.tar`（或目录下的备份文件）
- `gitlab-config-backup/gitlab.rb`
- `gitlab-config-backup/gitlab-secrets.json`

---

## 方案B：Docker Volume 打包备份（兜底，整卷快照）

特点：直接把 Docker volume 打成 tar 包；适合做“整库快照/兜底”，但可移植性和可控性不如方案A。

### 1) 确认卷名称

> Docker Compose 可能会给 volume 加前缀（与项目名有关）。先列出并确认实际名称。

```bash
docker volume ls | grep gitlab
```

### 2) 打包备份（示例：gitlab_data）

```bash
mkdir -p ./volume-backup

docker run --rm \
  -v gitlab_data:/volume \
  -v "$PWD/volume-backup":/backup \
  alpine sh -c "cd /volume && tar -czf /backup/gitlab_data.tgz ."
```

对 `gitlab_config`、`gitlab_logs` 同样执行一次（`logs` 可选）。

### 3) 备份产物

- `volume-backup/gitlab_data.tgz`
- （可选）`volume-backup/gitlab_config.tgz`
- （可选）`volume-backup/gitlab_logs.tgz`

---

## 推荐策略

- **日常备份/迁移/恢复**：优先使用 **方案A**
- **兜底快照**：在方案A基础上增加 **方案B**（尤其在升级前）

