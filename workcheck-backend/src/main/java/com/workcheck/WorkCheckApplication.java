package com.workcheck;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class WorkCheckApplication {
    //新增项目
    public static void main(String[] args) {
        SpringApplication.run(WorkCheckApplication.class, args);
        System.out.println("启动成功日志打印");
    }
}