package com.autosales.modules.batch.service;

import com.autosales.modules.batch.dto.BatchJobResponse;
import com.autosales.modules.batch.dto.CheckpointActionRequest;
import com.autosales.modules.batch.dto.CheckpointResponse;
import com.autosales.modules.batch.entity.BatchCheckpoint;
import com.autosales.modules.batch.entity.BatchControl;
import com.autosales.modules.batch.repository.BatchCheckpointRepository;
import com.autosales.modules.batch.repository.BatchControlRepository;
import com.autosales.common.exception.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for CheckpointService — port of BATRSTRT.cbl.
 * Validates the three control card actions:
 *   DISP  — Display current checkpoint (read latest by program_id)
 *   RESET — Delete all checkpoints for clean re-run
 *   COMPL — Mark checkpoint status as CP (Complete) to skip restart
 */
@ExtendWith(MockitoExtension.class)
class CheckpointServiceTest {

    @Mock private BatchCheckpointRepository batchCheckpointRepository;
    @Mock private BatchControlRepository batchControlRepository;

    @InjectMocks
    private CheckpointService checkpointService;

    private BatchCheckpoint testCheckpoint;
    private BatchControl testControl;

    @BeforeEach
    void setUp() {
        testCheckpoint = BatchCheckpoint.builder()
                .programId("BATDLY00")
                .checkpointSeq(3)
                .checkpointTimestamp(LocalDateTime.of(2026, 3, 29, 23, 30))
                .lastKeyValue("VIN-12345")
                .recordsIn(1500)
                .recordsOut(1480)
                .recordsError(20)
                .checkpointStatus("IP")
                .build();

        testControl = BatchControl.builder()
                .programId("BATDLY00")
                .lastRunDate(LocalDate.of(2026, 3, 29))
                .recordsProcessed(1500)
                .runStatus("OK")
                .createdTs(LocalDateTime.now())
                .updatedTs(LocalDateTime.now())
                .build();
    }

    // ── DISP Action ───────────────────────────────────────────────────

    @Test
    @DisplayName("BATRSTRT DISP: Returns latest checkpoint for program")
    void displayCheckpoint_returnsLatest() {
        when(batchCheckpointRepository.findFirstByProgramIdOrderByCheckpointSeqDesc("BATDLY00"))
                .thenReturn(Optional.of(testCheckpoint));

        CheckpointResponse result = checkpointService.displayCheckpoint("BATDLY00");

        assertEquals("BATDLY00", result.getProgramId());
        assertEquals(3, result.getCheckpointSeq());
        assertEquals("VIN-12345", result.getLastKeyValue());
        assertEquals(1500, result.getRecordsIn());
        assertEquals(1480, result.getRecordsOut());
        assertEquals(20, result.getRecordsError());
        assertEquals("IP", result.getCheckpointStatus());
    }

    @Test
    @DisplayName("BATRSTRT DISP: Returns NONE status when no checkpoint exists")
    void displayCheckpoint_noCheckpoint_returnsNone() {
        when(batchCheckpointRepository.findFirstByProgramIdOrderByCheckpointSeqDesc("BATDLY00"))
                .thenReturn(Optional.empty());

        CheckpointResponse result = checkpointService.displayCheckpoint("BATDLY00");

        assertEquals("BATDLY00", result.getProgramId());
        assertEquals("NONE", result.getCheckpointStatus());
    }

    // ── RESET Action ──────────────────────────────────────────────────

    @Test
    @DisplayName("BATRSTRT RESET: Deletes all checkpoints for program")
    void resetCheckpoint_deletesAll() {
        when(batchCheckpointRepository.findFirstByProgramIdOrderByCheckpointSeqDesc("BATDLY00"))
                .thenReturn(Optional.of(testCheckpoint));

        CheckpointResponse result = checkpointService.resetCheckpoint("BATDLY00");

        verify(batchCheckpointRepository).deleteByProgramId("BATDLY00");
        assertEquals("RESET", result.getCheckpointStatus(),
                "BATRSTRT: After RESET, status should indicate RESET");
    }

    // ── COMPL Action ──────────────────────────────────────────────────

    @Test
    @DisplayName("BATRSTRT COMPL: Updates checkpoint status to CP")
    void completeCheckpoint_setsStatusCp() {
        when(batchCheckpointRepository.findFirstByProgramIdOrderByCheckpointSeqDesc("BATDLY00"))
                .thenReturn(Optional.of(testCheckpoint));
        when(batchCheckpointRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        CheckpointResponse result = checkpointService.completeCheckpoint("BATDLY00");

        assertEquals("CP", result.getCheckpointStatus(),
                "BATRSTRT: COMPL action must set status to CP (Complete)");
        verify(batchCheckpointRepository).save(argThat(cp -> "CP".equals(cp.getCheckpointStatus())));
    }

    @Test
    @DisplayName("BATRSTRT COMPL: Throws exception when no checkpoint to complete")
    void completeCheckpoint_noCheckpoint_throwsException() {
        when(batchCheckpointRepository.findFirstByProgramIdOrderByCheckpointSeqDesc("BATDLY00"))
                .thenReturn(Optional.empty());

        assertThrows(EntityNotFoundException.class,
                () -> checkpointService.completeCheckpoint("BATDLY00"));
    }

    // ── Action Dispatch ───────────────────────────────────────────────

    @Test
    @DisplayName("BATRSTRT: Action dispatch routes DISP/RESET/COMPL correctly")
    void executeCheckpointAction_dispatchesCorrectly() {
        when(batchCheckpointRepository.findFirstByProgramIdOrderByCheckpointSeqDesc("BATDLY00"))
                .thenReturn(Optional.of(testCheckpoint));
        when(batchCheckpointRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        // DISP
        CheckpointActionRequest dispReq = CheckpointActionRequest.builder()
                .programId("BATDLY00").action("DISP").build();
        CheckpointResponse dispResult = checkpointService.executeCheckpointAction(dispReq);
        assertEquals("IP", dispResult.getCheckpointStatus());

        // COMPL
        CheckpointActionRequest complReq = CheckpointActionRequest.builder()
                .programId("BATDLY00").action("COMPL").build();
        CheckpointResponse complResult = checkpointService.executeCheckpointAction(complReq);
        assertEquals("CP", complResult.getCheckpointStatus());
    }

    // ── Batch Job Listing ─────────────────────────────────────────────

    @Test
    @DisplayName("BATRSTRT: Batch job listing maps program names and status descriptions")
    void getAllBatchJobs_mapsCorrectly() {
        when(batchControlRepository.findAllByOrderByUpdatedTsDesc()).thenReturn(List.of(testControl));

        List<BatchJobResponse> jobs = checkpointService.getAllBatchJobs();

        assertEquals(1, jobs.size());
        assertEquals("BATDLY00", jobs.get(0).getProgramId());
        assertEquals("Daily End-of-Day Processing", jobs.get(0).getProgramName());
        assertEquals("Completed Successfully", jobs.get(0).getStatusDescription());
    }

    @Test
    @DisplayName("BATRSTRT: getBatchJob throws EntityNotFoundException for unknown program")
    void getBatchJob_unknownProgram_throwsException() {
        when(batchControlRepository.findById("UNKNOWN")).thenReturn(Optional.empty());

        assertThrows(EntityNotFoundException.class,
                () -> checkpointService.getBatchJob("UNKNOWN"));
    }
}
