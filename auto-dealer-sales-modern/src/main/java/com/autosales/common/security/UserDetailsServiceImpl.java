package com.autosales.common.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UserDetailsServiceImpl implements UserDetailsService {

    private static final Logger log = LoggerFactory.getLogger(UserDetailsServiceImpl.class);

    private final SystemUserRepository systemUserRepository;

    public UserDetailsServiceImpl(SystemUserRepository systemUserRepository) {
        this.systemUserRepository = systemUserRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String userId) throws UsernameNotFoundException {
        SystemUser systemUser = systemUserRepository.findByUserId(userId)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + userId));

        if (!"Y".equals(systemUser.getActiveFlag())) {
            log.warn("Login attempt for inactive user: {}", userId);
            throw new UsernameNotFoundException("User account is inactive: " + userId);
        }

        if ("Y".equals(systemUser.getLockedFlag())) {
            log.warn("Login attempt for locked user: {}", userId);
            throw new UsernameNotFoundException("User account is locked: " + userId);
        }

        UserRole role = UserRole.fromCode(systemUser.getUserType());
        String springRole = "ROLE_" + role.name();

        return new User(
                systemUser.getUserId(),
                systemUser.getPasswordHash(),
                List.of(new SimpleGrantedAuthority(springRole))
        );
    }
}
