package com.autosales.modules.chat.dto;

import java.util.List;

public record ChatRequest(List<Message> messages, String provider) {
    public record Message(String role, String content) {}
}
