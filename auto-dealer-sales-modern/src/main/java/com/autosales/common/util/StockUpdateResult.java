package com.autosales.common.util;

/**
 * Stock position mutation result.
 * Port of COMSTCK0.cbl stock update output area.
 */
public record StockUpdateResult(
        String vin,
        String oldStatus,
        String newStatus,
        String dealerCode,
        boolean success,
        String message
) {
}
