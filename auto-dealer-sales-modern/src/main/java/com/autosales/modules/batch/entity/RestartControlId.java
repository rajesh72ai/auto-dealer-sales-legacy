package com.autosales.modules.batch.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RestartControlId implements Serializable {

    private String jobName;
    private String stepName;
}
