package com.teststend.authservice.service;

import com.teststend.authservice.dto.UserDto;
import com.teststend.authservice.entity.User;
import com.teststend.authservice.repository.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public UserDto me() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));
        return new UserDto(user.getId(), user.getUsername(), user.getEmail(), user.getRole(), user.isEnabled());
    }
}
