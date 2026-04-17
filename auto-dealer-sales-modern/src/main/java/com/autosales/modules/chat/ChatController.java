package com.autosales.modules.chat;

import com.autosales.modules.chat.dto.ChatRequest;
import com.autosales.modules.chat.dto.ChatResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','SALESPERSON','FINANCE','CLERK','OPERATOR')")
public class ChatController {

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @PostMapping
    public ResponseEntity<ChatResponse> chat(@RequestBody ChatRequest request) {
        try {
            ChatResponse response = chatService.chat(request);
            return ResponseEntity.ok(response);
        } catch (RateLimitException e) {
            return ResponseEntity.ok(new ChatResponse(e.getMessage(), ""));
        }
    }

    @GetMapping("/providers")
    public ResponseEntity<Map<String, Object>> getProviders() {
        List<LlmClient.ProviderInfo> providers = chatService.getAvailableProviders();
        String defaultProvider = chatService.getDefaultProvider();
        return ResponseEntity.ok(Map.of(
                "providers", providers,
                "defaultProvider", defaultProvider
        ));
    }
}
