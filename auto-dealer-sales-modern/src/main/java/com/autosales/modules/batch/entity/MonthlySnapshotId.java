package com.autosales.modules.batch.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MonthlySnapshotId implements Serializable {

    private String snapshotMonth;
    private String dealerCode;
}
