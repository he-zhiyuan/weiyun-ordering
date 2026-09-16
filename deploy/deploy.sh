#!/bin/bash
# 部署脚本模板。必须安装在仓库目录之外，例如 /opt/deploy/deploy.sh，
# 因为它会被 authorized_keys 的 command= 限制直接执行（见 DEPLOYMENT.md），
# 放进 /opt/weiyun-ordering 里会有被 git pull / git clean 误清理的风险。
#
# ~/.ssh/github_deploy_ro 是一把只读的、只允许 git clone/pull 该仓库的 deploy key
# (GitHub 仓库 Settings -> Deploy keys 里添加，不勾选 Write access)，
# 与触发这个脚本本身的 GitHub Actions SSH key 是两把不同的、用途不同的密钥。
set -e

REPO_DIR=/opt/weiyun-ordering
export GIT_SSH_COMMAND="ssh -i ~/.ssh/github_deploy_ro -o IdentitiesOnly=yes"

echo "==> Pulling latest code"
git -C "$REPO_DIR" pull --ff-only origin main

echo "==> Building backend"
cd "$REPO_DIR"
mvn -q -DskipTests package
sudo systemctl restart weiyun-server

echo "==> Building admin frontend"
cd "$REPO_DIR/weiyun-web-admin"
npm ci --legacy-peer-deps
NODE_OPTIONS=--openssl-legacy-provider npm run build
sudo mkdir -p /var/www/weiyun-admin
sudo rsync -a --delete dist/ /var/www/weiyun-admin/

echo "==> Building user frontend"
cd "$REPO_DIR/weiyun-web-user"
npm ci --legacy-peer-deps
npm run build
sudo mkdir -p /var/www/weiyun-user
sudo rsync -a --delete dist/ /var/www/weiyun-user/

echo "==> Reloading nginx"
sudo systemctl reload nginx

echo "==> Deploy finished"
