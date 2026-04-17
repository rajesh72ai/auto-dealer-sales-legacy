package com.autosales.modules.agent.action;

import com.autosales.modules.sales.dto.TradeInRequest;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.validation.Validation;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class PayloadValidatorTest {

    private final PayloadValidator validator = new PayloadValidator(
            new ObjectMapper(),
            Validation.buildDefaultValidatorFactory().getValidator());

    @Test
    void convertAndValidate_happyPath_returnsDto() {
        Map<String, Object> payload = Map.of(
                "tradeYear", 2019,
                "tradeMake", "HON",
                "tradeModel", "CIVIC",
                "odometer", 45000,
                "conditionCode", "G",
                "appraisedBy", "SALES001"
        );

        TradeInRequest req = validator.convertAndValidate(payload, TradeInRequest.class);
        assertEquals("G", req.getConditionCode());
        assertEquals(Short.valueOf((short) 2019), req.getTradeYear());
        assertEquals("SALES001", req.getAppraisedBy());
    }

    @Test
    void convertAndValidate_rejectsTwoCharConditionCode() {
        Map<String, Object> payload = Map.of(
                "tradeYear", 2019,
                "tradeMake", "HON",
                "tradeModel", "CIVIC",
                "odometer", 45000,
                "conditionCode", "GD",
                "appraisedBy", "SALES001"
        );

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> validator.convertAndValidate(payload, TradeInRequest.class));
        assertTrue(ex.getMessage().contains("TradeInRequest"));
        assertTrue(ex.getMessage().toLowerCase().contains("condition"));
    }

    @Test
    void convertAndValidate_rejectsMissingRequiredFields() {
        Map<String, Object> payload = Map.of(
                "tradeYear", 2019,
                "tradeMake", "HON"
        );

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> validator.convertAndValidate(payload, TradeInRequest.class));
        assertTrue(ex.getMessage().contains("tradeModel") || ex.getMessage().contains("conditionCode")
                || ex.getMessage().contains("odometer") || ex.getMessage().contains("appraisedBy"));
    }

    @Test
    void convertAndValidate_reportsAllViolationsInOneMessage() {
        Map<String, Object> payload = Map.of(
                "tradeYear", 2019,
                "tradeMake", "HON",
                "tradeModel", "CIVIC",
                "odometer", 45000,
                "conditionCode", "X",
                "appraisedBy", "TOOLONGUSERID"
        );

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> validator.convertAndValidate(payload, TradeInRequest.class));
        assertTrue(ex.getMessage().contains("appraisedBy"), "should report appraisedBy size violation");
        assertTrue(ex.getMessage().contains("conditionCode"), "should report conditionCode pattern violation");
    }
}
