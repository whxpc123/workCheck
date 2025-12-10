#!/bin/bash

# ========================================
# WorkCheck 服务管理脚本
# 用于注册为系统服务
# ========================================

SERVICE_NAME="workcheck"
SERVICE_DESC="WorkCheck Backend Service"
USER=$(whoami)
APP_HOME="/Users/xpc/Documents/workCheck/workcheck-backend"
PID_FILE="$APP_HOME/application.pid"
LOG_FILE="$APP_HOME/logs/application.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 安装服务（systemd）
install_service_systemd() {
    print_info "创建systemd服务文件..."

    sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null <<EOF
[Unit]
Description=${SERVICE_DESC}
After=network.target

[Service]
Type=forking
User=${USER}
WorkingDirectory=${APP_HOME}
ExecStart=${APP_HOME}/start.sh start
ExecStop=${APP_HOME}/start.sh stop
ExecReload=${APP_HOME}/start.sh restart
PIDFile=${PID_FILE}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable ${SERVICE_NAME}
    print_info "服务安装完成！"
    print_info "使用命令："
    print_info "  sudo systemctl start ${SERVICE_NAME}    # 启动服务"
    print_info "  sudo systemctl stop ${SERVICE_NAME}     # 停止服务"
    print_info "  sudo systemctl status ${SERVICE_NAME}   # 查看状态"
    print_info "  sudo systemctl logs ${SERVICE_NAME}     # 查看日志"
}

# 安装服务（launchd - macOS）
install_service_launchd() {
    print_info "创建launchd服务文件..."

    PLIST_FILE="$HOME/Library/LaunchAgents/com.workcheck.backend.plist"

    cat > ${PLIST_FILE} <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.workcheck.backend</string>
    <key>ProgramArguments</key>
    <array>
        <string>${APP_HOME}/start.sh</string>
        <string>start</string>
    </array>
    <key>WorkingDirectory</key>
    <string>${APP_HOME}</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${LOG_FILE}</string>
    <key>StandardErrorPath</key>
    <string>${LOG_FILE}</string>
</dict>
</plist>
EOF

    launchctl load ${PLIST_FILE}
    print_info "服务安装完成！"
    print_info "使用命令："
    print_info "  launchctl start com.workcheck.backend  # 启动服务"
    print_info "  launchctl stop com.workcheck.backend   # 停止服务"
    print_info "  launchctl list | grep workcheck        # 查看状态"
}

# 卸载服务
uninstall_service() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        PLIST_FILE="$HOME/Library/LaunchAgents/com.workcheck.backend.plist"
        if [ -f "$PLIST_FILE" ]; then
            launchctl unload ${PLIST_FILE}
            rm -f ${PLIST_FILE}
            print_info "服务已卸载"
        else
            print_error "服务未找到"
        fi
    else
        # Linux
        if command -v systemctl &> /dev/null; then
            sudo systemctl stop ${SERVICE_NAME}
            sudo systemctl disable ${SERVICE_NAME}
            sudo rm -f /etc/systemd/system/${SERVICE_NAME}.service
            sudo systemctl daemon-reload
            print_info "服务已卸载"
        else
            print_error "不支持的服务管理器"
        fi
    fi
}

# 显示帮助
show_help() {
    echo "WorkCheck 服务管理脚本"
    echo ""
    echo "用法: $0 [command]"
    echo ""
    echo "命令:"
    echo "  install   安装为系统服务"
    echo "  uninstall 卸载系统服务"
    echo "  help      显示帮助"
    echo ""
    echo "说明："
    echo "  - Linux系统使用systemd"
    echo "  - macOS系统使用launchd"
}

# 主函数
main() {
    case "$1" in
        install)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                install_service_launchd
            else
                install_service_systemd
            fi
            ;;
        uninstall)
            uninstall_service
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"