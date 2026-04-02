package com.autosales.modules.batch.repository;

import com.autosales.modules.batch.entity.BatchControl;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BatchControlRepository extends JpaRepository<BatchControl, String> {

    List<BatchControl> findByRunStatus(String runStatus);

    List<BatchControl> findAllByOrderByUpdatedTsDesc();
}
