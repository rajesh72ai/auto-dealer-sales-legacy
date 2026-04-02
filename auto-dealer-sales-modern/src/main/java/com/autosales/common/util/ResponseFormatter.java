package com.autosales.common.util;

import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Standardized API response formatter for all controller endpoints.
 * Port of COMMSGL0.cbl — common message formatting and response assembly module.
 *
 * <p>Provides factory methods to create consistent {@link ApiResponse} and
 * {@link PaginatedResponse} wrappers for all API responses.</p>
 */
@Component
public class ResponseFormatter {

    private static final String STATUS_SUCCESS = "success";
    private static final String STATUS_ERROR = "error";

    /**
     * Create a success response with data and no message.
     *
     * @param data the response payload
     * @param <T>  the payload type
     * @return an {@link ApiResponse} with status "success"
     */
    public <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(STATUS_SUCCESS, null, data, LocalDateTime.now());
    }

    /**
     * Create a success response with data and a message.
     *
     * @param data    the response payload
     * @param message a human-readable message
     * @param <T>     the payload type
     * @return an {@link ApiResponse} with status "success"
     */
    public <T> ApiResponse<T> success(T data, String message) {
        return new ApiResponse<>(STATUS_SUCCESS, message, data, LocalDateTime.now());
    }

    /**
     * Create an error response with a message and no data.
     *
     * @param message the error message
     * @return an {@link ApiResponse} with status "error" and null data
     */
    public ApiResponse<Void> error(String message) {
        return new ApiResponse<>(STATUS_ERROR, message, null, LocalDateTime.now());
    }

    /**
     * Create a paginated response wrapping a list of items with page metadata.
     *
     * @param content       the page content
     * @param page          the current page number (zero-based)
     * @param totalPages    the total number of pages
     * @param totalElements the total number of elements across all pages
     * @param <T>           the content item type
     * @return a {@link PaginatedResponse} with status "success"
     */
    public <T> PaginatedResponse<T> paginated(List<T> content, int page, int totalPages, long totalElements) {
        return new PaginatedResponse<>(STATUS_SUCCESS, null, content, page, totalPages, totalElements,
                LocalDateTime.now());
    }
}
