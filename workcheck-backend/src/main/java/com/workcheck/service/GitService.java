package com.workcheck.service;

import com.workcheck.dto.GitCommitDTO;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class GitService {

    private static final DateTimeFormatter COMMIT_DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    /**
     * 获取指定月份的Git提交记录
     * @param projectPath 项目路径
     * @param userName 用户名（可选）
     * @param month 月份（格式：yyyy-MM）
     * @return 提交记录列表
     */
    public List<GitCommitDTO> getCommitsForMonth(String projectPath, String userName, String month) {
        List<GitCommitDTO> commits = new ArrayList<>();

        if (projectPath == null || projectPath.isEmpty()) {
            // 如果没有指定项目路径，返回空列表
            return commits;
        }

        try {
            // 解析月份
            YearMonth yearMonth = YearMonth.parse(month);
            LocalDate startDate = yearMonth.atDay(1);
            LocalDate endDate = yearMonth.atEndOfMonth();

            // 构建Git命令
            List<String> command = new ArrayList<>();
            command.add("git");
            command.add("log");
            command.add("--since=" + startDate.format(COMMIT_DATE_FORMAT));
            command.add("--until=" + endDate.format(COMMIT_DATE_FORMAT));
            command.add("--pretty=format:%H|%an|%ad|%s");
            command.add("--date=short");
            command.add("--name-only");

            if (userName != null && !userName.isEmpty()) {
                command.add("--author=" + userName);
            }

            // 执行Git命令
            ProcessBuilder pb = new ProcessBuilder(command);
            pb.directory(new File(projectPath));
            Process process = pb.start();

            // 读取输出
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                GitCommitDTO currentCommit = null;

                while ((line = reader.readLine()) != null) {
                    if (line.contains("|")) {
                        // 新的提交记录
                        if (currentCommit != null) {
                            commits.add(currentCommit);
                        }

                        String[] parts = line.split("\\|", 4);
                        currentCommit = new GitCommitDTO();
                        currentCommit.setHash(parts[0]);
                        currentCommit.setAuthor(parts[1]);
                        currentCommit.setDate(parts[2]);
                        currentCommit.setMessage(parts[3]);
                        currentCommit.setFiles(new ArrayList<>());
                    } else if (!line.trim().isEmpty() && currentCommit != null) {
                        // 文件路径
                        currentCommit.getFiles().add(line.trim());
                    }
                }

                // 添加最后一个提交
                if (currentCommit != null) {
                    commits.add(currentCommit);
                }
            }

            // 等待命令执行完成
            int exitCode = process.waitFor();
            if (exitCode != 0) {
                System.err.println("Git命令执行失败，退出码: " + exitCode);
            }

        } catch (IOException | InterruptedException e) {
            System.err.println("获取Git提交记录失败: " + e.getMessage());
            e.printStackTrace();
        }

        return commits;
    }

    /**
     * 获取文件的修改内容
     * @param projectPath 项目路径
     * @param commitHash 提交哈希
     * @param filePath 文件路径
     * @return 修改内容
     */
    public String getFileDiff(String projectPath, String commitHash, String filePath) {
        try {
            List<String> command = new ArrayList<>();
            command.add("git");
            command.add("show");
            command.add(commitHash + ":" + filePath);

            ProcessBuilder pb = new ProcessBuilder(command);
            pb.directory(new File(projectPath));
            Process process = pb.start();

            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line).append("\n");
                }
            }

            int exitCode = process.waitFor();
            if (exitCode == 0) {
                return output.toString();
            } else {
                return "无法获取文件内容";
            }

        } catch (IOException | InterruptedException e) {
            System.err.println("获取文件差异失败: " + e.getMessage());
            return "获取文件内容失败: " + e.getMessage();
        }
    }

    /**
     * 检查是否为Git仓库
     * @param projectPath 项目路径
     * @return 是否为Git仓库
     */
    public boolean isGitRepository(String projectPath) {
        if (projectPath == null || projectPath.isEmpty()) {
            return false;
        }

        Path gitPath = Paths.get(projectPath, ".git");
        return Files.exists(gitPath) && Files.isDirectory(gitPath);
    }

    /**
     * 获取Git仓库的远程URL
     * @param projectPath 项目路径
     * @return 远程URL
     */
    public String getRemoteUrl(String projectPath) {
        try {
            List<String> command = new ArrayList<>();
            command.add("git");
            command.add("remote");
            command.add("get-url");
            command.add("origin");

            ProcessBuilder pb = new ProcessBuilder(command);
            pb.directory(new File(projectPath));
            Process process = pb.start();

            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line.trim());
                }
            }

            int exitCode = process.waitFor();
            if (exitCode == 0) {
                String url = output.toString();
                // 转换为HTTPS格式（如果是SSH格式）
                if (url.startsWith("git@")) {
                    url = url.replace(":", "/").replace("git@", "https://");
                    if (!url.endsWith(".git")) {
                        url += ".git";
                    }
                    url = url.replace(".git.git", ".git");
                }
                return url;
            }

        } catch (IOException | InterruptedException e) {
            System.err.println("获取远程URL失败: " + e.getMessage());
        }

        return null;
    }

    /**
     * 获取文件的差异内容（代码变更）
     * @param projectPath 项目路径
     * @param commitHash 提交哈希
     * @param filePath 文件路径
     * @return 差异内容
     */
    public String getFileDiff(String projectPath, String commitHash, String filePath) {
        try {
            // 首先尝试获取该提交与父提交的差异
            List<String> command = new ArrayList<>();
            command.add("git");
            command.add("diff");
            command.add("--unified=3");  // 显示3行上下文
            command.add(commitHash + "^");  // 父提交
            command.add(commitHash);
            command.add("--");
            command.add(filePath);

            ProcessBuilder pb = new ProcessBuilder(command);
            pb.directory(new File(projectPath));
            Process process = pb.start();

            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line).append("\n");
                }
            }

            int exitCode = process.waitFor();
            if (exitCode == 0) {
                String diff = output.toString();
                if (!diff.trim().isEmpty()) {
                    return diff;
                }
                // 如果没有差异，可能是新创建的文件
            }

            // 如果获取差异失败或为空，尝试获取文件内容
            command = new ArrayList<>();
            command.add("git");
            command.add("show");
            command.add(commitHash + ":" + filePath);

            pb = new ProcessBuilder(command);
            pb.directory(new File(projectPath));
            process = pb.start();

            output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line).append("\n");
                }
            }

            exitCode = process.waitFor();
            if (exitCode == 0) {
                String content = output.toString();
                if (!content.trim().isEmpty()) {
                    // 添加标识，表示这是新文件内容
                    return "+++ 新创建的文件内容 +++\n" + content;
                }
                return "文件在此提交中被创建但没有内容";
            }

            return "无法获取文件内容";

        } catch (IOException | InterruptedException e) {
            System.err.println("获取文件差异失败: " + e.getMessage());
            return "获取文件内容失败: " + e.getMessage();
        }
    }

    /**
     * 获取Git仓库的默认分支
     * @param projectPath 项目路径
     * @return 默认分支名称（main/master等）
     */
    public String getDefaultBranch(String projectPath) {
        try {
            List<String> command = new ArrayList<>();
            command.add("git");
            command.add("symbolic-ref");
            command.add("refs/remotes/origin/HEAD");

            ProcessBuilder pb = new ProcessBuilder(command);
            pb.directory(new File(projectPath));
            Process process = pb.start();

            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line.trim());
                }
            }

            int exitCode = process.waitFor();
            if (exitCode == 0) {
                String ref = output.toString();
                if (ref.startsWith("refs/remotes/origin/")) {
                    return ref.substring("refs/remotes/origin/".length());
                }
            }
        } catch (IOException | InterruptedException e) {
            System.err.println("获取默认分支失败: " + e.getMessage());
        }

        // 如果无法获取默认分支，尝试常见的分支名
        try {
            // 检查是否有 main 分支
            List<String> command = new ArrayList<>();
            command.add("git");
            command.add("show-ref");
            command.add("--verify");
            command.add("refs/remotes/origin/main");

            ProcessBuilder pb = new ProcessBuilder(command);
            pb.directory(new File(projectPath));
            Process process = pb.start();

            int exitCode = process.waitFor();
            if (exitCode == 0) {
                return "main";
            }

            // 检查是否有 master 分支
            command.set(2, "refs/remotes/origin/master");
            pb = new ProcessBuilder(command);
            pb.directory(new File(projectPath));
            process = pb.start();

            exitCode = process.waitFor();
            if (exitCode == 0) {
                return "master";
            }
        } catch (IOException | InterruptedException e) {
            System.err.println("检查分支失败: " + e.getMessage());
        }

        // 默认返回 main
        return "main";
    }

    /**
     * 获取指定时间范围的Git提交记录
     * @param projectPath 项目路径
     * @param userName 用户名（可选）
     * @param month 月份（格式：yyyy-MM，当startDate和endDate为null时使用）
     * @param startDate 开始日期（格式：yyyy-MM-dd，可选）
     * @param endDate 结束日期（格式：yyyy-MM-dd，可选）
     * @return 提交记录列表
     */
    public List<GitCommitDTO> getCommitsForDateRange(String projectPath, String userName, String month, String startDate, String endDate) {
        List<GitCommitDTO> commits = new ArrayList<>();

        if (projectPath == null || projectPath.isEmpty()) {
            return commits;
        }

        try {
            // 构建Git命令
            List<String> command = new ArrayList<>();
            command.add("git");
            command.add("log");

            // 如果提供了自定义时间范围，使用它；否则使用月份
            if (startDate != null && !startDate.isEmpty() && endDate != null && !endDate.isEmpty()) {
                command.add("--since=" + startDate);
                command.add("--until=" + endDate);
            } else if (month != null && !month.isEmpty()) {
                // 解析月份
                YearMonth yearMonth = YearMonth.parse(month);
                LocalDate dateStartDate = yearMonth.atDay(1);
                LocalDate dateEndDate = yearMonth.atEndOfMonth();
                command.add("--since=" + dateStartDate.format(COMMIT_DATE_FORMAT));
                command.add("--until=" + dateEndDate.format(COMMIT_DATE_FORMAT));
            }

            command.add("--pretty=format:%H|%an|%ad|%s");
            command.add("--date=short");
            command.add("--name-only");

            if (userName != null && !userName.isEmpty()) {
                command.add("--author=" + userName);
            }

            // 执行Git命令
            ProcessBuilder pb = new ProcessBuilder(command);
            pb.directory(new File(projectPath));
            Process process = pb.start();

            // 读取输出
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                GitCommitDTO currentCommit = null;

                while ((line = reader.readLine()) != null) {
                    if (line.contains("|")) {
                        // 新的提交记录
                        if (currentCommit != null) {
                            commits.add(currentCommit);
                        }

                        String[] parts = line.split("\\|", 4);
                        currentCommit = new GitCommitDTO();
                        currentCommit.setHash(parts[0]);
                        currentCommit.setAuthor(parts[1]);
                        currentCommit.setDate(parts[2]);
                        currentCommit.setMessage(parts[3]);
                        currentCommit.setFiles(new ArrayList<>());
                    } else if (!line.trim().isEmpty() && currentCommit != null) {
                        // 文件路径
                        currentCommit.getFiles().add(line.trim());
                    }
                }

                // 添加最后一个提交
                if (currentCommit != null) {
                    commits.add(currentCommit);
                }
            }

            // 等待命令执行完成
            int exitCode = process.waitFor();
            if (exitCode != 0) {
                System.err.println("Git命令执行失败，退出码: " + exitCode);
            }

        } catch (IOException | InterruptedException e) {
            System.err.println("获取Git提交记录失败: " + e.getMessage());
            e.printStackTrace();
        }

        return commits;
    }
}