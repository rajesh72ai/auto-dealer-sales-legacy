package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.BatchJobResponse;
import com.autosales.modules.batch.dto.CheckpointActionRequest;
import com.autosales.modules.batch.dto.CheckpointResponse;
import com.autosales.modules.batch.entity.BatchCheckpoint;
import com.autosales.modules.batch.entity.BatchControl;
import com.autosales.modules.batch.repository.BatchCheckpointRepository;
import com.autosales.modules.batch.repository.BatchControlRepository;
import com.autosales.common.exception.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

/**
 * Batch checkpoint and control management service.
 * Port of BATRSTRT.cbl — operations utility for batch abend recovery.
 * Supports three actions: DISP (display), RESET (clear for re-run), COMPL (mark complete).
 *
 * Also provides batch job status listing from BATCH_CONTROL table.
 */
@Service
@Transactional(readOnly = true)
@Slf4j
@RequiredArgsConstructor
public class CheckpointService {

    private final BatchCheckpointRepository batchCheckpointRepository;
    private final BatchControlRepository batchControlRepository;

    // Program name → description map
    private static final Map<String, String> PROGRAM_NAMES = Map.ofEntries(
            Map.entry("BATDLY00", "Daily End-of-Day Processing"),
            Map.entry("BATMTH00", "Monthly Close Processing"),
            Map.entry("BATPUR00", "Purge/Archive Processing"),
            Map.entry("BATVAL00", "Data Validation/Integrity"),
            Map.entry("BATWKL00", "Weekly Batch Processing"),
            Map.entry("BATCRM00", "CRM Feed Extract"),
            Map.entry("BATDLAKE", "Data Lake Extract"),
            Map.entry("BATDMS00", "DMS Interface Extract"),
            Map.entry("BATGLINT", "General Ledger Interface"),
            Map.entry("BATINB00", "Inbound Data Feed Processing"),
            Map.entry("BATRSTRT", "Batch Restart Utility")
    );

    private static final Map<String, String> STATUS_DESCRIPTIONS = Map.of(
            "OK", "Completed Successfully",
            "ER", "Completed with Errors",
            "RN", "Currently Running",
            "AB", "Abended",
            "NR", "Never Run"
    );

    // ── Batch Job Listing ─────────────────────────────────────────────

    public List<BatchJobResponse> getAllBatchJobs() {
        return batchControlRepository.findAllByOrderByUpdatedTsDesc()
                .stream()
                .map(this::toBatchJobResponse)
                .toList();
    }

    public BatchJobResponse getBatchJob(String programId) {
        return batchControlRepository.findById(programId)
                .map(this::toBatchJobResponse)
                .orElseThrow(() -> new EntityNotFoundException("BatchControl", programId));
    }

    // ── Checkpoint Operations (port of BATRSTRT) ──────────────────────

    public List<CheckpointResponse> getCheckpoints(String programId) {
        return batchCheckpointRepository.findByProgramIdOrderByCheckpointSeqDesc(programId)
                .stream()
                .map(this::toCheckpointResponse)
                .toList();
    }

    /**
     * Execute checkpoint action per BATRSTRT control card format:
     * DISP  — Display current checkpoint status
     * RESET — Delete all checkpoints for re-run from beginning
     * COMPL — Mark checkpoint status as 'CP' (Complete)
     */
    @Transactional
    public CheckpointResponse executeCheckpointAction(CheckpointActionRequest request) {
        String programId = request.getProgramId();
        String action = request.getAction();

        log.info("BATRSTRT: {} action for program {}", action, programId);

        return switch (action) {
            case "DISP" -> displayCheckpoint(programId);
            case "RESET" -> resetCheckpoint(programId);
            case "COMPL" -> completeCheckpoint(programId);
            default -> throw new IllegalArgumentException("Invalid action: " + action);
        };
    }

    /**
     * DISP: Read latest checkpoint and display status.
     * Ported from BATRSTRT PROCESS-DISPLAY paragraph.
     */
    CheckpointResponse displayCheckpoint(String programId) {
        return batchCheckpointRepository
                .findFirstByProgramIdOrderByCheckpointSeqDesc(programId)
                .map(this::toCheckpointResponse)
                .orElse(CheckpointResponse.builder()
                        .programId(programId)
                        .checkpointStatus("NONE")
                        .build());
    }

    /**
     * RESET: Delete all checkpoint rows for the program.
     * Ported from BATRSTRT PROCESS-RESET paragraph.
     * Allows clean re-run from beginning.
     */
    @Transactional
    CheckpointResponse resetCheckpoint(String programId) {
        CheckpointResponse current = displayCheckpoint(programId);
        batchCheckpointRepository.deleteByProgramId(programId);
        log.info("BATRSTRT: All checkpoints deleted for {}", programId);
        return CheckpointResponse.builder()
                .programId(programId)
                .checkpointStatus("RESET")
                .recordsIn(current.getRecordsIn())
                .recordsOut(current.getRecordsOut())
                .recordsError(current.getRecordsError())
                .build();
    }

    /**
     * COMPL: Update latest checkpoint status to 'CP' (Complete).
     * Ported from BATRSTRT PROCESS-COMPLETE paragraph.
     * Causes restart logic to skip restart on next run.
     */
    @Transactional
    CheckpointResponse completeCheckpoint(String programId) {
        BatchCheckpoint checkpoint = batchCheckpointRepository
                .findFirstByProgramIdOrderByCheckpointSeqDesc(programId)
                .orElseThrow(() -> new EntityNotFoundException("BatchCheckpoint", programId));

        checkpoint.setCheckpointStatus("CP");
        batchCheckpointRepository.save(checkpoint);
        log.info("BATRSTRT: Checkpoint marked complete for {}", programId);
        return toCheckpointResponse(checkpoint);
    }

    private BatchJobResponse toBatchJobResponse(BatchControl control) {
        return BatchJobResponse.builder()
                .programId(control.getProgramId())
                .programName(PROGRAM_NAMES.getOrDefault(control.getProgramId(), control.getProgramId()))
                .lastRunDate(control.getLastRunDate())
                .lastSyncDate(control.getLastSyncDate())
                .recordsProcessed(control.getRecordsProcessed())
                .runStatus(control.getRunStatus())
                .statusDescription(STATUS_DESCRIPTIONS.getOrDefault(control.getRunStatus(), "Unknown"))
                .createdTs(control.getCreatedTs())
                .updatedTs(control.getUpdatedTs())
                .build();
    }

    private CheckpointResponse toCheckpointResponse(BatchCheckpoint cp) {
        return CheckpointResponse.builder()
                .programId(cp.getProgramId())
                .checkpointSeq(cp.getCheckpointSeq())
                .checkpointTimestamp(cp.getCheckpointTimestamp())
                .lastKeyValue(cp.getLastKeyValue())
                .recordsIn(cp.getRecordsIn())
                .recordsOut(cp.getRecordsOut())
                .recordsError(cp.getRecordsError())
                .checkpointStatus(cp.getCheckpointStatus())
                .build();
    }
}
