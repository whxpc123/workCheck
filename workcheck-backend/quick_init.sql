-- 快速初始化数据库表（复制此内容到MySQL客户端执行）
CREATE DATABASE IF NOT EXISTS workcheck CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE workcheck;

-- 任务表
CREATE TABLE IF NOT EXISTS tasks (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id VARCHAR(50) NOT NULL,
    change_content TEXT,
    risk VARCHAR(20),
    user_name VARCHAR(100),
    month VARCHAR(10) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX uk_task (user_name, month, task_id),
    INDEX idx_task_id (task_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 任务文件表
CREATE TABLE IF NOT EXISTS task_files (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id BIGINT NOT NULL,
    file_path TEXT,
    test_status VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    INDEX idx_task (task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 任务检查项表
CREATE TABLE IF NOT EXISTS task_checks (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id BIGINT NOT NULL,
    check_item VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT '未完成',
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    INDEX idx_task_sort (task_id, sort_order),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 检查项模板表
CREATE TABLE IF NOT EXISTS check_templates (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_is_default (is_default),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 检查项模板明细表
CREATE TABLE IF NOT EXISTS check_template_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    template_id BIGINT NOT NULL,
    item_text VARCHAR(200) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (template_id) REFERENCES check_templates(id) ON DELETE CASCADE,
    INDEX idx_template_sort (template_id, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 插入默认检查项模板
INSERT IGNORE INTO check_templates (id, name, description, is_default, created_at)
VALUES (1, '默认检查项模板', '系统默认的代码变更检查项', TRUE, NOW());

-- 插入默认检查项明细
INSERT IGNORE INTO check_template_items (template_id, item_text, sort_order) VALUES
(1, '代码合并是否完成', 0),
(1, '冲突是否确认', 1),
(1, '核心逻辑单测覆盖', 2),
(1, '高风险点复盘', 3),
(1, '日志级别合理', 4),
(1, '异常兜底处理', 5),
(1, 'paas参数核对', 6),
(1, 'cmc参数核对', 7),
(1, '性能测试完成', 8);

-- 查看创建的表
SHOW TABLES;