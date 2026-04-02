package com.autosales.modules.admin.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ModelMasterId implements Serializable {

    private Short modelYear;
    private String makeCode;
    private String modelCode;
}
