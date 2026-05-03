package com.autosales.common.security;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * REST controller for user administration.
 * Port of USRADM00.cbl — system user master file maintenance.
 */
@RestController
@RequestMapping("/api/admin/users")
@PreAuthorize("hasAnyRole('ADMIN','OPERATOR')")
@Slf4j
public class UserAdminController {

    private final SystemUserRepository systemUserRepository;
    private final PasswordEncoder passwordEncoder;

    public UserAdminController(SystemUserRepository systemUserRepository,
                               PasswordEncoder passwordEncoder) {
        this.systemUserRepository = systemUserRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @GetMapping
    public PaginatedResponse<SystemUser> listUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String dealerCode) {
        Page<SystemUser> result;
        if (dealerCode != null && !dealerCode.isBlank()) {
            List<SystemUser> byDealer = systemUserRepository.findByDealerCode(dealerCode);
            int start = Math.min(page * size, byDealer.size());
            int end = Math.min(start + size, byDealer.size());
            List<SystemUser> pageContent = byDealer.subList(start, end);
            return new PaginatedResponse<>("success", null, pageContent, page,
                    (int) Math.ceil((double) byDealer.size() / size), byDealer.size(),
                    LocalDateTime.now());
        } else {
            result = systemUserRepository.findAll(PageRequest.of(page, size, Sort.by("userId")));
            return new PaginatedResponse<>("success", null, result.getContent(), page,
                    result.getTotalPages(), result.getTotalElements(), LocalDateTime.now());
        }
    }

    @GetMapping("/{userId}")
    public ApiResponse<SystemUser> getUser(@PathVariable String userId) {
        SystemUser user = systemUserRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found: " + userId));
        return new ApiResponse<>("success", null, user, LocalDateTime.now());
    }

    @PostMapping
    public ResponseEntity<ApiResponse<SystemUser>> createUser(@RequestBody Map<String, Object> request) {
        String userId = (String) request.get("userId");
        if (systemUserRepository.existsById(userId)) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(new ApiResponse<>("error", "User ID already exists", null, LocalDateTime.now()));
        }

        SystemUser user = SystemUser.builder()
                .userId(userId)
                .userName((String) request.get("userName"))
                .passwordHash(passwordEncoder.encode((String) request.get("password")))
                .userType((String) request.get("userType"))
                .dealerCode((String) request.get("dealerCode"))
                .activeFlag((String) request.getOrDefault("activeFlag", "Y"))
                .failedAttempts(0)
                .lockedFlag("N")
                // AI agent policy (B-tokenadmin) — defaults: agent enabled, no override
                .agentEnabled(toBool(request.get("agentEnabled"), true))
                .agentDailyTokenQuota(toInteger(request.get("agentDailyTokenQuota")))
                .agentNotes((String) request.get("agentNotes"))
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();

        SystemUser saved = systemUserRepository.save(user);
        log.info("Created user: {}", saved.getUserId());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>("success", "User created", saved, LocalDateTime.now()));
    }

    @PutMapping("/{userId}")
    public ApiResponse<SystemUser> updateUser(@PathVariable String userId,
                                              @RequestBody Map<String, Object> request) {
        SystemUser user = systemUserRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found: " + userId));

        if (request.containsKey("userName")) user.setUserName((String) request.get("userName"));
        if (request.containsKey("userType")) user.setUserType((String) request.get("userType"));
        if (request.containsKey("dealerCode")) user.setDealerCode((String) request.get("dealerCode"));
        if (request.containsKey("activeFlag")) user.setActiveFlag((String) request.get("activeFlag"));
        // AI agent policy (B-tokenadmin)
        if (request.containsKey("agentEnabled")) user.setAgentEnabled(toBool(request.get("agentEnabled"), true));
        if (request.containsKey("agentDailyTokenQuota")) user.setAgentDailyTokenQuota(toInteger(request.get("agentDailyTokenQuota")));
        if (request.containsKey("agentNotes")) user.setAgentNotes((String) request.get("agentNotes"));
        user.setUpdatedTs(LocalDateTime.now());

        SystemUser saved = systemUserRepository.save(user);
        log.info("Updated user: {}", saved.getUserId());
        return new ApiResponse<>("success", "User updated", saved, LocalDateTime.now());
    }

    @PostMapping("/{userId}/reset-password")
    public ApiResponse<Void> resetPassword(@PathVariable String userId,
                                           @RequestBody Map<String, String> request) {
        SystemUser user = systemUserRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found: " + userId));

        String newPassword = request.get("newPassword");
        if (newPassword == null || newPassword.isBlank()) {
            throw new RuntimeException("New password is required");
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        user.setUpdatedTs(LocalDateTime.now());
        systemUserRepository.save(user);
        log.info("Password reset for user: {}", userId);
        return new ApiResponse<>("success", "Password reset successfully", null, LocalDateTime.now());
    }

    @PostMapping("/{userId}/unlock")
    public ApiResponse<SystemUser> unlockUser(@PathVariable String userId) {
        SystemUser user = systemUserRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found: " + userId));

        user.setFailedAttempts(0);
        user.setLockedFlag("N");
        user.setUpdatedTs(LocalDateTime.now());
        SystemUser saved = systemUserRepository.save(user);
        log.info("Unlocked user: {}", userId);
        return new ApiResponse<>("success", "User unlocked", saved, LocalDateTime.now());
    }

    /**
     * Coerces a request value to Boolean. JSON booleans come through as
     * {@code java.lang.Boolean}; some clients send strings. {@code null}
     * returns the supplied default.
     */
    private static Boolean toBool(Object o, boolean dflt) {
        if (o == null) return dflt;
        if (o instanceof Boolean b) return b;
        return Boolean.parseBoolean(o.toString().trim());
    }

    /** Coerces a request value to Integer; null/blank → null (use system default). */
    private static Integer toInteger(Object o) {
        if (o == null) return null;
        if (o instanceof Number n) return n.intValue();
        String s = o.toString().trim();
        if (s.isEmpty()) return null;
        try { return Integer.parseInt(s); } catch (NumberFormatException nfe) { return null; }
    }

    @PostMapping("/{userId}/lock")
    public ApiResponse<SystemUser> lockUser(@PathVariable String userId) {
        SystemUser user = systemUserRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found: " + userId));

        user.setLockedFlag("Y");
        user.setUpdatedTs(LocalDateTime.now());
        SystemUser saved = systemUserRepository.save(user);
        log.info("Locked user: {}", userId);
        return new ApiResponse<>("success", "User locked", saved, LocalDateTime.now());
    }
}
