package com.autosales;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

/**
 * {@code @EnableAsync} added in B3a+B3b — lets services like
 * {@code BigQueryAnalyticsService} fire fire-and-forget inserts to BigQuery
 * without blocking the agent's tool-call audit path.
 */
@SpringBootApplication
@EnableAsync
public class AutosalesApplication {

    public static void main(String[] args) {
        SpringApplication.run(AutosalesApplication.class, args);
    }
}
