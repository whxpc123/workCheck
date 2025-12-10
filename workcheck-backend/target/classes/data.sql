-- 初始化默认检查项模板数据
INSERT IGNORE INTO check_templates (id, name, description, is_default, created_at)
VALUES (1, '默认检查项模板', '系统默认的代码变更检查项', true, NOW());

INSERT IGNORE INTO check_template_items (template_id, item_text, sort_order)
SELECT 1, item, idx FROM (
    SELECT '代码合并是否完成' as item, 0 as idx UNION ALL
    SELECT '冲突是否确认', 1 UNION ALL
    SELECT '核心逻辑单测覆盖', 2 UNION ALL
    SELECT '高风险点复盘', 3 UNION ALL
    SELECT '日志级别合理', 4 UNION ALL
    SELECT '异常兜底处理', 5 UNION ALL
    SELECT 'paas参数核对', 6 UNION ALL
    SELECT 'cmc参数核对', 7 UNION ALL
    SELECT '性能测试完成', 8
) AS items
WHERE NOT EXISTS (SELECT 1 FROM check_template_items WHERE template_id = 1 AND sort_order = items.idx);