# 部署目录说明

## 存放规范

- **按序号分应用**：`01-xxx`、`02-xxx`… 表示不同应用，序号与 `data/` 下数据目录对应。
- **应用内**：各应用目录含该应用的 `docker-compose.yml`、`README.md` 等。
- **数据路径**：应用数据统一放在项目根下 `data/<序号>-<应用名>/`，参见 [data/README.md](../data/README.md)。

## 目录结构

```
deploy/
├── 00-readme.md           # 本说明（部署规范与索引）
├── 01-gitlab/             # GitLab CE
│   ├── docker-compose.yml
│   └── README.md
├── 02-xxx/                # 其他应用（预留）
└── ...
```

## 当前部署索引

| 序号 | 路径 | 说明 | 数据目录 |
|------|------|------|----------|
| 01 | [01-gitlab/](01-gitlab/) | GitLab CE Docker Compose | `data/01-gitlab/` |

## 使用方式

进入对应应用目录后执行，例如：

```bash
cd deploy/01-gitlab
docker compose up -d
```

依赖检查等脚本见项目根 [README.md](../README.md)。
