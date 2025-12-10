package com.workcheck.repository;

import com.workcheck.entity.CheckTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CheckTemplateRepository extends JpaRepository<CheckTemplate, Long> {

    @Query("SELECT t FROM CheckTemplate t WHERE t.isDefault = true")
    Optional<CheckTemplate> findDefaultTemplate();

    @Query("SELECT t FROM CheckTemplate t ORDER BY t.isDefault DESC, t.createdAt DESC")
    List<CheckTemplate> findAllOrderedByDefaultFirst();
}