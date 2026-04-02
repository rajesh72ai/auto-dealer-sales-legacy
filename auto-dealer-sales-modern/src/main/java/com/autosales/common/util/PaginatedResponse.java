package com.autosales.common.util;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Paginated API response wrapper with page metadata.
 * Port of COMMSGL0.cbl — common message/response formatting with scrolling support.
 *
 * @param <T> the type of the content items
 */
public record PaginatedResponse<T>(
        String status,
        String message,
        List<T> content,
        int page,
        int totalPages,
        long totalElements,
        LocalDateTime timestamp
) {
}
