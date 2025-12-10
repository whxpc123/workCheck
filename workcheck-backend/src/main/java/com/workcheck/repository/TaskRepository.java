package com.workcheck.repository;

import com.workcheck.entity.Task;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {

    List<Task> findByUserNameAndMonthOrderByCreatedAtDesc(String userName, String month);

    @Query("SELECT t FROM Task t WHERE t.userName = :userName AND t.month = :month ORDER BY t.createdAt DESC")
    List<Task> findTasks(@Param("userName") String userName, @Param("month") String month);

    Optional<Task> findByTaskId(String taskId);

    @Query("SELECT DISTINCT t.userName FROM Task t")
    List<String> findDistinctUserNames();

    @Query("SELECT DISTINCT t.month FROM Task t ORDER BY t.month DESC")
    List<String> findDistinctMonths();

    @Modifying
    @Query("DELETE FROM Task t WHERE t.userName = :userName AND t.month = :month")
    int deleteByUserNameAndMonth(@Param("userName") String userName, @Param("month") String month);
}