# 本地 Docker 安装 GitLab 方案

## 一、推荐版本

**GitLab CE 17.11.x**（例如 `gitlab/gitlab-ce:17.11.0-ce.0`）

- 官方持续维护的稳定版，中文（简体）支持完整，界面、文档、错误提示等均可切换为中文。
- 不推荐使用 `latest`，生产/长期使用应固定具体版本便于升级与回滚。

可选替代：若希望更新一些，可用 **18.x** 系列当前稳定 tag（如 `18.0.x-ce.0`），中文支持同样良好。

---

## 二、中文使用说明

- 安装完成后，登录 GitLab → **右上角头像 → Preferences → Localization** → **Language** 选择 **简体中文** 保存即可。
- 仓库名、分支名、提交信息等可随意使用中文；Web 界面、设置、邮件模板等均支持中文。

---

## 三、中国区使用注意点

| 项目 | 说明 |
|------|------|
| **Docker 镜像** | 默认从 Docker Hub 拉取 `gitlab/gitlab-ce`，国内可能较慢。可配置镜像加速（如阿里云、DaoCloud、dockerproxy 等）再 `docker compose pull`。 |
| **时区** | 在 `GITLAB_OMNIBUS_CONFIG` 中设置 `gitlab_rails['time_zone'] = 'Asia/Shanghai'`，保证时间显示正确。 |
| **访问地址** | 本地使用可设 `external_url 'http://localhost'` 或 `http://localhost:8080`（若改端口）。 |

---

## 四、目录与 Compose 设计（本仓库）

- **数据目录**：`data/01-gitlab/`，下分 `config`、`logs`、`data`，与 `deploy/01-gitlab/` 一一对应。
- **部署配置**：`deploy/01-gitlab/docker-compose.yml`，volumes 挂载 `../../data/01-gitlab/...`。
- **端口**：主机 SSH 若占用 22，GitLab 的 Git SSH 改用 2222，Web 使用 8080。

---

## 五、docker-compose.yml 要点

- **image**：`gitlab/gitlab-ce:17.9.5-ce.0`（本仓库已采用）。
- **environment**：`GITLAB_OMNIBUS_CONFIG` 内配置：
  - `external_url`、`gitlab_rails['time_zone'] = 'Asia/Shanghai'`
  - `gitlab_rails['gitlab_shell_ssh_port'] = 2222`
- **ports**：8080（Web）、2222（Git SSH）。
- **volumes**：挂载 `data/01-gitlab/{config,logs,data}`。
- **restart**：`always`；**shm_size**：`256m`。

---

## 六、安装与初始化流程

1. 执行 `./scripts/check-gitlab-deps.sh` 检查依赖（建议本地终端）。
2. `cd deploy/01-gitlab`，执行 `docker compose up -d`，等待容器就绪（首次启动可能数分钟）。
3. 查看 root 初始密码：  
   `docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password`
4. 浏览器访问 `http://localhost:8080`，用 `root` 与上述密码登录。
5. 在 **Preferences → Localization** 中切换为 **简体中文**。

---

## 七、资源配置建议

- **最低**：4 核 CPU、4GB RAM、20GB 磁盘。
- **推荐**：4 核+、8GB RAM、50GB+ 磁盘，以保证顺畅使用。

---

## 八、本仓库已提供

1. `deploy/01-gitlab/docker-compose.yml`：即用配置（时区、端口、卷）。
2. `deploy/01-gitlab/README.md`：启动、取 root 密码、访问地址等步骤。
3. `scripts/check-gitlab-deps.sh`：部署前依赖检查。

如需区分 Mac / Windows 的路径或端口细节，可修改 `deploy/01-gitlab/docker-compose.yml` 与 `data/01-gitlab` 挂载路径。
