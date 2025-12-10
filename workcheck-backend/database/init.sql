-- ========================================
-- 快速初始化脚本
-- 用于快速创建和初始化数据库
-- ========================================

-- 1. 创建数据库用户（可选）
-- CREATE USER IF NOT EXISTS 'workcheck'@'%' IDENTIFIED BY 'WorkCheck123!';
-- GRANT ALL PRIVILEGES ON workcheck.* TO 'workcheck'@'%';
-- FLUSH PRIVILEGES;

-- 2. 创建数据库并导入结构
SOURCE workcheck.sql;

-- 3. 插入示例数据（用于测试）
INSERT INTO tasks (task_id, change_content, risk, user_name, month) VALUES
('S00001', '修复用户登录页面样式问题', '低', 'admin', '2024-01'),
('S00002', '添加导出Excel功能', '中', 'admin', '2024-01'),
('S00003', '优化数据库查询性能', '高', 'zhangsan', '2024-01');

-- 为第一个任务添加文件
INSERT INTO task_files (task_id, file_path, test_status) VALUES
(1, '/src/components/Login.vue', '已完成'),
(1, '/src/styles/login.css', '已完成');

-- 为第二个任务添加文件
INSERT INTO task_files (task_id, file_path, test_status) VALUES
(2, '/src/utils/export.js', '进行中'),
(2, '/src/api/export.js', '未开始');

-- 为第三个任务添加文件
INSERT INTO task_files (task_id, file_path, test_status) VALUES
(3, '/src/sql/user.sql', '已完成'),
(3, '/src/sql/order.sql', '已完成');

-- 为任务添加检查项状态
INSERT INTO task_checks (task_id, check_item, status, sort_order)
SELECT t.id, cti.item_text, CASE WHEN t.id = 1 THEN '完成' WHEN t.id = 2 THEN '未完成' ELSE '完成' END, cti.sort_order
FROM tasks t
CROSS JOIN check_template_items cti
WHERE cti.template_id = 1
ORDER BY t.id, cti.sort_order;

-- 查看示例数据
SELECT '任务列表：' as info;
SELECT id, task_id, change_content, risk, user_name, month FROM tasks;

SELECT '\n文件列表：' as info;
SELECT tf.id, t.task_id, tf.file_path, tf.test_status
FROM task_files tf
JOIN tasks t ON tf.task_id = t.id;

SELECT '\n检查项统计：' as info;
SELECT t.task_id, COUNT(*) as total_checks,
       SUM(CASE WHEN tc.status = '完成' THEN 1 ELSE 0 END) as completed_checks
FROM tasks t
LEFT JOIN task_checks tc ON t.id = tc.task_id
GROUP BY t.id, t.task_id;

-- 完成
SELECT '\n数据库初始化完成！' as info;