package com.workcheck.controller;

import com.workcheck.dto.TaskDTO;
import com.workcheck.service.WorkCheckService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class WorkCheckController {

    @Autowired
    private WorkCheckService workCheckService;

    // 加载任务
    @GetMapping("/load")
    public ResponseEntity<Map<String, Object>> loadTasks(
            @RequestParam String user,
            @RequestParam String month) {
        try {
            List<TaskDTO> tasks = workCheckService.loadTasks(user, month);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("tasks", tasks);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    // 保存任务
    @PostMapping("/save")
    public ResponseEntity<Map<String, Object>> saveTasks(
            @RequestParam String user,
            @RequestParam String month,
            @RequestBody List<TaskDTO> tasks) {
        try {
            List<TaskDTO> savedTasks = workCheckService.saveTasks(user, month, tasks);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("tasks", savedTasks);
            response.put("message", "保存成功");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    // 获取检查项模板
    @GetMapping("/check-template")
    public ResponseEntity<Map<String, Object>> getCheckTemplate() {
        try {
            List<String> checks = workCheckService.getCheckTemplate();
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("checks", checks);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    // 获取所有用户
    @GetMapping("/users")
    public ResponseEntity<Map<String, Object>> getAllUsers() {
        try {
            List<String> users = workCheckService.getAllUsers();
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("users", users);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    // 获取所有月份
    @GetMapping("/months")
    public ResponseEntity<Map<String, Object>> getAllMonths() {
        try {
            List<String> months = workCheckService.getAllMonths();
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("months", months);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    // 初始化默认模板
    @PostMapping("/init-template")
    public ResponseEntity<Map<String, Object>> initDefaultTemplate() {
        try {
            workCheckService.initializeDefaultCheckTemplate();
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "默认模板初始化成功");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    // 健康检查
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "OK");
        response.put("message", "WorkCheck API is running");
        response.put("timestamp", System.currentTimeMillis());
        return ResponseEntity.ok(response);
    }
}