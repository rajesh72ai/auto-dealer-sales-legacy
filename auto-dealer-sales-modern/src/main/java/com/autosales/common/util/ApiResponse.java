package com.autosales.common.util;

import java.time.LocalDateTime;

/**
 * Standardized API response wrapper.
 * Port of COMMSGL0.cbl — common message/response formatting area.
 *
 * @param <T> the type of the response data payload
 */
public record ApiResponse<T>(
        String status,
        String message,
        T data,
        LocalDateTime timestamp
) {
}
