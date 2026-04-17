package com.autosales.common.audit;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.PaginatedResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * REST controller for audit log administration and search.
 * Port of AUDQRY00.cbl — audit trail inquiry/display program.
 */
@RestController
@RequestMapping("/api/admin/audit-log")
@PreAuthorize("hasAnyRole('ADMIN','OPERATOR')")
@Slf4j
public class AuditLogController {

    private final AuditLogRepository auditLogRepository;

    public AuditLogController(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    @GetMapping
    public PaginatedResponse<AuditLog> searchAuditLog(
            @RequestParam(required = false) String userId,
            @RequestParam(required = false) String tableName,
            @RequestParam(required = false) String actionType,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        // Normalize empty strings to null for JPQL query
        String userIdParam = (userId != null && !userId.isBlank()) ? userId : null;
        String tableNameParam = (tableName != null && !tableName.isBlank()) ? tableName : null;
        String actionTypeParam = (actionType != null && !actionType.isBlank()) ? actionType : null;

        Page<AuditLog> result = auditLogRepository.search(
                userIdParam, tableNameParam, actionTypeParam, from, to,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "auditTs")));

        return new PaginatedResponse<>("success", null, result.getContent(), page,
                result.getTotalPages(), result.getTotalElements(), LocalDateTime.now());
    }

    @GetMapping("/stats")
    public ApiResponse<Map<String, Long>> getAuditStats() {
        List<Object[]> rawCounts = auditLogRepository.countByActionType();
        Map<String, Long> stats = new LinkedHashMap<>();
        for (Object[] row : rawCounts) {
            stats.put((String) row[0], (Long) row[1]);
        }
        return new ApiResponse<>("success", null, stats, LocalDateTime.now());
    }
}
