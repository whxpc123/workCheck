package com.workcheck.controller;

import com.workcheck.service.WorkCheckService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class InitController {

    @Autowired
    private WorkCheckService workCheckService;

    /**
     * 创建所有表（仅用于初始化）
     */
    @GetMapping("/init-database")
    public ResponseEntity<Map<String, Object>> initDatabase() {
        Map<String, Object> response = new HashMap<>();

        try {
            // 调用初始化方法
            workCheckService.initializeDefaultCheckTemplate();

            response.put("success", true);
            response.put("message", "数据库初始化成功！表已创建，默认检查项模板已添加。");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", "初始化失败：" + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    /**
     * 检查数据库状态
     */
    @GetMapping("/check-database")
    public ResponseEntity<Map<String, Object>> checkDatabase() {
        Map<String, Object> response = new HashMap<>();

        try {
            // 尝试加载数据，检查表是否存在
            workCheckService.getCheckTemplate();

            response.put("success", true);
            response.put("message", "数据库连接正常，表已存在");
            response.put("tables", new String[]{"check_templates", "check_template_items", "tasks", "task_files", "task_checks"});
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", "数据库可能未初始化：" + e.getMessage());
            response.put("message", "请先调用 /api/init-database 来初始化数据库");
            return ResponseEntity.ok(response);
        }
    }
}