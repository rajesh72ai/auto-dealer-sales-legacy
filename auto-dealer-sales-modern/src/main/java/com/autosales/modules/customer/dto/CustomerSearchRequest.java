package com.autosales.modules.customer.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerSearchRequest {

    @NotBlank @Pattern(regexp = "LN|FN|PH|DL|ID", message = "Search type must be LN, FN, PH, DL, or ID")
    private String searchType;

    @NotBlank
    private String searchValue;

    @NotBlank @Size(max = 5)
    private String dealerCode;
}
