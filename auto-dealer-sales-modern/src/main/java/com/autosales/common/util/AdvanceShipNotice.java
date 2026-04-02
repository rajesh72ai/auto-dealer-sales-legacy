package com.autosales.common.util;

import java.time.LocalDate;
import java.util.List;

/**
 * Parsed EDI 856 Advance Ship Notice.
 * Port of COMEDIL0.cbl — 856 Ship Notice/Manifest output area.
 */
public record AdvanceShipNotice(
        String shipmentId,
        LocalDate shipDate,
        String carrier,
        String destination,
        String originCode,
        List<String> vins,
        String isaControlNumber
) {
}
