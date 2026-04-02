package com.autosales.modules.batch.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CheckpointActionRequest {

    @NotBlank
    private String programId;

    @NotBlank
    @Pattern(regexp = "DISP|RESET|COMPL", message = "Action must be DISP, RESET, or COMPL")
    private String action;
}
