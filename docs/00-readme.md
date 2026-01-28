# 文档目录说明

## 存放规范

- **按序号分主题**：`01-xxx`、`02-xxx`… 表示不同主题，序号递增便于排序与扩展。
- **主题内按序号**：各主题目录下 `01-xxx.md`、`02-xxx.md`… 表示该主题内的文档顺序。
- **命名**：`序号-简短描述.md`，使用小写、连字符。

## 目录结构

```
docs/
├── 00-readme.md           # 本说明（文档规范与索引）
├── 01-gitlab/             # GitLab 相关
│   ├── 01-docker-install-plan.md
│   └── ...
├── 02-xxx/                # 其他主题（预留）
└── ...
```

## 当前文档索引

| 序号 | 路径 | 说明 |
|------|------|------|
| 01 | [01-gitlab/01-docker-install-plan.md](01-gitlab/01-docker-install-plan.md) | GitLab Docker 安装方案（本地、中文、中国区） |

## 脚本与部署

- 依赖检查：`./scripts/check-gitlab-deps.sh`（**请在本地终端执行**，Cursor 集成终端可能无法访问 Docker/网络）
- 部署配置：`deploy/01-gitlab/`（参见 [deploy/00-readme.md](../deploy/00-readme.md)）
