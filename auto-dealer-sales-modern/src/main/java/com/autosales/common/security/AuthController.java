package com.autosales.common.security;

import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private static final Logger log = LoggerFactory.getLogger(AuthController.class);
    private static final int MAX_FAILED_ATTEMPTS = 5;

    private final SystemUserRepository systemUserRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    public AuthController(SystemUserRepository systemUserRepository,
                          PasswordEncoder passwordEncoder,
                          JwtTokenProvider jwtTokenProvider) {
        this.systemUserRepository = systemUserRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenProvider = jwtTokenProvider;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody AuthRequest request) {
        log.info("Login attempt for user: {}", request.getUserId());

        SystemUser user = systemUserRepository.findByUserId(request.getUserId()).orElse(null);

        if (user == null) {
            log.warn("Login failed - user not found: {}", request.getUserId());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Invalid credentials"));
        }

        if (!"Y".equals(user.getActiveFlag())) {
            log.warn("Login failed - inactive user: {}", request.getUserId());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Account is inactive"));
        }

        if ("Y".equals(user.getLockedFlag())) {
            log.warn("Login failed - locked user: {}", request.getUserId());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Account is locked due to too many failed attempts"));
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            log.warn("Login failed - invalid password for user: {}", request.getUserId());
            int attempts = (user.getFailedAttempts() != null ? user.getFailedAttempts() : 0) + 1;
            user.setFailedAttempts(attempts);
            user.setUpdatedTs(LocalDateTime.now());

            if (attempts >= MAX_FAILED_ATTEMPTS) {
                user.setLockedFlag("Y");
                log.warn("Account locked after {} failed attempts: {}", attempts, request.getUserId());
            }

            systemUserRepository.save(user);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Invalid credentials"));
        }

        // Successful login
        UserRole role = UserRole.fromCode(user.getUserType());

        user.setFailedAttempts(0);
        user.setLastLoginTs(LocalDateTime.now());
        user.setUpdatedTs(LocalDateTime.now());
        systemUserRepository.save(user);

        String accessToken = jwtTokenProvider.generateAccessToken(
                user.getUserId(), role.name(), user.getDealerCode(), user.getUserName());
        String refreshToken = jwtTokenProvider.generateRefreshToken(user.getUserId());

        log.info("Login successful for user: {}", request.getUserId());

        AuthResponse response = AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .userId(user.getUserId())
                .userName(user.getUserName())
                .userType(role.name())
                .dealerCode(user.getDealerCode())
                .build();

        return ResponseEntity.ok(response);
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(@RequestBody Map<String, String> request) {
        String refreshToken = request.get("refreshToken");

        if (refreshToken == null || !jwtTokenProvider.validateToken(refreshToken)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Invalid or expired refresh token"));
        }

        String userId = jwtTokenProvider.getUserIdFromToken(refreshToken);

        SystemUser user = systemUserRepository.findByUserId(userId).orElse(null);
        if (user == null || !"Y".equals(user.getActiveFlag()) || "Y".equals(user.getLockedFlag())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "User account is not valid"));
        }

        UserRole role = UserRole.fromCode(user.getUserType());
        String newAccessToken = jwtTokenProvider.generateAccessToken(
                user.getUserId(), role.name(), user.getDealerCode(), user.getUserName());

        log.info("Token refreshed for user: {}", userId);

        return ResponseEntity.ok(Map.of(
                "accessToken", newAccessToken,
                "userId", user.getUserId()
        ));
    }
}
