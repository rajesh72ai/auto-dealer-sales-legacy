package com.autosales.modules.agent.action;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Converts an agent-supplied payload Map into a typed Request DTO AND runs
 * JSR-303 (jakarta.validation) bean validation on the result.
 *
 * Previously each handler used {@code mapper.convertValue(...)} directly,
 * which bypasses {@code @Pattern}/{@code @Size}/{@code @NotBlank}/etc. Bad
 * input silently flowed to the service and failed mid-INSERT with raw
 * {@code ERROR: value too long for type character varying(N)} or similar.
 * See defect #43 (conditionCode) and feedback_skill_vs_dto_drift.md.
 *
 * With this helper, skill-vs-DTO drift surfaces at dry-run with a clean
 * {@code IllegalArgumentException} listing all violations by field path.
 */
@Component
@RequiredArgsConstructor
public class PayloadValidator {

    private final ObjectMapper mapper;
    private final Validator validator;

    /**
     * Convert the payload map to {@code type}, then validate. Throws
     * {@link IllegalArgumentException} with all violations if invalid.
     *
     * @param payload raw fields (from the agent's proposal payload)
     * @param type    target DTO class with JSR-303 annotations
     * @return a validated instance of {@code type}
     */
    public <T> T convertAndValidate(Map<String, Object> payload, Class<T> type) {
        T dto = mapper.convertValue(payload, type);
        Set<ConstraintViolation<T>> violations = validator.validate(dto);
        if (!violations.isEmpty()) {
            String msg = violations.stream()
                    .map(v -> v.getPropertyPath() + ": " + v.getMessage())
                    .sorted()
                    .collect(Collectors.joining("; "));
            throw new IllegalArgumentException("Invalid payload for " + type.getSimpleName() + " — " + msg);
        }
        return dto;
    }
}
