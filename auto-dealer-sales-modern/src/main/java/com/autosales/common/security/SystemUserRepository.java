package com.autosales.common.security;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SystemUserRepository extends JpaRepository<SystemUser, String> {

    Optional<SystemUser> findByUserId(String userId);

    List<SystemUser> findByDealerCode(String dealerCode);
}
