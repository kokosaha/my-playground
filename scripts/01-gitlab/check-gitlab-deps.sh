#!/usr/bin/env bash
# 检查 GitLab Docker 部署依赖：Docker、Docker Compose、镜像版本
# 用法: ./scripts/check-gitlab-deps.sh

set -e

GITLAB_IMAGE="${GITLAB_IMAGE:-gitlab/gitlab-ce:17.9.5-ce.0}"
FALLBACK_TAGS="17.9.5-ce.0 17.8.4-ce.0 17.10.3-ce.0"
FAIL=0

echo "========== GitLab Docker 依赖检查 =========="
echo ""

# 1. Docker 已安装且运行
echo "[1] Docker 已安装且运行"
if command -v docker &>/dev/null; then
  if docker info &>/dev/null; then
    echo "    OK  $(docker --version)"
  else
    echo "    FAIL  Docker 未运行或当前用户无权限，请启动 Docker 并重试"
    FAIL=1
  fi
else
  echo "    FAIL  未找到 docker 命令"
  FAIL=1
fi
echo ""

# 2. Docker Compose 可用
echo "[2] Docker Compose 可用"
if docker compose version &>/dev/null; then
  echo "    OK  $(docker compose version --short 2>/dev/null || docker compose version)"
elif command -v docker-compose &>/dev/null && docker-compose version &>/dev/null; then
  echo "    OK  docker-compose $(docker-compose version --short 2>/dev/null || docker-compose version)"
else
  echo "    FAIL  未找到 docker compose 或 docker-compose"
  FAIL=1
fi
echo ""

# 3. 镜像版本是否存在（本地或远程）
echo "[3] 镜像 ${GITLAB_IMAGE}"
if docker image inspect "$GITLAB_IMAGE" &>/dev/null; then
  echo "    OK  已存在本地镜像"
else
  echo "    正在检查远程是否存在该 tag..."
  FOUND=
  for tag in $GITLAB_IMAGE $FALLBACK_TAGS; do
    [ "${tag#*:}" != "$tag" ] && img="$tag" || img="gitlab/gitlab-ce:$tag"
    if docker manifest inspect "$img" &>/dev/null; then
      FOUND="$img"; break
    fi
  done
  if [ -n "$FOUND" ]; then
    echo "    OK  远程存在 $FOUND，拉取后可部署"
  else
    echo "    FAIL  无法验证远程 tag（网络或 Docker 权限？）。可手动: docker pull gitlab/gitlab-ce:17.9.5-ce.0"
    FAIL=1
  fi
fi
echo ""

# 4. 端口占用（可选提示）
echo "[4] 端口占用提示"
for port in 8080 2222; do
  if lsof -i :"$port" &>/dev/null; then
    echo "    注意  端口 $port 可能已被占用"
  fi
done
echo ""

echo "========== 检查结束 =========="
if [ $FAIL -eq 0 ]; then
  echo "依赖满足，可进行部署。确认后执行: cd deploy/01-gitlab && docker compose up -d"
  exit 0
else
  echo "存在未满足项，请修复后再部署。"
  exit 1
fi
