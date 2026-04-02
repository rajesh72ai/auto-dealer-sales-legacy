package com.autosales.modules.admin.repository;

import com.autosales.modules.admin.entity.Lender;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LenderRepository extends JpaRepository<Lender, String> {

    List<Lender> findByActiveFlag(String activeFlag);

    List<Lender> findByLenderType(String lenderType);
}
