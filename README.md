# my-playground

本地实验与部署脚本仓库。含 GitLab Docker 方案、部署配置与检查脚本。

## 目录结构

```
├── data/                    # 应用数据（按序号）
│   ├── README.md
│   └── 01-gitlab/           # GitLab config、logs、data
├── deploy/                  # 部署配置（按序号分应用）
│   ├── 00-readme.md         # 部署规范与索引
│   └── 01-gitlab/           # GitLab CE
│       ├── docker-compose.yml
│       └── README.md
├── docs/                    # 文档（按序号分主题）
│   ├── 00-readme.md
│   └── 01-gitlab/
│       └── 01-docker-install-plan.md
├── scripts/                 # 脚本
│   ├── README.md
│   └── check-gitlab-deps.sh
└── README.md
```

## GitLab Docker 部署

1. **依赖检查**（需本机 Docker 已启动，建议在本地终端执行）：
   ```bash
   ./scripts/check-gitlab-deps.sh
   ```
2. **确认通过后**部署：
   ```bash
   cd deploy/01-gitlab
   docker compose up -d
   ```
3. 详见 [docs/01-gitlab/01-docker-install-plan.md](docs/01-gitlab/01-docker-install-plan.md)、[deploy/01-gitlab/README.md](deploy/01-gitlab/README.md)。

## Git 仓库

若尚未初始化：

```bash
git init
```

再将 `data/`、`deploy/`、`docs/`、`scripts/` 等纳入版本管理。
