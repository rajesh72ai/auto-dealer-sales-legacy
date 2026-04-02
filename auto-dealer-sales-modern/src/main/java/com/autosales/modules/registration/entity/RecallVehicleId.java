package com.autosales.modules.registration.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RecallVehicleId implements Serializable {

    private String recallId;
    private String vin;
}
