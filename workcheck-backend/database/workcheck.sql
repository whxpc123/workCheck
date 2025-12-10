-- ========================================
-- WorkCheck 数据库脚本
-- 创建时间：2024年
-- 描述：代码变更检查系统数据库结构
-- ========================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS workcheck
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE workcheck;

-- ========================================
-- 1. 检查项模板表
-- ========================================
CREATE TABLE IF NOT EXISTS check_templates (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT '模板名称',
    description VARCHAR(500) COMMENT '模板描述',
    is_default BOOLEAN DEFAULT FALSE COMMENT '是否默认模板',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_is_default (is_default),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB COMMENT='检查项模板表';

-- ========================================
-- 2. 检查项模板明细表
-- ========================================
CREATE TABLE IF NOT EXISTS check_template_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    template_id BIGINT NOT NULL COMMENT '模板ID',
    item_text VARCHAR(200) NOT NULL COMMENT '检查项内容',
    sort_order INT NOT NULL DEFAULT 0 COMMENT '排序顺序',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (template_id) REFERENCES check_templates(id) ON DELETE CASCADE,
    INDEX idx_template_sort (template_id, sort_order)
) ENGINE=InnoDB COMMENT='检查项模板明细表';

-- ========================================
-- 3. 任务主表
-- ========================================
CREATE TABLE IF NOT EXISTS tasks (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id VARCHAR(50) NOT NULL COMMENT '任务编号',
    change_content TEXT COMMENT '变更内容',
    risk VARCHAR(20) COMMENT '风险等级',
    user_name VARCHAR(100) NOT NULL COMMENT '用户名',
    month VARCHAR(10) NOT NULL COMMENT '月份(YYYY-MM)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY uk_task (user_name, month, task_id),
    INDEX idx_user_month (user_name, month),
    INDEX idx_task_id (task_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB COMMENT='任务主表';

-- ========================================
-- 4. 任务文件表
-- ========================================
CREATE TABLE IF NOT EXISTS task_files (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id BIGINT NOT NULL COMMENT '任务ID',
    file_path TEXT COMMENT '文件路径',
    test_status VARCHAR(100) COMMENT '测试状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    INDEX idx_task (task_id)
) ENGINE=InnoDB COMMENT='任务文件表';

-- ========================================
-- 5. 任务检查项表
-- ========================================
CREATE TABLE IF NOT EXISTS task_checks (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id BIGINT NOT NULL COMMENT '任务ID',
    check_item VARCHAR(200) NOT NULL COMMENT '检查项内容',
    status VARCHAR(20) NOT NULL DEFAULT '未完成' COMMENT '状态(完成/未完成)',
    sort_order INT NOT NULL DEFAULT 0 COMMENT '排序顺序',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    INDEX idx_task_sort (task_id, sort_order),
    INDEX idx_status (status)
) ENGINE=InnoDB COMMENT='任务检查项表';

-- ========================================
-- 初始化数据
-- ========================================

-- 插入默认检查项模板
INSERT INTO check_templates (id, name, description, is_default, created_at)
VALUES (1, '默认检查项模板', '系统默认的代码变更检查项', TRUE, NOW())
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    description = VALUES(description),
    is_default = VALUES(is_default);

-- 插入默认检查项明细
INSERT INTO check_template_items (template_id, item_text, sort_order) VALUES
(1, '代码合并是否完成', 0),
(1, '冲突是否确认', 1),
(1, '核心逻辑单测覆盖', 2),
(1, '高风险点复盘', 3),
(1, '日志级别合理', 4),
(1, '异常兜底处理', 5),
(1, 'paas参数核对', 6),
(1, 'cmc参数核对', 7),
(1, '性能测试完成', 8)
ON DUPLICATE KEY UPDATE
    item_text = VALUES(item_text),
    sort_order = VALUES(sort_order);

-- ========================================
-- 创建视图（可选）
-- ========================================

-- 任务统计视图
CREATE OR REPLACE VIEW v_task_stats AS
SELECT
    user_name,
    month,
    COUNT(*) as total_tasks,
    COUNT(CASE WHEN status = '完成' THEN 1 END) as completed_checks,
    COUNT(*) * 9 as total_checks,  -- 假设每个任务有9个检查项
    ROUND(COUNT(CASE WHEN status = '完成' THEN 1 END) * 100.0 / (COUNT(*) * 9), 2) as completion_rate
FROM tasks t
LEFT JOIN task_checks tc ON t.id = tc.task_id
GROUP BY user_name, month;

-- ========================================
-- 创建存储过程（可选）
-- ========================================

DELIMITER //

-- 清理指定月份之前的旧数据
CREATE PROCEDURE IF NOT EXISTS CleanOldData(IN months_to_keep INT)
BEGIN
    DECLARE cutoff_date DATE;
    SET cutoff_date = DATE_SUB(CURRENT_DATE(), INTERVAL months_to_keep MONTH);

    DELETE FROM tasks
    WHERE STR_TO_DATE(CONCAT(month, '-01'), '%Y-%m-%d') < cutoff_date;
END //

DELIMITER ;

-- ========================================
-- 数据库使用说明
-- ========================================

/*
1. 数据库配置要求：
   - MySQL 8.0 或以上版本
   - 字符集：utf8mb4
   - 排序规则：utf8mb4_unicode_ci

2. 连接配置：
   在 application.yml 中配置：
   spring:
     datasource:
       url: jdbc:mysql://localhost:3306/workcheck?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai
       username: root
       password: [你的密码]

3. 表结构说明：
   - check_templates: 检查项模板表，可以创建多套模板
   - check_template_items: 检查项模板明细，存储具体的检查内容
   - tasks: 任务主表，存储任务基本信息
   - task_files: 任务文件表，一个任务可以关联多个文件
   - task_checks: 任务检查项表，记录每个检查项的完成状态

4. 扩展说明：
   - 支持动态添加检查项：在 check_template_items 表中添加新记录
   - 支持多套模板：在 check_templates 表中创建新模板，并设置 is_default=FALSE
   - 数据备份：建议定期备份 tasks 相关的表

5. 清理数据：
   使用存储过程 CleanOldData 清理指定月份之前的数据：
   CALL CleanOldData(12);  -- 清理12个月之前的数据
*/

-- 显示表结构
SHOW TABLES;

-- 显示初始化数据
SELECT '默认检查项模板：' as info;
SELECT * FROM check_templates WHERE is_default = TRUE;

SELECT '默认检查项：' as info;
SELECT * FROM check_template_items WHERE template_id = 1 ORDER BY sort_order;