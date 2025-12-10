package com.workcheck.controller;

import com.workcheck.dto.GitCommitDTO;
import com.workcheck.service.GitService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/git")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class GitController {

    @Autowired
    private GitService gitService;

    /**
     * 获取指定月份的Git提交记录
     */
    @GetMapping("/commits")
    public ResponseEntity<Map<String, Object>> getCommits(
            @RequestParam String userName,
            @RequestParam String month,
            @RequestParam(required = false) String projectPath) {
        Map<String, Object> response = new HashMap<>();

        try {
            // 检查是否为Git仓库
            if (projectPath != null && !projectPath.isEmpty()) {
                if (!gitService.isGitRepository(projectPath)) {
                    response.put("success", false);
                    response.put("error", "指定路径不是Git仓库");
                    return ResponseEntity.ok(response);
                }
            }

            // 获取提交记录
            List<GitCommitDTO> commits = gitService.getCommitsForMonth(projectPath, userName, month);

            // 获取远程URL
            String remoteUrl = null;
            if (projectPath != null && !projectPath.isEmpty()) {
                remoteUrl = gitService.getRemoteUrl(projectPath);
            }

            response.put("success", true);
            response.put("commits", commits);
            response.put("remoteUrl", remoteUrl);
            response.put("total", commits.size());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            response.put("success", false);
            response.put("error", "获取Git提交记录失败：" + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    /**
     * 获取文件的修改内容
     */
    @GetMapping("/file-diff")
    public ResponseEntity<Map<String, Object>> getFileDiff(
            @RequestParam String projectPath,
            @RequestParam String commitHash,
            @RequestParam String filePath) {
        Map<String, Object> response = new HashMap<>();

        try {
            // 检查是否为Git仓库
            if (!gitService.isGitRepository(projectPath)) {
                response.put("success", false);
                response.put("error", "指定路径不是Git仓库");
                return ResponseEntity.ok(response);
            }

            // 获取文件内容
            String content = gitService.getFileDiff(projectPath, commitHash, filePath);

            response.put("success", true);
            response.put("content", content);
            response.put("commitHash", commitHash);
            response.put("filePath", filePath);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            response.put("success", false);
            response.put("error", "获取文件内容失败：" + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    /**
     * 检查是否为Git仓库
     */
    @GetMapping("/check-repo")
    public ResponseEntity<Map<String, Object>> checkRepository(@RequestParam String projectPath) {
        Map<String, Object> response = new HashMap<>();

        try {
            boolean isRepo = gitService.isGitRepository(projectPath);
            String remoteUrl = null;

            if (isRepo) {
                remoteUrl = gitService.getRemoteUrl(projectPath);
            }

            response.put("success", true);
            response.put("isRepository", isRepo);
            response.put("remoteUrl", remoteUrl);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            response.put("success", false);
            response.put("error", "检查仓库失败：" + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }
}