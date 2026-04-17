package com.autosales.modules.agent.action;

import com.autosales.common.security.SystemUser;
import com.autosales.common.security.SystemUserRepository;
import com.autosales.common.security.UserRole;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class CurrentUserContext {

    private final SystemUserRepository userRepository;

    public Snapshot current() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String userId = (auth != null && auth.getName() != null) ? auth.getName() : "anonymous";
        SystemUser user = userRepository.findByUserId(userId).orElse(null);
        UserRole role = (user != null && user.getUserType() != null)
                ? UserRole.fromCode(user.getUserType())
                : null;
        String dealerCode = user != null ? user.getDealerCode() : null;
        return new Snapshot(userId, role, dealerCode);
    }

    @Getter
    public static class Snapshot {
        private final String userId;
        private final UserRole role;
        private final String dealerCode;

        public Snapshot(String userId, UserRole role, String dealerCode) {
            this.userId = userId;
            this.role = role;
            this.dealerCode = dealerCode;
        }

        public String roleCode() { return role != null ? role.getCode() : null; }

        public boolean hasRole(UserRole... allowed) {
            if (allowed == null || allowed.length == 0) return true;
            if (role == null) return false;
            for (UserRole r : allowed) if (r == role) return true;
            return false;
        }
    }
}
