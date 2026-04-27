package com.teststend.authservice.controller;

import com.teststend.authservice.dto.RoleChangeRequest;
import com.teststend.authservice.dto.ToggleEnabledRequest;
import com.teststend.authservice.dto.UserDto;
import com.teststend.authservice.service.AdminService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private final AdminService adminService;

    public AdminController(AdminService adminService) {
        this.adminService = adminService;
    }

    @GetMapping("/users")
    public List<UserDto> listUsers() {
        return adminService.listUsers();
    }

    @PutMapping("/users/{id}/role")
    public UserDto changeRole(@PathVariable Long id, @Valid @RequestBody RoleChangeRequest request) {
        return adminService.changeRole(id, request);
    }

    @PutMapping("/users/{id}/enabled")
    public UserDto toggleEnabled(@PathVariable Long id, @Valid @RequestBody ToggleEnabledRequest request) {
        return adminService.toggleEnabled(id, request);
    }
}
