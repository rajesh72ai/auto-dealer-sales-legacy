package com.autosales.modules.batch.repository;

import com.autosales.modules.batch.entity.BatchCheckpoint;
import com.autosales.modules.batch.entity.BatchCheckpointId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BatchCheckpointRepository extends JpaRepository<BatchCheckpoint, BatchCheckpointId> {

    List<BatchCheckpoint> findByProgramIdOrderByCheckpointSeqDesc(String programId);

    Optional<BatchCheckpoint> findFirstByProgramIdOrderByCheckpointSeqDesc(String programId);

    void deleteByProgramId(String programId);

    List<BatchCheckpoint> findByCheckpointStatus(String checkpointStatus);
}
