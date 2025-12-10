package com.workcheck.service;

import com.workcheck.dto.TaskDTO;
import com.workcheck.dto.FileDTO;
import com.workcheck.dto.CheckDTO;
import com.workcheck.entity.*;
import com.workcheck.repository.CheckTemplateRepository;
import com.workcheck.repository.TaskRepository;
import javax.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import java.util.Set;
import java.util.HashSet;
import org.springframework.stereotype.Service;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@Transactional
public class WorkCheckService {

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private CheckTemplateRepository checkTemplateRepository;

    @PersistenceContext
    private EntityManager entityManager;

    // 加载任务
    public List<TaskDTO> loadTasks(String userName, String month) {
        List<Task> tasks = taskRepository.findTasks(userName, month);
        return tasks.stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    // 保存任务
    public List<TaskDTO> saveTasks(String userName, String month, List<TaskDTO> taskDTOs) {
        // 先删除原有任务（使用显式的批量删除查询，这样可以看到DELETE SQL）
        int deletedCount = taskRepository.deleteByUserNameAndMonth(userName, month);
        System.out.println("删除了 " + deletedCount + " 条任务记录");

        // 立即刷新，确保DELETE语句立即执行
        entityManager.flush();

        // 清除一级缓存，确保后续查询能看到删除结果
        entityManager.clear();

        // 再次查询确认删除
        List<Task> existingTasks = taskRepository.findTasks(userName, month);
        System.out.println("删除后剩余任务数: " + existingTasks.size());

        // 确保任务ID唯一
        Set<String> usedTaskIds = new HashSet<>();
        List<Task> savedTasks = new ArrayList<>();

        for (TaskDTO dto : taskDTOs) {
            System.out.println("处理任务: " + dto.getTaskId() + ", checks数量: " + (dto.getChecks() != null ? dto.getChecks().size() : 0));
            Task task = convertToEntity(dto);
            task.setUserName(userName);
            task.setMonth(month);

            // 如果任务ID重复，生成新的ID
            if (usedTaskIds.contains(task.getTaskId())) {
                String baseId = task.getTaskId().replaceAll("-\\w*$", "");
                int suffix = 1;
                String newTaskId;
                do {
                    newTaskId = baseId + "-" + suffix;
                    suffix++;
                } while (usedTaskIds.contains(newTaskId));
                task.setTaskId(newTaskId);
            }

            usedTaskIds.add(task.getTaskId());
            savedTasks.add(taskRepository.save(task));
        }

        return savedTasks.stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    // 获取检查项模板
    public List<String> getCheckTemplate() {
        // 尝试获取默认模板
        Optional<CheckTemplate> defaultTemplate = checkTemplateRepository.findDefaultTemplate();

        if (defaultTemplate.isPresent()) {
            CheckTemplate template = defaultTemplate.get();
            return template.getItems().stream()
                    .sorted((a, b) -> a.getSortOrder().compareTo(b.getSortOrder()))
                    .map(CheckTemplateItem::getItemText)
                    .collect(Collectors.toList());
        }

        // 如果没有默认模板，返回硬编码的默认检查项
        List<String> defaultChecks = new ArrayList<>();
        defaultChecks.add("代码合并是否完成");
        defaultChecks.add("冲突是否确认");
        defaultChecks.add("核心逻辑单测覆盖");
        defaultChecks.add("高风险点复盘");
        defaultChecks.add("日志级别合理");
        defaultChecks.add("异常兜底处理");
        defaultChecks.add("paas参数核对");
        defaultChecks.add("cmc参数核对");
        defaultChecks.add("性能测试完成");
        return defaultChecks;
    }

    // 初始化默认检查项模板
    public void initializeDefaultCheckTemplate() {
        // 检查是否已存在默认模板
        Optional<CheckTemplate> existingDefault = checkTemplateRepository.findDefaultTemplate();
        if (existingDefault.isPresent()) {
            return; // 已存在默认模板，不需要重复创建
        }

        // 创建默认模板
        CheckTemplate defaultTemplate = new CheckTemplate();
        defaultTemplate.setName("默认检查项模板");
        defaultTemplate.setDescription("系统默认的代码变更检查项");
        defaultTemplate.setIsDefault(true);

        List<CheckTemplateItem> items = new ArrayList<>();
        String[] defaultItems = {
            "代码合并是否完成",
            "冲突是否确认",
            "核心逻辑单测覆盖",
            "高风险点复盘",
            "日志级别合理",
            "异常兜底处理",
            "paas参数核对",
            "cmc参数核对",
            "性能测试完成"
        };

        for (int i = 0; i < defaultItems.length; i++) {
            CheckTemplateItem item = new CheckTemplateItem();
            item.setItemText(defaultItems[i]);
            item.setSortOrder(i);
            item.setTemplate(defaultTemplate);
            items.add(item);
        }

        defaultTemplate.setItems(items);
        checkTemplateRepository.save(defaultTemplate);
    }

    // 获取所有用户列表
    public List<String> getAllUsers() {
        return taskRepository.findDistinctUserNames();
    }

    // 获取所有月份列表
    public List<String> getAllMonths() {
        return taskRepository.findDistinctMonths();
    }

    // 转换DTO到实体
    private Task convertToEntity(TaskDTO dto) {
        Task task = new Task();
        task.setId(dto.getId());
        task.setTaskId(dto.getTaskId());
        task.setChange(dto.getChange());
        task.setRisk(dto.getRisk());

        // 处理文件列表
        if (dto.getFiles() != null) {
            List<TaskFile> files = dto.getFiles().stream().map(fileDTO -> {
                TaskFile file = new TaskFile();
                file.setId(fileDTO.getId());
                file.setFile(fileDTO.getFile());
                file.setTest(fileDTO.getTest());
                file.setTask(task);
                return file;
            }).collect(Collectors.toList());
            task.setFiles(files);
        }

        // 处理检查项列表
        if (dto.getChecks() != null) {
            List<TaskCheck> checks = dto.getChecks().stream().map(checkDTO -> {
                TaskCheck check = new TaskCheck();
                check.setId(checkDTO.getId());
                check.setCheckItem(checkDTO.getCheckItem());
                check.setStatus(checkDTO.getStatus());
                check.setSortOrder(checkDTO.getSortOrder());
                check.setTask(task);
                return check;
            }).collect(Collectors.toList());
            task.setChecks(checks);
        }

        return task;
    }

    // 转换实体到DTO
    private TaskDTO convertToDTO(Task task) {
        TaskDTO dto = new TaskDTO();
        dto.setId(task.getId());
        dto.setTaskId(task.getTaskId());
        dto.setChange(task.getChange());
        dto.setRisk(task.getRisk());
        dto.setUserName(task.getUserName());
        dto.setMonth(task.getMonth());

        // 处理文件列表
        if (task.getFiles() != null) {
            List<FileDTO> fileDTOs = task.getFiles().stream().map(file -> {
                FileDTO fileDTO = new FileDTO();
                fileDTO.setId(file.getId());
                fileDTO.setFile(file.getFile());
                fileDTO.setTest(file.getTest());
                return fileDTO;
            }).collect(Collectors.toList());
            dto.setFiles(fileDTOs);
        }

        // 处理检查项列表
        if (task.getChecks() != null) {
            List<CheckDTO> checkDTOs = task.getChecks().stream()
                    .sorted((a, b) -> a.getSortOrder().compareTo(b.getSortOrder()))
                    .map(check -> {
                        CheckDTO checkDTO = new CheckDTO();
                        checkDTO.setId(check.getId());
                        checkDTO.setCheckItem(check.getCheckItem());
                        checkDTO.setStatus(check.getStatus());
                        checkDTO.setSortOrder(check.getSortOrder());
                        return checkDTO;
                    }).collect(Collectors.toList());
            dto.setChecks(checkDTOs);
        }

        return dto;
    }
}