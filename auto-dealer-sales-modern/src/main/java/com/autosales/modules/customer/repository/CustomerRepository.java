package com.autosales.modules.customer.repository;

import com.autosales.modules.customer.entity.Customer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CustomerRepository extends JpaRepository<Customer, Integer> {

    List<Customer> findByLastNameAndFirstName(String lastName, String firstName);

    List<Customer> findByDealerCode(String dealerCode);

    List<Customer> findByLastNameStartingWithIgnoreCase(String prefix);

    Page<Customer> findByDealerCode(String dealerCode, Pageable pageable);

    Page<Customer> findByDealerCodeAndLastNameContainingIgnoreCase(String dealerCode, String lastName, Pageable pageable);

    Page<Customer> findByDealerCodeAndFirstNameContainingIgnoreCase(String dealerCode, String firstName, Pageable pageable);

    Page<Customer> findByDealerCodeAndCellPhone(String dealerCode, String cellPhone, Pageable pageable);

    Page<Customer> findByDealerCodeAndHomePhone(String dealerCode, String homePhone, Pageable pageable);

    Optional<Customer> findByLastNameAndCellPhoneAndDealerCode(String lastName, String cellPhone, String dealerCode);

    List<Customer> findByDealerCodeAndFirstNameIgnoreCaseAndLastNameIgnoreCase(
            String dealerCode, String firstName, String lastName);
}
