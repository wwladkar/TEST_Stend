package com.teststend.coreservice.dto;

import com.teststend.coreservice.entity.TaskPriority;
import com.teststend.coreservice.entity.TaskStatus;

public record TaskDto(Long id, String title, String description, TaskStatus status, TaskPriority priority, String createdBy) {}
