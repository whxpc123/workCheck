# WorkCheck 数据库管理

## 📁 文件说明

- `workcheck.sql` - 完整的数据库结构脚本，包含所有表、索引、视图和存储过程
- `init.sql` - 数据库初始化脚本，包含示例数据
- `db_manager.sh` - 数据库管理工具脚本（Linux/macOS）
- `README.md` - 本说明文档

## 🚀 快速开始

### 1. 修改数据库配置

编辑 `db_manager.sh` 文件中的数据库连接配置：

```bash
DB_HOST="localhost"      # 数据库主机
DB_PORT="3306"           # 数据库端口
DB_USER="root"           # 数据库用户名
DB_PASSWORD="123456"     # 数据库密码
```

### 2. 创建和初始化数据库

```bash
# 进入数据库目录
cd /Users/xpc/Documents/workCheck/workcheck-backend/database

# 方法1：使用管理脚本（推荐）
./db_manager.sh create      # 创建数据库和表结构
./db_manager.sh init        # 初始化数据库（包含示例数据）

# 方法2：使用MySQL命令
mysql -u root -p < workcheck.sql
mysql -u root -p workcheck < init.sql
```

### 3. 验证数据库

```bash
# 查看统计信息
./db_manager.sh stats

# 连接数据库查看
./db_manager.sh connect
```

## 🛠️ 数据库管理命令

```bash
# 创建数据库
./db_manager.sh create

# 初始化（创建+示例数据）
./db_manager.sh init

# 备份数据库
./db_manager.sh backup

# 恢复数据库
./db_manager.sh restore backup_file.sql

# 清理旧数据（默认保留12个月）
./db_manager.sh clean

# 清理6个月前的数据
./db_manager.sh clean 6

# 显示统计信息
./db_manager.sh stats

# 连接到数据库
./db_manager.sh connect

# 显示帮助
./db_manager.sh help
```

## 📊 数据库结构

### 主要表结构

1. **check_templates** - 检查项模板表
   - 支持多套检查项模板
   - 默认模板（is_default=1）

2. **check_template_items** - 检查项明细表
   - 存储具体的检查项内容
   - 支持自定义排序

3. **tasks** - 任务主表
   - 存储任务基本信息
   - 按用户和月份组织

4. **task_files** - 任务文件表
   - 一个任务可以有多个文件
   - 记录文件路径和测试状态

5. **task_checks** - 任务检查项表
   - 记录每个检查项的完成状态
   - 从模板继承检查项内容

### 关系说明

```
check_templates (1) ──── (N) check_template_items
      tasks (1) ──── (N) task_files
      tasks (1) ──── (N) task_checks
```

## 💾 备份和恢复

### 自动备份

```bash
# 创建备份（自动压缩）
./db_manager.sh backup

# 备份文件位置
ls -la backups/
```

### 手动备份

```bash
# 完整备份
mysqldump -u root -p workcheck > backup_$(date +%Y%m%d).sql

# 压缩备份
gzip backup_$(date +%Y%m%d).sql
```

### 恢复数据

```bash
# 从备份恢复
./db_manager.sh restore backups/workcheck_20240101.sql

# 或者直接使用MySQL命令
mysql -u root -p workcheck < backup_file.sql
```

## 🧹 数据清理

### 清理旧任务数据

```bash
# 清理12个月前的数据（默认）
./db_manager.sh clean

# 清理指定月份数据
./db_manager.sh clean 6
```

### SQL清理命令

```sql
-- 删除指定月份之前的任务
DELETE FROM tasks
WHERE STR_TO_DATE(CONCAT(month, '-01'), '%Y-%m-%d')
    < DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH);

-- 或使用存储过程
CALL CleanOldData(12);  -- 清理12个月之前的数据
```

## 📈 监控和统计

### 查看任务统计

```sql
-- 按用户和月份统计
SELECT
    user_name,
    month,
    COUNT(*) as task_count,
    AVG(check_count) as avg_checks
FROM (
    SELECT
        t.user_name,
        t.month,
        t.id,
        COUNT(tc.id) as check_count
    FROM tasks t
    LEFT JOIN task_checks tc ON t.id = tc.task_id
    GROUP BY t.id
) t
GROUP BY user_name, month
ORDER BY month DESC;
```

### 查看完成率

```sql
-- 使用视图
SELECT * FROM v_task_stats;

-- 或者直接查询
SELECT
    t.user_name,
    t.month,
    COUNT(DISTINCT t.id) as total_tasks,
    SUM(CASE WHEN tc.status = '完成' THEN 1 ELSE 0 END) as completed_checks,
    COUNT(tc.id) as total_checks,
    ROUND(
        SUM(CASE WHEN tc.status = '完成' THEN 1 ELSE 0 END) * 100.0 / COUNT(tc.id),
        2
    ) as completion_rate
FROM tasks t
LEFT JOIN task_checks tc ON t.id = tc.task_id
GROUP BY t.user_name, t.month;
```

## 🔧 维护建议

1. **定期备份** - 建议每周备份一次数据
2. **清理旧数据** - 根据需要定期清理超过保留期的数据
3. **监控空间** - 定期检查数据库大小，必要时进行优化
4. **索引优化** - 根据查询模式添加或调整索引

## 🐛 常见问题

### Q: 无法连接到数据库
A: 检查MySQL服务是否启动，用户名密码是否正确

### Q: 执行脚本报权限错误
A: 确保MySQL用户有创建数据库和表的权限

### Q: 备份文件太大
A: 可以分表备份，或使用 `--single-transaction` 参数进行一致性备份

### Q: 恢复数据报错
A: 确保目标数据库存在，且版本兼容

## 📞 技术支持

如有问题，请检查：
1. MySQL服务状态
2. 数据库连接参数
3. 用户权限设置
4. 磁盘空间是否充足