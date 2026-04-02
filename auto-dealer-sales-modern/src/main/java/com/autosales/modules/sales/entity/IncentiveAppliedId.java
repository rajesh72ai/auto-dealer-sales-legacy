package com.autosales.modules.sales.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class IncentiveAppliedId implements Serializable {

    private String dealNumber;
    private String incentiveId;
}
