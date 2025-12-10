package com.workcheck.dto;

import java.util.List;

public class TaskDTO {
    private Long id;
    private String taskId;
    private String change;
    private String risk;
    private String userName;
    private String month;
    private List<FileDTO> files;
    private List<CheckDTO> checks;

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTaskId() {
        return taskId;
    }

    public void setTaskId(String taskId) {
        this.taskId = taskId;
    }

    public String getChange() {
        return change;
    }

    public void setChange(String change) {
        this.change = change;
    }

    public String getRisk() {
        return risk;
    }

    public void setRisk(String risk) {
        this.risk = risk;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getMonth() {
        return month;
    }

    public void setMonth(String month) {
        this.month = month;
    }

    public List<FileDTO> getFiles() {
        return files;
    }

    public void setFiles(List<FileDTO> files) {
        this.files = files;
    }

    public List<CheckDTO> getChecks() {
        return checks;
    }

    public void setChecks(List<CheckDTO> checks) {
        this.checks = checks;
    }
}