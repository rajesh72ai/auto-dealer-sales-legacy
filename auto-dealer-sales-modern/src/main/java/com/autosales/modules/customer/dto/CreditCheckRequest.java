package com.autosales.modules.customer.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreditCheckRequest {

    @NotNull
    private Integer customerId;

    @DecimalMin(value = "0.00")
    private BigDecimal monthlyDebt;

    @Pattern(regexp = "EQ|TU|EX", message = "Bureau code must be EQ, TU, or EX")
    @Builder.Default
    private String bureauCode = "EQ";
}
