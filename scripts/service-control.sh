#!/bin/bash

# Cursor API 服务控制脚本

SERVICE_NAME="cursor-api"

case "${1:-status}" in
    start)
        echo "启动服务..."
        systemctl --user start "$SERVICE_NAME"
        systemctl --user status "$SERVICE_NAME" --no-pager
        ;;
    stop)
        echo "停止服务..."
        systemctl --user stop "$SERVICE_NAME"
        ;;
    restart)
        echo "重启服务..."
        systemctl --user restart "$SERVICE_NAME"
        systemctl --user status "$SERVICE_NAME" --no-pager
        ;;
    status)
        systemctl --user status "$SERVICE_NAME" --no-pager
        ;;
    logs)
        journalctl --user -u "$SERVICE_NAME -f"
        ;;
    enable)
        echo "启用开机自启..."
        systemctl --user enable "$SERVICE_NAME"
        ;;
    disable)
        echo "禁用开机自启..."
        systemctl --user disable "$SERVICE_NAME"
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|logs|enable|disable}"
        echo ""
        echo "命令说明:"
        echo "  start    - 启动服务"
        echo "  stop     - 停止服务"
        echo "  restart  - 重启服务"
        echo "  status   - 查看状态 (默认)"
        echo "  logs     - 查看日志"
        echo "  enable   - 启用开机自启"
        echo "  disable  - 禁用开机自启"
        exit 1
        ;;
esac
