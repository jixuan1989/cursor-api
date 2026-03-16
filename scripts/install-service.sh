#!/bin/bash

# Cursor API 用户服务安装脚本

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_NAME="cursor-api"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

echo "=========================================="
echo "  Cursor API 服务安装脚本"
echo "=========================================="
echo ""

# 检查是否已构建 release 版本
if [ ! -f "$PROJECT_DIR/target/release/cursor-api" ]; then
    echo "未找到 release 版本，正在构建..."
    echo ""
    cd "$PROJECT_DIR"
    cargo build --release
    echo ""
fi

# 检查 .env 文件
if [ ! -f "$PROJECT_DIR/.env" ]; then
    echo "警告: 未找到 .env 文件"
    echo "请从 .env.example 复制并配置："
    echo "  cp $PROJECT_DIR/.env.example $PROJECT_DIR/.env"
    echo "  然后编辑 $PROJECT_DIR/.env 设置 AUTH_TOKEN"
    echo ""
    read -p "是否继续安装? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 创建 systemd 用户目录
echo "创建 systemd 用户服务目录..."
mkdir -p "$SYSTEMD_USER_DIR"

# 复制服务文件
echo "安装服务文件..."
cp "$PROJECT_DIR/scripts/cursor-api.service" "$SYSTEMD_USER_DIR/"

# 替换服务文件中的路径
sed -i "s|%h/codes/cursor-api|$PROJECT_DIR|g" "$SYSTEMD_USER_DIR/cursor-api.service"

# 重新加载 systemd 配置
echo "重新加载 systemd 配置..."
systemctl --user daemon-reload

# 启用服务（开机自启）
echo "启用开机自启..."
systemctl --user enable "$SERVICE_NAME"

# 启用 lingering（用户未登录时也能运行服务）
echo "启用用户 lingering..."
loginctl enable-linger "$USER" 2>/dev/null || echo "警告: 无法启用 lingering (可能需要 sudo 权限)"

echo ""
echo "=========================================="
echo "  安装完成!"
echo "=========================================="
echo ""
echo "常用命令："
echo "  启动服务:    systemctl --user start $SERVICE_NAME"
echo "  停止服务:    systemctl --user stop $SERVICE_NAME"
echo "  重启服务:    systemctl --user restart $SERVICE_NAME"
echo "  查看状态:    systemctl --user status $SERVICE_NAME"
echo "  查看日志:    journalctl --user -u $SERVICE_NAME -f"
echo "  禁用自启:    systemctl --user disable $SERVICE_NAME"
echo ""
echo "现在可以启动服务了："
echo "  systemctl --user start $SERVICE_NAME"
echo ""
