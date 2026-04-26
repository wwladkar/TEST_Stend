package com.teststend.authservice.controller;

import com.teststend.authservice.dto.UserDto;
import com.teststend.authservice.entity.User;
import com.teststend.authservice.repository.UserRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private final UserRepository userRepository;

    public AdminController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping("/users")
    public List<UserDto> listUsers() {
        return userRepository.findAll().stream()
                .map(this::toDto)
                .toList();
    }

    @PutMapping("/users/{id}/role")
    public UserDto changeRole(@PathVariable Long id, @RequestBody String role) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));
        user.setRole(role);
        return toDto(userRepository.save(user));
    }

    @PutMapping("/users/{id}/enabled")
    public UserDto toggleEnabled(@PathVariable Long id, @RequestBody boolean enabled) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));
        user.setEnabled(enabled);
        return toDto(userRepository.save(user));
    }

    private UserDto toDto(User u) {
        return new UserDto(u.getId(), u.getUsername(), u.getEmail(), u.getRole(), u.isEnabled());
    }
}
