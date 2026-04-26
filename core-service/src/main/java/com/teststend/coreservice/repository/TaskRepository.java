package com.teststend.coreservice.repository;

import com.teststend.coreservice.entity.Task;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TaskRepository extends JpaRepository<Task, Long> {
    Page<Task> findByCreatedBy(String createdBy, Pageable pageable);
}
