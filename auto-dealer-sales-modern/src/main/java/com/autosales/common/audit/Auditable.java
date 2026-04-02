package com.autosales.common.audit;

import java.lang.annotation.*;

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Auditable {
    String action();           // INS, UPD, DEL, INQ, LOG, APV, RJT, PRT
    String entity();           // Table/entity name
    String keyExpression() default ""; // SpEL expression for key value
}
