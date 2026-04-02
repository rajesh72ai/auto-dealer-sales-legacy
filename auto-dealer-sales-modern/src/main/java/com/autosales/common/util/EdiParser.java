package com.autosales.common.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * EDI 214 and 856 message parser for vehicle shipment tracking.
 * Port of COMEDIL0.cbl — EDI message parsing module.
 *
 * <p>EDI messages use tilde (~) as the segment terminator and
 * asterisk (*) as the element separator within segments.</p>
 */
@Component
public class EdiParser {

    private static final Logger log = LoggerFactory.getLogger(EdiParser.class);

    private static final String SEGMENT_TERMINATOR = "~";
    private static final String ELEMENT_SEPARATOR = "\\*";

    private static final DateTimeFormatter EDI_DATE_FORMAT = DateTimeFormatter.ofPattern("yyyyMMdd");

    /**
     * Parse an EDI 214 Transportation Carrier Shipment Status Message.
     *
     * <p>Extracts data from segments: ISA, GS, ST, B10, L11, AT7, SE, GE, IEA.
     * Pulls shipmentId from B10, carrier and reference from L11,
     * status/location/date from AT7.</p>
     *
     * @param rawMessage the raw EDI 214 message string
     * @return a {@link ShipmentStatusMessage} with extracted fields
     * @throws IllegalArgumentException if the message cannot be parsed
     */
    public ShipmentStatusMessage parseEdi214(String rawMessage) {
        log.debug("Parsing EDI 214 message, length={}", rawMessage.length());

        Map<String, List<String[]>> segmentMap = parseSegments(rawMessage);

        // ISA — Interchange Control Header
        String isaControlNumber = extractField(segmentMap, "ISA", 0, 13, "");

        // B10 — Beginning Segment for Shipment Status
        String shipmentId = extractField(segmentMap, "B10", 0, 1, "");
        String carrierCode = extractField(segmentMap, "B10", 0, 3, "");

        // L11 — Business Instructions and Reference Number
        String referenceNumber = extractField(segmentMap, "L11", 0, 1, "");

        // AT7 — Shipment Status Details
        String status = extractField(segmentMap, "AT7", 0, 1, "");
        String location = extractField(segmentMap, "AT7", 0, 5, "");
        String dateStr = extractField(segmentMap, "AT7", 0, 3, "");
        LocalDate eventDate = parseDateSafe(dateStr);

        return new ShipmentStatusMessage(shipmentId, carrierCode, status, location, eventDate,
                referenceNumber, isaControlNumber);
    }

    /**
     * Parse an EDI 856 Advance Ship Notice / Manifest.
     *
     * <p>Extracts data from segments: ISA, GS, ST, BSN, HL, TD5, N1, LIN, SN1, SE, GE, IEA.
     * Pulls shipment info from BSN, carrier from TD5, destination from N1,
     * and VINs from LIN segments.</p>
     *
     * @param rawMessage the raw EDI 856 message string
     * @return an {@link AdvanceShipNotice} with extracted fields including VIN list
     * @throws IllegalArgumentException if the message cannot be parsed
     */
    public AdvanceShipNotice parseEdi856(String rawMessage) {
        log.debug("Parsing EDI 856 message, length={}", rawMessage.length());

        Map<String, List<String[]>> segmentMap = parseSegments(rawMessage);

        // ISA — Interchange Control Header
        String isaControlNumber = extractField(segmentMap, "ISA", 0, 13, "");

        // BSN — Beginning Segment for Ship Notice
        String shipmentId = extractField(segmentMap, "BSN", 0, 2, "");
        String dateStr = extractField(segmentMap, "BSN", 0, 3, "");
        LocalDate shipDate = parseDateSafe(dateStr);

        // TD5 — Carrier Details
        String carrier = extractField(segmentMap, "TD5", 0, 3, "");

        // N1 — Name segments (ST = Ship To, SF = Ship From)
        String destination = "";
        String originCode = "";
        List<String[]> n1Segments = segmentMap.getOrDefault("N1", List.of());
        for (String[] fields : n1Segments) {
            if (fields.length > 2) {
                if ("ST".equals(fields[1])) {
                    destination = fields.length > 2 ? fields[2] : "";
                } else if ("SF".equals(fields[1])) {
                    originCode = fields.length > 2 ? fields[2] : "";
                }
            }
        }

        // LIN — Item Identification (VINs)
        List<String> vins = new ArrayList<>();
        List<String[]> linSegments = segmentMap.getOrDefault("LIN", List.of());
        for (String[] fields : linSegments) {
            // LIN*sequence*VN*<VIN> — VN is the Vehicle Number qualifier
            for (int i = 1; i < fields.length - 1; i++) {
                if ("VN".equals(fields[i]) && i + 1 < fields.length) {
                    vins.add(fields[i + 1].trim());
                }
            }
        }

        return new AdvanceShipNotice(shipmentId, shipDate, carrier, destination, originCode,
                vins, isaControlNumber);
    }

    /**
     * Split raw EDI content into a map of segment identifier to list of field arrays.
     */
    private Map<String, List<String[]>> parseSegments(String rawMessage) {
        String cleaned = rawMessage.replaceAll("[\\r\\n]", "").trim();
        String[] segments = cleaned.split(SEGMENT_TERMINATOR);

        return Arrays.stream(segments)
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(s -> s.split(ELEMENT_SEPARATOR, -1))
                .filter(fields -> fields.length > 0 && !fields[0].isEmpty())
                .collect(Collectors.groupingBy(fields -> fields[0]));
    }

    /**
     * Safely extract a field from a specific occurrence of a segment.
     */
    private String extractField(Map<String, List<String[]>> segmentMap, String segmentId,
                                int occurrence, int fieldIndex, String defaultValue) {
        List<String[]> segments = segmentMap.getOrDefault(segmentId, List.of());
        if (occurrence >= segments.size()) {
            return defaultValue;
        }
        String[] fields = segments.get(occurrence);
        if (fieldIndex >= fields.length) {
            return defaultValue;
        }
        return fields[fieldIndex].trim();
    }

    /**
     * Parse a date string in EDI format (yyyyMMdd), returning null on failure.
     */
    private LocalDate parseDateSafe(String dateStr) {
        if (dateStr == null || dateStr.isBlank() || dateStr.length() != 8) {
            return null;
        }
        try {
            return LocalDate.parse(dateStr, EDI_DATE_FORMAT);
        } catch (Exception e) {
            log.warn("Could not parse EDI date: {}", dateStr);
            return null;
        }
    }
}
