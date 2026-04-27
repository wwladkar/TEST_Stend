package com.teststend.authservice.service;

import com.teststend.authservice.dto.AuthResponse;
import com.teststend.authservice.dto.LoginRequest;
import com.teststend.authservice.dto.RegisterRequest;
import com.teststend.authservice.entity.User;
import com.teststend.authservice.repository.UserRepository;
import com.teststend.common.security.JwtTokenProvider;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AuthService {

    private static final String INVALID_CREDENTIALS = "Неверное имя пользователя или пароль";
    private static final String USER_EXISTS = "Пользователь с таким именем или email уже существует";
    private static final String ACCOUNT_BLOCKED = "Аккаунт заблокирован";

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtTokenProvider jwtTokenProvider) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenProvider = jwtTokenProvider;
    }

    public AuthResponse register(@Valid RegisterRequest request) {
        if (userRepository.existsByUsername(request.username()) || userRepository.existsByEmail(request.email())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, USER_EXISTS);
        }

        User user = new User(
                request.username(),
                request.email(),
                passwordEncoder.encode(request.password()),
                "USER"
        );
        userRepository.save(user);

        String token = jwtTokenProvider.generateToken(user.getUsername(), user.getRole());
        return new AuthResponse(token, user.getUsername(), user.getRole());
    }

    public AuthResponse login(@Valid LoginRequest request) {
        User user = userRepository.findByUsername(request.username())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, INVALID_CREDENTIALS));

        if (!passwordEncoder.matches(request.password(), user.getPassword())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, INVALID_CREDENTIALS);
        }

        if (!user.isEnabled()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, ACCOUNT_BLOCKED);
        }

        String token = jwtTokenProvider.generateToken(user.getUsername(), user.getRole());
        return new AuthResponse(token, user.getUsername(), user.getRole());
    }
}
