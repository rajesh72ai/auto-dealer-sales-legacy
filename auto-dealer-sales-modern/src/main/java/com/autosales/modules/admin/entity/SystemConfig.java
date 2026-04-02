package com.autosales.modules.admin.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "system_config")
public class SystemConfig {

    @Id
    @Column(name = "config_key", length = 30)
    private String configKey;

    @Column(name = "config_value", nullable = false, length = 100)
    private String configValue;

    @Column(name = "config_desc", length = 60)
    private String configDesc;

    @Column(name = "updated_by", length = 8)
    private String updatedBy;

    @Column(name = "updated_ts", nullable = false)
    private LocalDateTime updatedTs;
}
