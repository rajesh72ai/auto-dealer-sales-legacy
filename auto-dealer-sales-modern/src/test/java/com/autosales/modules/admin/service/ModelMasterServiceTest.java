package com.autosales.modules.admin.service;

import com.autosales.common.exception.DuplicateEntityException;
import com.autosales.common.exception.EntityNotFoundException;
import com.autosales.common.util.ResponseFormatter;
import com.autosales.modules.admin.dto.ModelMasterRequest;
import com.autosales.modules.admin.dto.ModelMasterResponse;
import com.autosales.modules.admin.entity.ModelMaster;
import com.autosales.modules.admin.entity.ModelMasterId;
import com.autosales.modules.admin.repository.ModelMasterRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ModelMasterServiceTest {

    @Mock
    private ModelMasterRepository repository;

    @Mock
    private ResponseFormatter responseFormatter;

    @InjectMocks
    private ModelMasterService modelMasterService;

    private ModelMaster buildModelMaster() {
        return ModelMaster.builder()
                .modelYear((short) 2025)
                .makeCode("TOY")
                .modelCode("CAMRY")
                .modelName("Camry LE")
                .bodyStyle("SD")
                .trimLevel("LE")
                .engineType("GAS")
                .transmission("A")
                .driveTrain("FWD")
                .exteriorColors("White,Black,Silver")
                .interiorColors("Black,Gray")
                .curbWeight(3300)
                .fuelEconomyCity((short) 28)
                .fuelEconomyHwy((short) 39)
                .activeFlag("Y")
                .createdTs(LocalDateTime.of(2024, 6, 1, 10, 0))
                .build();
    }

    private ModelMasterRequest buildRequest() {
        return ModelMasterRequest.builder()
                .modelYear((short) 2025)
                .makeCode("TOY")
                .modelCode("CAMRY")
                .modelName("Camry LE")
                .bodyStyle("SD")
                .trimLevel("LE")
                .engineType("GAS")
                .transmission("A")
                .driveTrain("FWD")
                .exteriorColors("White,Black,Silver")
                .interiorColors("Black,Gray")
                .curbWeight(3300)
                .fuelEconomyCity((short) 28)
                .fuelEconomyHwy((short) 39)
                .activeFlag("Y")
                .build();
    }

    @Test
    void testFindByKey_success() {
        ModelMaster entity = buildModelMaster();
        ModelMasterId id = new ModelMasterId((short) 2025, "TOY", "CAMRY");
        when(repository.findById(id)).thenReturn(Optional.of(entity));

        ModelMasterResponse response = modelMasterService.findByKey((short) 2025, "TOY", "CAMRY");

        assertNotNull(response);
        assertEquals((short) 2025, response.getModelYear());
        assertEquals("TOY", response.getMakeCode());
        assertEquals("CAMRY", response.getModelCode());
        assertEquals("Camry LE", response.getModelName());
        assertEquals("SD", response.getBodyStyle());
        assertEquals("FWD", response.getDriveTrain());
        verify(repository).findById(id);
    }

    @Test
    void testFindByKey_notFound() {
        ModelMasterId id = new ModelMasterId((short) 2025, "XXX", "NONE");
        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThrows(EntityNotFoundException.class,
                () -> modelMasterService.findByKey((short) 2025, "XXX", "NONE"));
        verify(repository).findById(id);
    }

    @Test
    void testCreate_success() {
        ModelMasterRequest request = buildRequest();
        ModelMasterId id = new ModelMasterId((short) 2025, "TOY", "CAMRY");
        when(repository.existsById(id)).thenReturn(false);
        when(repository.save(any(ModelMaster.class))).thenAnswer(inv -> inv.getArgument(0));

        ModelMasterResponse response = modelMasterService.create(request);

        assertNotNull(response);
        assertEquals("CAMRY", response.getModelCode());

        ArgumentCaptor<ModelMaster> captor = ArgumentCaptor.forClass(ModelMaster.class);
        verify(repository).save(captor.capture());
        ModelMaster saved = captor.getValue();
        assertNotNull(saved.getCreatedTs());
    }

    @Test
    void testCreate_duplicate() {
        ModelMasterRequest request = buildRequest();
        ModelMasterId id = new ModelMasterId((short) 2025, "TOY", "CAMRY");
        when(repository.existsById(id)).thenReturn(true);

        assertThrows(DuplicateEntityException.class,
                () -> modelMasterService.create(request));
        verify(repository, never()).save(any());
    }
}
