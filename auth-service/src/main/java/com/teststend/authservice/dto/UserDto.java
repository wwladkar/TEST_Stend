package com.teststend.authservice.dto;

public record UserDto(Long id, String username, String email, String role, boolean enabled) {}
