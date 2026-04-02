package com.autosales.common.audit;

import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.expression.EvaluationContext;
import org.springframework.expression.ExpressionParser;
import org.springframework.expression.spel.standard.SpelExpressionParser;
import org.springframework.expression.spel.support.StandardEvaluationContext;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Aspect
@Component
public class AuditAspect {

    private static final Logger log = LoggerFactory.getLogger(AuditAspect.class);
    private static final ExpressionParser SPEL_PARSER = new SpelExpressionParser();

    private final AuditLogRepository auditLogRepository;

    public AuditAspect(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    @Around("@annotation(auditable)")
    public Object audit(ProceedingJoinPoint joinPoint, Auditable auditable) throws Throwable {
        // Always execute the target method first
        Object result = joinPoint.proceed();

        // Audit logging — never fails the main transaction
        try {
            String userId = resolveUserId();
            String programId = resolveProgramId(joinPoint);
            String keyValue = resolveKeyValue(auditable.keyExpression(), joinPoint);

            AuditLog entry = new AuditLog();
            entry.setUserId(userId);
            entry.setProgramId(programId);
            entry.setActionType(auditable.action());
            entry.setTableName(auditable.entity());
            entry.setKeyValue(keyValue);
            entry.setAuditTs(LocalDateTime.now());

            auditLogRepository.save(entry);
            log.debug("Audit logged: {} {} {} key={}", userId, auditable.action(), auditable.entity(), keyValue);
        } catch (Exception ex) {
            log.warn("Audit logging failed (non-fatal): {}", ex.getMessage());
        }

        return result;
    }

    private String resolveUserId() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.getName() != null) {
                return auth.getName();
            }
        } catch (Exception ex) {
            log.debug("Could not resolve user from SecurityContext: {}", ex.getMessage());
        }
        return "SYSTEM";
    }

    private String resolveProgramId(ProceedingJoinPoint joinPoint) {
        String className = joinPoint.getTarget().getClass().getSimpleName();
        return className.length() > 8 ? className.substring(0, 8) : className;
    }

    private String resolveKeyValue(String keyExpression, ProceedingJoinPoint joinPoint) {
        if (keyExpression == null || keyExpression.isBlank()) {
            return "";
        }
        try {
            MethodSignature sig = (MethodSignature) joinPoint.getSignature();
            String[] paramNames = sig.getParameterNames();
            Object[] args = joinPoint.getArgs();

            EvaluationContext ctx = new StandardEvaluationContext();
            if (paramNames != null) {
                for (int i = 0; i < paramNames.length; i++) {
                    ((StandardEvaluationContext) ctx).setVariable(paramNames[i], args[i]);
                }
            }

            Object value = SPEL_PARSER.parseExpression(keyExpression).getValue(ctx);
            return value != null ? value.toString() : "";
        } catch (Exception ex) {
            log.debug("SpEL evaluation failed for '{}': {}", keyExpression, ex.getMessage());
            return "";
        }
    }
}
