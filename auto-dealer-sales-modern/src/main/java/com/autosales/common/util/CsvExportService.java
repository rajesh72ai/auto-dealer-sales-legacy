package com.autosales.common.util;

import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.function.Function;

/**
 * Generic CSV export utility service.
 * Generates CSV content from any list of objects and builds download-ready HTTP responses.
 */
@Service
public class CsvExportService {

    private static final byte[] UTF8_BOM = new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF};

    /**
     * Generate CSV content string from a list of data objects.
     *
     * @param data      the list of objects to export
     * @param headers   the CSV column headers
     * @param rowMapper function that maps each object to an array of cell values
     * @return the complete CSV content as a string
     */
    public String exportToCsv(List<?> data, String[] headers, Function<Object, String[]> rowMapper) {
        StringBuilder sb = new StringBuilder();

        // Header row
        sb.append(String.join(",", headers)).append("\r\n");

        // Data rows
        for (Object item : data) {
            String[] cells = rowMapper.apply(item);
            for (int i = 0; i < cells.length; i++) {
                if (i > 0) sb.append(",");
                sb.append(escapeCsvField(cells[i]));
            }
            sb.append("\r\n");
        }

        return sb.toString();
    }

    /**
     * Build a download-ready ResponseEntity with CSV content.
     * Includes UTF-8 BOM for Excel compatibility and Content-Disposition attachment header.
     *
     * @param csvContent the CSV content string
     * @param filename   the download filename (should end with .csv)
     * @return ResponseEntity with byte[] body ready for download
     */
    public ResponseEntity<byte[]> buildCsvResponse(String csvContent, String filename) {
        byte[] csvBytes = csvContent.getBytes(StandardCharsets.UTF_8);
        byte[] responseBytes = new byte[UTF8_BOM.length + csvBytes.length];
        System.arraycopy(UTF8_BOM, 0, responseBytes, 0, UTF8_BOM.length);
        System.arraycopy(csvBytes, 0, responseBytes, UTF8_BOM.length, csvBytes.length);

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(responseBytes);
    }

    private String escapeCsvField(String field) {
        if (field == null) {
            return "";
        }
        if (field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r")) {
            return "\"" + field.replace("\"", "\"\"") + "\"";
        }
        return field;
    }
}
