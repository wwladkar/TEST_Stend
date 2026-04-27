package com.teststend.authservice.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record RoleChangeRequest(
    @NotBlank @Pattern(regexp = "USER|ADMIN", message = "Роль должна быть USER или ADMIN")
    String role
) {}
