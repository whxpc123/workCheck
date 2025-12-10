package com.workcheck.dto;

import java.util.List;

public class GitCommitDTO {
    private String hash;
    private String author;
    private String date;
    private String message;
    private List<String> files;

    public GitCommitDTO() {}

    public GitCommitDTO(String hash, String author, String date, String message, List<String> files) {
        this.hash = hash;
        this.author = author;
        this.date = date;
        this.message = message;
        this.files = files;
    }

    public String getHash() {
        return hash;
    }

    public void setHash(String hash) {
        this.hash = hash;
    }

    public String getAuthor() {
        return author;
    }

    public void setAuthor(String author) {
        this.author = author;
    }

    public String getDate() {
        return date;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public List<String> getFiles() {
        return files;
    }

    public void setFiles(List<String> files) {
        this.files = files;
    }

    public String getShortHash() {
        return hash != null && hash.length() > 7 ? hash.substring(0, 7) : hash;
    }
}