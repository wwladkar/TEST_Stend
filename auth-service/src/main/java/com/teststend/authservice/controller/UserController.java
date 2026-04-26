package com.teststend.authservice.controller;

import com.teststend.authservice.dto.UserDto;
import com.teststend.authservice.entity.User;
import com.teststend.authservice.repository.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserRepository userRepository;

    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping("/me")
    public UserDto me() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));
        return new UserDto(user.getId(), user.getUsername(), user.getEmail(), user.getRole(), user.isEnabled());
    }
}
