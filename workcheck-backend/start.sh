#!/bin/bash

# ========================================
# WorkCheck 后端启动脚本
# 支持开发和生产环境
# ========================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置
APP_NAME="workcheck-backend"
JAR_FILE="target/${APP_NAME}-1.0.0.jar"
PID_FILE="application.pid"
LOG_FILE="logs/application.log"
SPRING_PROFILE="dev"  # dev, prod, test

# 打印带颜色的消息
print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}           WorkCheck 后端服务${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 检查Java环境
check_java() {
    print_step "检查Java环境..."

    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
        print_info "Java版本: $JAVA_VERSION"

        # 检查Java版本是否满足要求（需要Java 8+）
        MAJOR_VERSION=$(echo $JAVA_VERSION | cut -d'.' -f1)
        if [ "$MAJOR_VERSION" -lt 8 ]; then
            print_error "需要Java 8或更高版本，当前版本: $JAVA_VERSION"
            exit 1
        fi

        if [ "$MAJOR_VERSION" -ge 9 ]; then
            print_warn "检测到Java $MAJOR_VERSION，建议使用Java 8以获得最佳兼容性"
        fi
    else
        print_error "未找到Java，请安装Java 8或更高版本"
        exit 1
    fi

    if command -v mvn &> /dev/null; then
        MVN_VERSION=$(mvn -version | head -n 1 | awk '{print $3}')
        print_info "Maven版本: $MVN_VERSION"
    else
        print_warn "未找到Maven，尝试使用wrapper..."
        if [ ! -f "mvnw" ]; then
            print_error "未找到Maven和Maven Wrapper"
            exit 1
        fi
    fi
}

# 检查数据库连接
check_database() {
    print_step "检查数据库连接..."

    # 从配置文件读取数据库信息
    DB_CONFIG=$(grep -A 10 "spring.datasource" src/main/resources/application.yml)
    DB_HOST=$(echo "$DB_CONFIG" | grep "url" | sed 's/.*\/\/\([^:]*\):.*/\1/' || echo "localhost")
    DB_PORT=$(echo "$DB_CONFIG" | grep "url" | sed 's/.*:\([0-9]*\)\/.*/\1/' || echo "3306")
    DB_NAME=$(echo "$DB_CONFIG" | grep "url" | sed 's/.*\/\([^?]*\).*/\1/' || echo "workcheck")

    print_info "数据库地址: $DB_HOST:$DB_PORT"
    print_info "数据库名称: $DB_NAME"

    # 检查数据库是否存在
    if command -v mysql &> /dev/null; then
        if mysql -h$DB_HOST -P$DB_PORT -u root -p123456 -e "USE $DB_NAME;" 2>/dev/null; then
            print_info "数据库连接成功"
        else
            print_warn "数据库 $DB_NAME 不存在或无法连接"
            read -p "是否自动创建数据库？(y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                mysql -h$DB_HOST -P$DB_PORT -u root -p123456 -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
                print_info "数据库创建成功"
            fi
        fi
    else
        print_warn "未安装MySQL客户端，跳过数据库检查"
    fi
}

# 创建必要目录
create_directories() {
    print_step "创建必要目录..."

    mkdir -p logs
    mkdir -p target
    mkdir -p temp

    print_info "目录创建完成"
}

# 清理构建缓存
clean_build() {
    print_step "清理构建缓存..."

    if command -v mvn &> /dev/null; then
        mvn clean
    else
        ./mvnw clean
    fi

    print_info "清理完成"
}

# 编译打包
build_project() {
    print_step "编译打包项目..."

    if command -v mvn &> /dev/null; then
        mvn clean package -DskipTests
    else
        ./mvnw clean package -DskipTests
    fi

    if [ $? -eq 0 ]; then
        print_info "编译成功"
    else
        print_error "编译失败"
        exit 1
    fi
}

# 停止现有服务
stop_service() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat $PID_FILE)
        if ps -p $PID > /dev/null; then
            print_step "停止现有服务 (PID: $PID)..."
            kill $PID
            sleep 3

            # 强制停止
            if ps -p $PID > /dev/null; then
                kill -9 $PID
                print_warn "强制停止服务"
            fi
        fi
        rm -f $PID_FILE
    fi
}

# 启动服务
start_service() {
    print_step "启动服务..."

    # 设置JVM参数
    JVM_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC"

    # Java 8+ 特有参数
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
    MAJOR_VERSION=$(echo $JAVA_VERSION | cut -d'.' -f1)

    if [ "$MAJOR_VERSION" -ge 8 ]; then
        JVM_OPTS="$JVM_OPTS -XX:+UseStringDeduplication"
    fi

    # 开发环境额外参数
    if [ "$SPRING_PROFILE" = "dev" ]; then
        JVM_OPTS="$JVM_OPTS -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005"
        print_info "启用调试模式，端口: 5005"
    fi

    # 启动命令
    if command -v mvn &> /dev/null; then
        # 使用Maven运行（开发环境推荐）
        print_info "使用Maven运行（开发模式）"
        nohup mvn spring-boot:run -Dspring-boot.run.profiles=$SPRING_PROFILE \
            > $LOG_FILE 2>&1 &
        echo $! > $PID_FILE
    else
        # 使用JAR运行（生产环境推荐）
        if [ -f "$JAR_FILE" ]; then
            print_info "使用JAR运行"
            nohup java $JVM_OPTS -jar -Dspring.profiles.active=$SPRING_PROFILE $JAR_FILE \
                > $LOG_FILE 2>&1 &
            echo $! > $PID_FILE
        else
            print_error "未找到JAR文件: $JAR_FILE"
            exit 1
        fi
    fi

    # 等待服务启动
    sleep 5

    # 检查服务状态
    if ps -p $(cat $PID_FILE) > /dev/null; then
        print_info "服务启动成功！"
        print_info "PID: $(cat $PID_FILE)"
        print_info "Profile: $SPRING_PROFILE"
        print_info "日志文件: $LOG_FILE"
        print_info "访问地址: http://localhost:8080/workcheck"
        print_info "API文档: http://localhost:8080/workcheck/api/health"
    else
        print_error "服务启动失败！"
        print_error "请查看日志: tail -f $LOG_FILE"
        exit 1
    fi
}

