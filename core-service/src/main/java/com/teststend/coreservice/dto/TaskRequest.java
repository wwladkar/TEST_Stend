package com.teststend.coreservice.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record TaskRequest(
    @NotBlank @Size(min = 1, max = 200) String title,
    @Size(max = 1000) String description,
    String status,
    String priority
) {}
