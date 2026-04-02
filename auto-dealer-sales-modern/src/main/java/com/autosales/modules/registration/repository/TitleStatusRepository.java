package com.autosales.modules.registration.repository;

import com.autosales.modules.registration.entity.TitleStatus;
import com.autosales.modules.registration.entity.TitleStatusId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TitleStatusRepository extends JpaRepository<TitleStatus, TitleStatusId> {

    List<TitleStatus> findByRegIdOrderByStatusSeqDesc(String regId);

    @Query("SELECT COALESCE(MAX(t.statusSeq), 0) FROM TitleStatus t WHERE t.regId = :regId")
    Short findMaxStatusSeqByRegId(String regId);
}