# 显示服务状态
show_status() {
    print_step "检查服务状态..."

    if [ -f "$PID_FILE" ]; then
        PID=$(cat $PID_FILE)
        if ps -p $PID > /dev/null; then
            print_info "服务运行中"
            print_info "PID: $PID"

            # 显示端口占用情况
            PORTS=$(lsof -Pan -p $PID -i | grep LISTEN)
            if [ ! -z "$PORTS" ]; then
                print_info "监听端口:"
                echo "$PORTS" | awk '{print "  " $9}'
            fi

            # 显示内存使用
            MEMORY=$(ps -p $PID -o pid,vsz,rss,pcpu,pmem | tail -1)
            print_info "内存使用: $(echo $MEMORY | awk '{print $2/1024"MB"} VSZ, $(echo $MEMORY | awk '{print $3/1024"MB"} RSS)'
        else
            print_warn "PID文件存在但进程不存在"
            rm -f $PID_FILE
        fi
    else
        print_warn "服务未运行"
    fi
}

# 查看日志
show_logs() {
    if [ -f "$LOG_FILE" ]; then
        print_step "显示日志（按Ctrl+C退出）..."
        tail -f $LOG_FILE
    else
        print_warn "日志文件不存在: $LOG_FILE"
    fi
}

# 停止服务
stop_service_command() {
    print_step "停止服务..."
    stop_service
    print_info "服务已停止"
}

# 重启服务
restart_service() {
    print_step "重启服务..."
    stop_service
    sleep 2
    start_service
}

# 运行测试
run_tests() {
    print_step "运行测试..."

    if command -v mvn &> /dev/null; then
        mvn test
    else
        ./mvnw test
    fi

    if [ $? -eq 0 ]; then
        print_info "测试通过"
    else
        print_error "测试失败"
    fi
}

# 显示帮助
show_help() {
    echo "WorkCheck 后端启动脚本"
    echo ""
    echo "用法: $0 [command] [options]"
    echo ""
    echo "命令:"
    echo "  start     启动服务（默认）"
    echo "  stop      停止服务"
    echo "  restart   重启服务"
    echo "  status    查看服务状态"
    echo "  logs      查看实时日志"
    echo "  build     重新编译"
    echo "  test      运行测试"
    echo "  dev       开发模式启动（启用调试）"
    echo "  prod      生产模式启动"
    echo "  clean     清理构建缓存"
    echo "  help      显示帮助"
    echo ""
    echo "选项:"
    echo "  -p, --profile [dev|prod|test]  指定Spring配置文件"
    echo ""
    echo "示例:"
    echo "  $0 start                # 启动服务"
    echo "  $0 start -p prod        # 生产模式启动"
    echo "  $0 dev                  # 开发模式启动（带调试）"
    echo "  $0 restart              # 重启服务"
    echo "  $0 logs                 # 查看日志"
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--profile)
                SPRING_PROFILE="$2"
                shift 2
                ;;
            start|stop|restart|status|logs|build|test|dev|prod|clean|help)
                COMMAND="$1"
                shift
                ;;
            *)
                print_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 主函数
main() {
    # 解析命令行参数
    COMMAND=${COMMAND:-"start"}
    parse_args "$@"

    # 显示头部
    print_header

    # 执行命令
    case $COMMAND in
        start)
            check_java
            check_database
            create_directories
            if [ ! -f "$JAR_FILE" ] || [ "src/main/resources/application.yml" -nt "$JAR_FILE" ]; then
                build_project
            fi
            start_service
            ;;
        dev)
            SPRING_PROFILE="dev"
            check_java
            check_database
            create_directories
            mvn spring-boot:run -Dspring-boot.run.profiles=dev
            ;;
        prod)
            SPRING_PROFILE="prod"
            check_java
            check_database
            create_directories
            build_project
            start_service
            ;;
        stop)
            stop_service_command
            ;;
        restart)
            restart_service
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        build)
            check_java
            build_project
            ;;
        test)
            check_java
            run_tests
            ;;
        clean)
            clean_build
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $COMMAND"
            show_help
            exit 1
            ;;
    esac
}

# 捕获退出信号
trap 'print_info "正在退出..."; stop_service; exit 0' SIGINT SIGTERM

# 执行主函数
main "$@"