package com.autosales.common.controller;

import com.autosales.common.util.ApiResponse;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.common.util.VinDecodedInfo;
import com.autosales.common.util.VinDecoder;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Public utility endpoint for VIN decoding.
 * Port of COMVINL0.cbl — VIN lookup/decode routine.
 * No authentication required.
 */
@RestController
@RequestMapping("/api/vin")
@Slf4j
@RequiredArgsConstructor
public class VinController {

    private final VinDecoder vinDecoder;
    private final ResponseFormatter responseFormatter;

    @GetMapping("/decode/{vin}")
    public ResponseEntity<ApiResponse<VinDecodedInfo>> decodeVin(@PathVariable String vin) {
        log.info("GET /api/vin/decode/{}", vin);
        VinDecodedInfo decoded = vinDecoder.decode(vin);
        return ResponseEntity.ok(responseFormatter.success(decoded, "VIN decoded successfully"));
    }
}
