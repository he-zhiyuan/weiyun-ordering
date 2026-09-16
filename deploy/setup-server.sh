#!/bin/bash
# 新服务器一次性初始化脚本。适用于全新的 Ubuntu 20.04/22.04 服务器。
# 用法：把本文件 scp 到服务器，然后 sudo bash setup-server.sh
#
# 这个脚本只负责"把环境和骨架搭起来"，不会启动后端服务——因为此时
# /etc/sky-take-out/server.env 里还是空占位符，直接启动一定会崩。
# 脚本跑完后，照着结尾打印的清单继续手动操作。
set -e

REPO_URL="https://github.com/he-zhiyuan/weiyun-ordering.git"
REPO_DIR=/opt/weiyun-ordering
DEPLOY_SCRIPT_DIR=/opt/deploy

echo "==> 安装基础软件：git, rsync, nginx, openjdk-17, maven"
sudo apt-get update
sudo apt-get install -y git rsync nginx openjdk-17-jdk maven curl

echo "==> 安装 Node.js 20 LTS (NodeSource)"
if ! command -v node >/dev/null 2>&1 || [ "$(node -v | cut -d. -f1 | tr -d v)" -lt 20 ]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

echo "==> 创建 2GB swap（如果还没有）"
if [ "$(swapon --show | wc -l)" -eq 0 ]; then
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

echo "==> 准备 /etc/sky-take-out/server.env（模板，需要手动填真实值）"
sudo mkdir -p /etc/sky-take-out
if [ ! -f /etc/sky-take-out/server.env ]; then
    sudo cp "$(dirname "$0")/server.env.example" /etc/sky-take-out/server.env
    sudo chmod 600 /etc/sky-take-out/server.env
fi

echo "==> clone 代码仓库到 $REPO_DIR"
if [ ! -d "$REPO_DIR" ]; then
    sudo git clone "$REPO_URL" "$REPO_DIR"
    sudo chown -R "$(whoami)" "$REPO_DIR"
fi

echo "==> 安装 systemd 单元"
sudo cp "$REPO_DIR/deploy/weiyun-server.service" /etc/systemd/system/weiyun-server.service
sudo systemctl daemon-reload
sudo systemctl enable weiyun-server

echo "==> 安装 nginx 站点配置"
sudo cp "$REPO_DIR/deploy/nginx-weiyun-user.conf" /etc/nginx/sites-available/weiyun-user
sudo cp "$REPO_DIR/deploy/nginx-weiyun-admin.conf" /etc/nginx/sites-available/weiyun-admin
sudo ln -sf /etc/nginx/sites-available/weiyun-user /etc/nginx/sites-enabled/weiyun-user
sudo ln -sf /etc/nginx/sites-available/weiyun-admin /etc/nginx/sites-enabled/weiyun-admin
# 默认的 nginx 欢迎页站点会和我们的 default_server 冲突，禁用掉
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t

echo "==> 准备部署脚本目录 $DEPLOY_SCRIPT_DIR（放在仓库目录之外，不受 git pull/clean 影响）"
sudo mkdir -p "$DEPLOY_SCRIPT_DIR"
sudo cp "$REPO_DIR/deploy/deploy.sh" "$DEPLOY_SCRIPT_DIR/deploy.sh"
sudo chmod +x "$DEPLOY_SCRIPT_DIR/deploy.sh"

cat <<'EOF'

========================================================
环境骨架已搭建完成。接下来还需要手动完成（不可自动化的部分）：

1. 确认 MySQL / Redis 已安装并已建好数据库（本脚本不负责数据库/Redis 安装）。

2. 编辑 /etc/sky-take-out/server.env，填入真实的数据库/Redis连接信息
   （阿里云OSS/微信支付两组变量可选，留空即可）。

3. 给 GitHub 只读部署密钥（用于 deploy.sh 里 git pull，与下面第4步的密钥不同）：
     ssh-keygen -t ed25519 -f ~/.ssh/github_deploy_ro -N ""
   把公钥内容加到 GitHub 仓库 Settings -> Deploy keys（不要勾选 Write access）。

4. 生成 GitHub Actions 触发部署专用密钥（与第3步用途不同，这把是"谁能触发部署"）：
     ssh-keygen -t ed25519 -f /tmp/deploy_trigger -N ""
   把公钥追加进本机 ~/.ssh/authorized_keys，并加上 command= 限制，例如：
     command="/opt/deploy/deploy.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAA... deploy@github-actions
   私钥内容写入 GitHub 仓库 Secrets: DEPLOY_SSH_KEY
   同时设置 Secrets: DEPLOY_HOST=<本机公网IP>, DEPLOY_USER=<本机登录用户名>
   用完把 /tmp/deploy_trigger* 删除。

5. 手动跑一次部署脚本验证全链路：
     bash /opt/deploy/deploy.sh
   跑完检查: systemctl status weiyun-server

6. 之后每次 git push 到 main 分支，GitHub Actions 会自动 SSH 过来触发 /opt/deploy/deploy.sh。

详细说明见仓库根目录 DEPLOYMENT.md。
========================================================
EOF
