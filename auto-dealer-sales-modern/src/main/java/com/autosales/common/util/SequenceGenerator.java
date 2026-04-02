package com.autosales.common.util;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Concurrency-safe sequence generation using database-level locking.
 * Port of COMSEQL0.cbl — centralized sequence number generator.
 *
 * <p>Each call acquires a row-level lock (SELECT ... FOR UPDATE) on the
 * system_config table, increments the sequence value, and returns a
 * formatted identifier. The dedicated transaction (REQUIRES_NEW) ensures
 * the sequence is committed independently of the caller's transaction.</p>
 */
@Component
public class SequenceGenerator {

    private static final Logger log = LoggerFactory.getLogger(SequenceGenerator.class);

    private static final String SELECT_SQL =
            "SELECT config_value FROM system_config WHERE config_key = ?1 FOR UPDATE";
    private static final String UPDATE_SQL =
            "UPDATE system_config SET config_value = ?1 WHERE config_key = ?2";

    @PersistenceContext
    private EntityManager entityManager;

    /**
     * Generate the next deal number. Format: D-0000000026
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public String generateDealNumber() {
        long next = getNextValue("SEQ_DEAL");
        String formatted = String.format("D-%010d", next);
        log.debug("Generated deal number: {}", formatted);
        return formatted;
    }

    /**
     * Generate the next finance ID. Format: F-000000000016
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public String generateFinanceId() {
        long next = getNextValue("SEQ_FINANCE");
        String formatted = String.format("F-%012d", next);
        log.debug("Generated finance ID: {}", formatted);
        return formatted;
    }

    /**
     * Generate the next registration ID. Format: R-000000000016
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public String generateRegistrationId() {
        long next = getNextValue("SEQ_REGISTRATION");
        String formatted = String.format("R-%012d", next);
        log.debug("Generated registration ID: {}", formatted);
        return formatted;
    }

    /**
     * Generate the next transfer ID. Format: T-000000000016
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public String generateTransferId() {
        long next = getNextValue("SEQ_TRANSFER");
        String formatted = String.format("T-%012d", next);
        log.debug("Generated transfer ID: {}", formatted);
        return formatted;
    }

    /**
     * Generate the next shipment ID. Format: S-000000000016
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public String generateShipmentId() {
        long next = getNextValue("SEQ_SHIPMENT");
        String formatted = String.format("S-%012d", next);
        log.debug("Generated shipment ID: {}", formatted);
        return formatted;
    }

    /**
     * Generate the next stock number. Format: STK-00000016
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public String generateStockNumber() {
        long next = getNextValue("SEQ_STOCK");
        String formatted = String.format("STK-%08d", next);
        log.debug("Generated stock number: {}", formatted);
        return formatted;
    }

    /**
     * Atomically fetch-and-increment a named sequence from system_config.
     *
     * @param sequenceKey the config_key identifying the sequence
     * @return the next sequence value
     */
    private long getNextValue(String sequenceKey) {
        Query selectQuery = entityManager.createNativeQuery(SELECT_SQL);
        selectQuery.setParameter(1, sequenceKey);

        String currentValue = (String) selectQuery.getSingleResult();
        long nextValue = Long.parseLong(currentValue.trim()) + 1;

        Query updateQuery = entityManager.createNativeQuery(UPDATE_SQL);
        updateQuery.setParameter(1, String.valueOf(nextValue));
        updateQuery.setParameter(2, sequenceKey);
        updateQuery.executeUpdate();

        return nextValue;
    }
}
