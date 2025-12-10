#!/bin/bash

# WorkCheck 数据库管理脚本
# 用法：./db_manager.sh [command] [options]

DB_NAME="workcheck"
DB_HOST="localhost"
DB_PORT="3306"
DB_USER="root"
DB_PASSWORD="123456"  # 请根据实际情况修改

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查MySQL连接
check_mysql() {
    mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD -e "SELECT 1;" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# 创建数据库
create_db() {
    print_info "正在创建数据库 $DB_NAME..."
    mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD < workcheck.sql
    if [ $? -eq 0 ]; then
        print_info "数据库创建成功！"
    else
        print_error "数据库创建失败！"
    fi
}

# 初始化数据
init_data() {
    print_info "正在初始化数据库..."
    mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD $DB_NAME < init.sql
    if [ $? -eq 0 ]; then
        print_info "数据初始化成功！"
    else
        print_error "数据初始化失败！"
    fi
}

# 备份数据库
backup_db() {
    BACKUP_DIR="backups"
    BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql"

    mkdir -p $BACKUP_DIR
    print_info "正在备份数据库到 $BACKUP_FILE..."

    mysqldump -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD \
        --single-transaction \
        --routines \
        --triggers \
        $DB_NAME > $BACKUP_FILE

    if [ $? -eq 0 ]; then
        print_info "数据库备份成功！文件位置：$BACKUP_FILE"

        # 压缩备份文件
        gzip $BACKUP_FILE
        print_info "备份文件已压缩：$BACKUP_FILE.gz"
    else
        print_error "数据库备份失败！"
    fi
}

# 恢复数据库
restore_db() {
    if [ -z "$2" ]; then
        print_error "请指定备份文件路径！"
        echo "用法：$0 restore <backup_file>"
        exit 1
    fi

    BACKUP_FILE=$2
    if [ ! -f "$BACKUP_FILE" ]; then
        print_error "备份文件不存在：$BACKUP_FILE"
        exit 1
    fi

    print_warn "警告：这将覆盖现有数据库 $DB_NAME！"
    read -p "确定要继续吗？(y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "正在恢复数据库..."
        mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD $DB_NAME < $BACKUP_FILE
        if [ $? -eq 0 ]; then
            print_info "数据库恢复成功！"
        else
            print_error "数据库恢复失败！"
        fi
    else
        print_info "操作已取消。"
    fi
}

# 清理旧数据
clean_data() {
    if [ -z "$2" ]; then
        MONTHS_TO_KEEP=12
    else
        MONTHS_TO_KEEP=$2
    fi

    print_warn "将清理 $MONTHS_TO_KEEP 个月之前的数据"
    read -p "确定要继续吗？(y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD $DB_NAME -e "
            DELETE FROM tasks
            WHERE STR_TO_DATE(CONCAT(month, '-01'), '%Y-%m-%d')
                < DATE_SUB(CURRENT_DATE(), INTERVAL $MONTHS_TO_KEEP MONTH);
        "
        print_info "旧数据清理完成！"
    else
        print_info "操作已取消。"
    fi
}

# 显示统计信息
show_stats() {
    print_info "数据库统计信息："
    echo "----------------------------------------"

    mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD $DB_NAME -e "
        SELECT
            '总任务数' as '统计项',
            COUNT(*) as '数量'
        FROM tasks
        UNION ALL
        SELECT
            '总文件数',
            COUNT(*)
        FROM task_files
        UNION ALL
        SELECT
            '总检查项数',
            COUNT(*)
        FROM task_checks
        UNION ALL
        SELECT
            '已完成检查项',
            COUNT(*)
        FROM task_checks
        WHERE status = '完成'
        UNION ALL
        SELECT
            '检查项模板数',
            COUNT(*)
        FROM check_templates;
    "

    echo "----------------------------------------"
    print_info "用户和月份统计："
    echo "----------------------------------------"

    mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD $DB_NAME -e "
        SELECT
            user_name as '用户',
            month as '月份',
            COUNT(*) as '任务数'
        FROM tasks
        GROUP BY user_name, month
        ORDER BY month DESC, user_name;
    "
}

# 连接数据库
connect_db() {
    print_info "连接到数据库 $DB_NAME..."
    mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD $DB_NAME
}

# 显示帮助
show_help() {
    echo "WorkCheck 数据库管理工具"
    echo "用法：$0 [command] [options]"
    echo ""
    echo "命令："
    echo "  create     创建数据库和表结构"
    echo "  init       初始化数据库（包含示例数据）"
    echo "  backup     备份数据库"
    echo "  restore    恢复数据库"
    echo "  clean      清理旧数据（默认保留12个月）"
    echo "  stats      显示统计信息"
    echo "  connect    连接到数据库"
    echo "  help       显示此帮助信息"
    echo ""
    echo "示例："
    echo "  $0 create           # 创建数据库"
    echo "  $0 init             # 初始化数据库"
    echo "  $0 backup           # 备份数据库"
    echo "  $0 restore backup.sql # 从备份恢复"
    echo "  $0 clean 6          # 清理6个月前的数据"
}

# 主程序
main() {
    # 检查MySQL连接
    if ! check_mysql; then
        print_error "无法连接到MySQL数据库！请检查连接配置。"
        exit 1
    fi

    case "$1" in
        create)
            create_db
            ;;
        init)
            create_db
            init_data
            ;;
        backup)
            backup_db
            ;;
        restore)
            restore_db $@
            ;;
        clean)
            clean_data $@
            ;;
        stats)
            show_stats
            ;;
        connect)
            connect_db
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令：$1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主程序
main $@