package com.teststend.coreservice.dto;

public record TaskDto(Long id, String title, String description, String status, String priority, String createdBy) {}
