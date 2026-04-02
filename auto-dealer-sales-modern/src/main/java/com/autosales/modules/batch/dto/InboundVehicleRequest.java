package com.autosales.modules.batch.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InboundVehicleRequest {

    @NotBlank
    private String recordType;

    @NotBlank
    private String vin;

    @NotBlank
    private String makeCode;

    @NotBlank
    private String modelCode;

    private Short modelYear;

    private String trim;

    private String exteriorColor;

    private String interiorColor;

    @NotBlank
    private String dealerCode;

    @Positive
    private BigDecimal invoiceAmount;

    private BigDecimal msrp;
}
