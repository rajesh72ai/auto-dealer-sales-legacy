package com.autosales.common.exception;

public class DuplicateEntityException extends RuntimeException {
    public DuplicateEntityException(String entity, String key) {
        super(entity + " already exists with key: " + key);
    }
}
