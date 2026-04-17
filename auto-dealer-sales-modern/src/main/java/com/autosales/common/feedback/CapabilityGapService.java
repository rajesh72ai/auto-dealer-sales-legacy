package com.autosales.common.feedback;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Reusable service for recording and querying AI capability gaps.
 * Designed to be injected by any module (agent, chat, batch, etc.).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CapabilityGapService {

    private final CapabilityGapRepository repository;

    @Transactional
    public CapabilityGapLog record(CapabilityGapLog entry) {
        CapabilityGapLog saved = repository.save(entry);
        log.info("Capability gap logged: id={}, capability={}, category={}, priority={}",
                saved.getGapId(), saved.getRequestedCapability(),
                saved.getCategory(), saved.getPriorityHint());
        return saved;
    }

    public Page<CapabilityGapLog> listAll(int page, int size) {
        return repository.findAllByOrderByCreatedTsDesc(PageRequest.of(page, size));
    }

    public Page<CapabilityGapLog> listByStatus(String status, int page, int size) {
        return repository.findByStatusOrderByCreatedTsDesc(status, PageRequest.of(page, size));
    }

    public List<CapabilityGapSummary> getSummary() {
        return repository.findGapSummary();
    }

    public Map<String, Object> getDashboard() {
        Map<String, Object> dash = new LinkedHashMap<>();
        dash.put("totalNew", repository.countByStatus("NEW"));
        dash.put("totalReviewed", repository.countByStatus("REVIEWED"));
        dash.put("totalPlanned", repository.countByStatus("PLANNED"));
        dash.put("totalImplemented", repository.countByStatus("IMPLEMENTED"));
        dash.put("topRequested", repository.findGapSummary());
        dash.put("recentGaps", repository.findAllByOrderByCreatedTsDesc(PageRequest.of(0, 10)).getContent());
        return dash;
    }

    @Transactional
    public CapabilityGapLog updateStatus(Long gapId, String status, String resolutionNotes) {
        CapabilityGapLog gap = repository.findById(gapId)
                .orElseThrow(() -> new IllegalArgumentException("Gap not found: " + gapId));
        gap.setStatus(status);
        gap.setResolutionNotes(resolutionNotes);
        if ("IMPLEMENTED".equals(status) || "WONT_DO".equals(status)) {
            gap.setResolvedTs(LocalDateTime.now());
        }
        return repository.save(gap);
    }
}
