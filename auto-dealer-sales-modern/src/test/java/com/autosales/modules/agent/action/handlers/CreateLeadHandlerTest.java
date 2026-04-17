package com.autosales.modules.agent.action.handlers;

import com.autosales.common.security.UserRole;
import com.autosales.modules.agent.action.CurrentUserContext;
import com.autosales.modules.agent.action.dryrun.DryRunRollback;
import com.autosales.modules.agent.action.dto.ImpactPreview;
import com.autosales.modules.customer.dto.LeadRequest;
import com.autosales.modules.customer.dto.LeadResponse;
import com.autosales.modules.customer.service.CustomerLeadService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CreateLeadHandlerTest {

    @Mock private CustomerLeadService leadService;
    @Spy  private ObjectMapper mapper = new ObjectMapper();
    @InjectMocks private CreateLeadHandler handler;

    private CurrentUserContext.Snapshot salesUser;

    @BeforeEach
    void setUp() {
        salesUser = new CurrentUserContext.Snapshot("SALES001", UserRole.SALESPERSON, "DLR01");
    }

    @Test
    void metadata_correct() {
        assertEquals("create_lead", handler.toolName());
        assertTrue(handler.reversible());
        assertEquals("POST /api/leads", handler.endpointDescriptor());
    }

    @Test
    void dryRun_throwsRollbackWithPreview() {
        when(leadService.create(any())).thenReturn(sampleLead());

        Map<String, Object> payload = Map.of(
            "customerId", 42,
            "leadSource", "WK",
            "interestModel", "CAMRY"
        );

        DryRunRollback rollback = assertThrows(DryRunRollback.class,
                () -> handler.dryRun(payload, salesUser));
        ImpactPreview preview = rollback.getPreview();
        assertTrue(preview.getSummary().contains("customer #42"));
        assertTrue(preview.isReversible());
    }

    @Test
    void dryRun_defaultsDealerAndSalespersonFromUser() {
        ArgumentCaptor<LeadRequest> cap = ArgumentCaptor.forClass(LeadRequest.class);
        when(leadService.create(cap.capture())).thenReturn(sampleLead());

        Map<String, Object> payload = Map.of(
            "customerId", 42,
            "leadSource", "WK"
        );
        assertThrows(DryRunRollback.class, () -> handler.dryRun(payload, salesUser));

        LeadRequest req = cap.getValue();
        assertEquals("DLR01", req.getDealerCode());
        assertEquals("SALES001", req.getAssignedSales());
    }

    @Test
    void compensation_includesLeadIdAndCloseAction() {
        LeadResponse lead = sampleLead();
        Map<String, Object> comp = handler.compensation(Map.of(), lead);
        assertNotNull(comp);
        assertEquals("close_lead", comp.get("action"));
        assertEquals(101, comp.get("leadId"));
        assertEquals("DD", comp.get("leadStatus"));
    }

    private LeadResponse sampleLead() {
        return LeadResponse.builder()
                .leadId(101)
                .customerId(42)
                .customerName("Jane Smith")
                .dealerCode("DLR01")
                .leadSource("WK")
                .interestModel("CAMRY")
                .interestYear((short) 2025)
                .leadStatus("NW")
                .assignedSales("SALES001")
                .contactCount((short) 0)
                .build();
    }
}
