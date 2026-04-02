package com.autosales.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * OpenAPI / Swagger configuration for the AUTOSALES API.
 * Provides API documentation at /swagger-ui.html with JWT bearer authentication.
 */
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI autosalesOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("AUTOSALES API")
                        .description("Auto Dealer Sales & Reporting System")
                        .version("1.0.0"))
                .addSecurityItem(new SecurityRequirement().addList("Bearer"))
                .components(new Components()
                        .addSecuritySchemes("Bearer", new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")));
    }
}
