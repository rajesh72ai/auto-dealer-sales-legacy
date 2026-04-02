package com.autosales.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

/**
 * JPA configuration enabling auditing support.
 * Activates @CreatedDate and @LastModifiedDate annotations on JPA entities.
 */
@Configuration
@EnableJpaAuditing
public class JpaConfig {
}
