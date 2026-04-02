package com.autosales.common.util;

import java.time.LocalDate;

/**
 * Parsed EDI 214 shipment status message.
 * Port of COMEDIL0.cbl — 214 Transportation Carrier Shipment Status output area.
 */
public record ShipmentStatusMessage(
        String shipmentId,
        String carrierCode,
        String status,
        String location,
        LocalDate eventDate,
        String referenceNumber,
        String isaControlNumber
) {
}
