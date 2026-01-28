# 应用数据目录

按序号存放各应用持久化数据，与 `deploy/` 中部署配置一一对应。

| 序号 | 路径 | 说明 |
|------|------|------|
| 01 | `01-gitlab/` | GitLab CE 的 config、logs、data |

- `config`：配置
- `logs`：日志
- `data`：业务数据（库、仓库等）

数据目录已加入 `.gitignore`，仅保留空目录结构（`.gitkeep`）入库。
