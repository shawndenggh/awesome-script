#!/bin/bash
# ============================================
# Self-Hosted Runner 环境安装脚本
# 在 runner 机器上运行此脚本安装所有必要工具
# ============================================

set -e

echo "🚀 开始安装 Self-Hosted Runner 依赖..."

# ============================================
# 等待 apt 锁释放的函数
# ============================================
wait_for_apt_lock() {
    local max_wait=300  # 最多等待 300 秒（5分钟）
    local wait_time=0
    
    while fuser /var/lib/apt/lists/lock /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        if [ $wait_time -eq 0 ]; then
            echo "⏳ 检测到 apt 被其他进程占用，等待锁释放..."
        fi
        
        if [ $wait_time -ge $max_wait ]; then
            echo "❌ 等待超时，apt 锁仍被占用"
            echo "   请手动检查: sudo lsof /var/lib/dpkg/lock-frontend"
            exit 1
        fi
        
        sleep 5
        wait_time=$((wait_time + 5))
        echo "   已等待 ${wait_time}s..."
    done
    
    if [ $wait_time -gt 0 ]; then
        echo "✅ apt 锁已释放，继续安装..."
    fi
}

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ 无法检测操作系统"
    exit 1
fi

echo "📦 检测到操作系统: $OS"

# ============================================
# Ubuntu/Debian 安装
# ============================================
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    echo "📦 更新包管理器..."
    wait_for_apt_lock
    sudo apt-get update

    echo "📦 安装基础构建工具..."
    wait_for_apt_lock
    sudo apt-get install -y \
        make \
        build-essential \
        curl \
        wget \
        git \
        unzip \
        zip \
        tar \
        gzip \
        jq \
        ca-certificates \
        gnupg \
        lsb-release

    echo "🐳 安装 Docker..."
    # 移除旧版本
    wait_for_apt_lock
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # 添加 Docker 官方 GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # 添加 Docker 仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    wait_for_apt_lock
    sudo apt-get update
    wait_for_apt_lock
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ============================================
# CentOS/RHEL/Fedora 安装
# ============================================
elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ] || [ "$OS" = "fedora" ]; then
    echo "📦 安装基础构建工具..."
    sudo yum install -y \
        make \
        gcc \
        curl \
        wget \
        git \
        unzip \
        zip \
        tar \
        gzip \
        jq

    echo "🐳 安装 Docker..."
    sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true

    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

else
    echo "❌ 不支持的操作系统: $OS"
    echo "请手动安装: make, docker, unzip, git, curl, jq"
    exit 1
fi

# ============================================
# 配置 Docker
# ============================================
echo "⚙️ 配置 Docker..."

# 启动 Docker 服务
sudo systemctl start docker
sudo systemctl enable docker

# 将当前用户添加到 docker 组（避免每次都用 sudo）
if [ -n "$SUDO_USER" ]; then
    RUNNER_USER=$SUDO_USER
else
    RUNNER_USER=$(whoami)
fi

sudo usermod -aG docker $RUNNER_USER
echo "✅ 已将用户 $RUNNER_USER 添加到 docker 组"

# ============================================
# 验证安装
# ============================================
echo ""
echo "============================================"
echo "🔍 验证安装结果..."
echo "============================================"

echo -n "make: "
make --version | head -1

echo -n "docker: "
docker --version

echo -n "docker compose: "
docker compose version

echo -n "git: "
git --version

echo -n "unzip: "
unzip -v | head -1

echo -n "curl: "
curl --version | head -1

echo -n "jq: "
jq --version

echo ""
echo "============================================"
echo "✅ 所有工具安装完成！"
echo "============================================"
echo ""
echo "⚠️  重要提示："
echo "   1. 请重新登录或运行 'newgrp docker' 使 docker 组生效"
echo "   2. 如果 runner 已经在运行，请重启 runner 服务"
echo ""
