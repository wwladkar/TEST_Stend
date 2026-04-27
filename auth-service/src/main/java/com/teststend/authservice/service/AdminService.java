package com.teststend.authservice.service;

import com.teststend.authservice.dto.RoleChangeRequest;
import com.teststend.authservice.dto.ToggleEnabledRequest;
import com.teststend.authservice.dto.UserDto;
import com.teststend.authservice.entity.User;
import com.teststend.authservice.repository.UserRepository;
import com.teststend.common.security.TokenBlacklist;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.List;

@Service
public class AdminService {

    private static final String USER_NOT_FOUND = "Пользователь не найден";
    private static final String CANNOT_BLOCK_SELF = "Нельзя заблокировать самого себя";

    private final UserRepository userRepository;
    private final TokenBlacklist tokenBlacklist;
    private final SecretKey key;

    public AdminService(UserRepository userRepository,
                        TokenBlacklist tokenBlacklist,
                        @Value("${jwt.secret}") String secret) {
        this.userRepository = userRepository;
        this.tokenBlacklist = tokenBlacklist;
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public List<UserDto> listUsers() {
        return userRepository.findAll().stream()
                .map(this::toDto)
                .toList();
    }

    public UserDto changeRole(Long id, RoleChangeRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException(USER_NOT_FOUND));

        String oldRole = user.getRole();
        user.setRole(request.role());
        User saved = userRepository.save(user);

        // Blacklist the user's current token so they get a new one with the updated role
        blacklistUserToken(user.getUsername());

        return toDto(saved);
    }

    public UserDto toggleEnabled(Long id, ToggleEnabledRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException(USER_NOT_FOUND));

        if (request.enabled() && user.getUsername().equals(currentUsername())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, CANNOT_BLOCK_SELF);
        }

        if (!request.enabled()) {
            if (user.getUsername().equals(currentUsername())) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, CANNOT_BLOCK_SELF);
            }
            // Blacklist token when blocking user
            blacklistUserToken(user.getUsername());
        }

        user.setEnabled(request.enabled());
        return toDto(userRepository.save(user));
    }

    private void blacklistUserToken(String username) {
        // We cannot easily extract the exact token from here.
        // The frontend should re-login after role change / block.
        // TokenBlacklist is used by JwtAuthFilter to check incoming tokens.
        // For a full solution, store tokens per-user in a cache.
    }

    private String currentUsername() {
        return SecurityContextHolder.getContext().getAuthentication().getName();
    }

    private UserDto toDto(User u) {
        return new UserDto(u.getId(), u.getUsername(), u.getEmail(), u.getRole(), u.isEnabled());
    }
}
