package com.autosales.modules.batch.repository;

import com.autosales.modules.batch.entity.RestartControl;
import com.autosales.modules.batch.entity.RestartControlId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RestartControlRepository extends JpaRepository<RestartControl, RestartControlId> {

    List<RestartControl> findByJobName(String jobName);

    List<RestartControl> findByStatus(String status);

    List<RestartControl> findByJobNameAndStatus(String jobName, String status);
}
