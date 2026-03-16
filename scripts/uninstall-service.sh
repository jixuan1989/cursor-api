#!/bin/bash

# Cursor API 用户服务卸载脚本

set -e

SERVICE_NAME="cursor-api"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

echo "=========================================="
echo "  Cursor API 服务卸载脚本"
echo "=========================================="
echo ""

# 停止服务
echo "停止服务..."
systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true

# 禁用服务
echo "禁用开机自启..."
systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true

# 删除服务文件
echo "删除服务文件..."
rm -f "$SYSTEMD_USER_DIR/cursor-api.service"

# 重新加载 systemd 配置
echo "重新加载 systemd 配置..."
systemctl --user daemon-reload
systemctl --user reset-failed 2>/dev/null || true

echo ""
echo "=========================================="
echo "  卸载完成!"
echo "=========================================="
echo ""
