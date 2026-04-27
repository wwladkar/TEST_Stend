package com.teststend.authservice.controller;

import com.teststend.authservice.dto.UserDto;
import com.teststend.authservice.service.UserService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public UserDto me() {
        return userService.me();
    }
}
