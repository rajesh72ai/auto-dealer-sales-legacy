package com.autosales.common.feedback;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CapabilityGapServiceTest {

    @Mock
    private CapabilityGapRepository repository;

    @InjectMocks
    private CapabilityGapService service;

    private CapabilityGapLog sampleGap;

    @BeforeEach
    void setUp() {
        sampleGap = CapabilityGapLog.builder()
                .gapId(1L)
                .appId("AUTOSALES")
                .appName("Auto Dealer Sales")
                .sourceSystem("AGENT")
                .userId("ADMIN001")
                .dealerCode("DLR01")
                .requestedCapability("create_customer")
                .category("CRUD")
                .userInput("Add a new customer named John Smith to DLR01")
                .scenarioDescription("User wanted to register a new customer before creating a deal")
                .agentReasoning("create_customer is not in the write-tool allow-list")
                .suggestedAlternative("Use Customers → New in the sidebar")
                .priorityHint("HIGH")
                .status("NEW")
                .createdTs(LocalDateTime.now())
                .build();
    }

    @Test
    void record_savesAndReturns() {
        when(repository.save(any())).thenReturn(sampleGap);

        CapabilityGapLog result = service.record(sampleGap);

        assertThat(result.getGapId()).isEqualTo(1L);
        assertThat(result.getRequestedCapability()).isEqualTo("create_customer");
        verify(repository).save(sampleGap);
    }

    @Test
    void record_preservesAppIdAndAppName() {
        when(repository.save(any())).thenReturn(sampleGap);

        service.record(sampleGap);

        ArgumentCaptor<CapabilityGapLog> captor = ArgumentCaptor.forClass(CapabilityGapLog.class);
        verify(repository).save(captor.capture());
        assertThat(captor.getValue().getAppId()).isEqualTo("AUTOSALES");
        assertThat(captor.getValue().getAppName()).isEqualTo("Auto Dealer Sales");
    }

    @Test
    void listAll_returnsPaginated() {
        var page = new PageImpl<>(List.of(sampleGap));
        when(repository.findAllByOrderByCreatedTsDesc(any())).thenReturn(page);

        var result = service.listAll(0, 20);

        assertThat(result.getContent()).hasSize(1);
        assertThat(result.getContent().get(0).getRequestedCapability()).isEqualTo("create_customer");
    }

    @Test
    void listByStatus_filtersCorrectly() {
        var page = new PageImpl<>(List.of(sampleGap));
        when(repository.findByStatusOrderByCreatedTsDesc(eq("NEW"), any())).thenReturn(page);

        var result = service.listByStatus("NEW", 0, 20);

        assertThat(result.getContent()).hasSize(1);
        verify(repository).findByStatusOrderByCreatedTsDesc("NEW", PageRequest.of(0, 20));
    }

    @Test
    void getDashboard_returnsAllCounts() {
        when(repository.countByStatus("NEW")).thenReturn(5L);
        when(repository.countByStatus("REVIEWED")).thenReturn(2L);
        when(repository.countByStatus("PLANNED")).thenReturn(1L);
        when(repository.countByStatus("IMPLEMENTED")).thenReturn(3L);
        when(repository.findGapSummary()).thenReturn(List.of());
        when(repository.findAllByOrderByCreatedTsDesc(any())).thenReturn(new PageImpl<>(List.of()));

        Map<String, Object> dash = service.getDashboard();

        assertThat(dash.get("totalNew")).isEqualTo(5L);
        assertThat(dash.get("totalReviewed")).isEqualTo(2L);
        assertThat(dash.get("totalPlanned")).isEqualTo(1L);
        assertThat(dash.get("totalImplemented")).isEqualTo(3L);
    }

    @Test
    void updateStatus_setsResolvedTsForImplemented() {
        when(repository.findById(1L)).thenReturn(Optional.of(sampleGap));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CapabilityGapLog result = service.updateStatus(1L, "IMPLEMENTED", "Built in Wave 8");

        assertThat(result.getStatus()).isEqualTo("IMPLEMENTED");
        assertThat(result.getResolutionNotes()).isEqualTo("Built in Wave 8");
        assertThat(result.getResolvedTs()).isNotNull();
    }

    @Test
    void updateStatus_noResolvedTsForReviewed() {
        when(repository.findById(1L)).thenReturn(Optional.of(sampleGap));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CapabilityGapLog result = service.updateStatus(1L, "REVIEWED", null);

        assertThat(result.getStatus()).isEqualTo("REVIEWED");
        assertThat(result.getResolvedTs()).isNull();
    }

    @Test
    void updateStatus_throwsForMissingId() {
        when(repository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.updateStatus(999L, "REVIEWED", null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Gap not found: 999");
    }

    @Test
    void record_richContextFields() {
        when(repository.save(any())).thenReturn(sampleGap);

        service.record(sampleGap);

        ArgumentCaptor<CapabilityGapLog> captor = ArgumentCaptor.forClass(CapabilityGapLog.class);
        verify(repository).save(captor.capture());
        CapabilityGapLog saved = captor.getValue();
        assertThat(saved.getUserInput()).contains("Add a new customer");
        assertThat(saved.getScenarioDescription()).contains("register a new customer");
        assertThat(saved.getAgentReasoning()).contains("allow-list");
        assertThat(saved.getSuggestedAlternative()).contains("sidebar");
        assertThat(saved.getPriorityHint()).isEqualTo("HIGH");
    }
}
