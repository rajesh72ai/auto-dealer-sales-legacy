package com.autosales.common.controller;

import com.autosales.common.util.CsvExportService;
import com.autosales.modules.customer.entity.Customer;
import com.autosales.modules.customer.repository.CustomerRepository;
import com.autosales.modules.sales.entity.SalesDeal;
import com.autosales.modules.sales.repository.SalesDealRepository;
import com.autosales.modules.vehicle.entity.StockAdjustment;
import com.autosales.modules.vehicle.entity.StockPosition;
import com.autosales.modules.vehicle.entity.Vehicle;
import com.autosales.modules.vehicle.repository.StockAdjustmentRepository;
import com.autosales.modules.vehicle.repository.StockPositionRepository;
import com.autosales.modules.vehicle.repository.VehicleRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * REST controller for CSV data exports.
 * Port of mainframe batch extract programs — enables dealer data download for reporting.
 */
@RestController
@RequestMapping("/api/export")
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','OPERATOR')")
@Slf4j
public class ExportController {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter DATETIME_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    private final VehicleRepository vehicleRepository;
    private final StockPositionRepository stockPositionRepository;
    private final CustomerRepository customerRepository;
    private final SalesDealRepository salesDealRepository;
    private final StockAdjustmentRepository stockAdjustmentRepository;
    private final CsvExportService csvExportService;

    public ExportController(VehicleRepository vehicleRepository,
                            StockPositionRepository stockPositionRepository,
                            CustomerRepository customerRepository,
                            SalesDealRepository salesDealRepository,
                            StockAdjustmentRepository stockAdjustmentRepository,
                            CsvExportService csvExportService) {
        this.vehicleRepository = vehicleRepository;
        this.stockPositionRepository = stockPositionRepository;
        this.customerRepository = customerRepository;
        this.salesDealRepository = salesDealRepository;
        this.stockAdjustmentRepository = stockAdjustmentRepository;
        this.csvExportService = csvExportService;
    }

    @GetMapping("/vehicles")
    public ResponseEntity<byte[]> exportVehicles(@RequestParam String dealerCode) {
        log.info("Exporting vehicles for dealer {}", dealerCode);
        List<Vehicle> vehicles = vehicleRepository.findByDealerCode(dealerCode, PageRequest.of(0, 10000)).getContent();

        String csv = csvExportService.exportToCsv(vehicles,
                new String[]{"VIN", "Stock#", "Year", "Make", "Model", "Status", "Color", "Days In Stock", "Dealer"},
                item -> {
                    Vehicle v = (Vehicle) item;
                    return new String[]{
                            v.getVin(),
                            v.getStockNumber(),
                            String.valueOf(v.getModelYear()),
                            v.getMakeCode(),
                            v.getModelCode(),
                            v.getVehicleStatus(),
                            v.getExteriorColor(),
                            String.valueOf(v.getDaysInStock()),
                            v.getDealerCode()
                    };
                });

        return csvExportService.buildCsvResponse(csv, "vehicles-" + dealerCode + ".csv");
    }

    @GetMapping("/stock-positions")
    public ResponseEntity<byte[]> exportStockPositions(@RequestParam String dealerCode) {
        log.info("Exporting stock positions for dealer {}", dealerCode);
        List<StockPosition> positions = stockPositionRepository.findByDealerCode(dealerCode);

        String csv = csvExportService.exportToCsv(positions,
                new String[]{"Dealer", "Year", "Make", "Model", "On Hand", "In Transit", "Allocated", "On Hold", "Sold MTD", "Sold YTD", "Reorder Point"},
                item -> {
                    StockPosition sp = (StockPosition) item;
                    return new String[]{
                            sp.getDealerCode(),
                            String.valueOf(sp.getModelYear()),
                            sp.getMakeCode(),
                            sp.getModelCode(),
                            String.valueOf(sp.getOnHandCount()),
                            String.valueOf(sp.getInTransitCount()),
                            String.valueOf(sp.getAllocatedCount()),
                            String.valueOf(sp.getOnHoldCount()),
                            String.valueOf(sp.getSoldMtd()),
                            String.valueOf(sp.getSoldYtd()),
                            String.valueOf(sp.getReorderPoint())
                    };
                });

        return csvExportService.buildCsvResponse(csv, "stock-positions-" + dealerCode + ".csv");
    }

    @GetMapping("/customers")
    public ResponseEntity<byte[]> exportCustomers(@RequestParam String dealerCode) {
        log.info("Exporting customers for dealer {}", dealerCode);
        List<Customer> customers = customerRepository.findByDealerCode(dealerCode);

        String csv = csvExportService.exportToCsv(customers,
                new String[]{"Customer ID", "First Name", "Last Name", "DOB", "Cell Phone", "Email", "City", "State", "Dealer"},
                item -> {
                    Customer c = (Customer) item;
                    return new String[]{
                            String.valueOf(c.getCustomerId()),
                            c.getFirstName(),
                            c.getLastName(),
                            c.getDateOfBirth() != null ? c.getDateOfBirth().format(DATE_FMT) : "",
                            c.getCellPhone() != null ? c.getCellPhone() : "",
                            c.getEmail() != null ? c.getEmail() : "",
                            c.getCity() != null ? c.getCity() : "",
                            c.getStateCode() != null ? c.getStateCode() : "",
                            c.getDealerCode()
                    };
                });

        return csvExportService.buildCsvResponse(csv, "customers-" + dealerCode + ".csv");
    }

    @GetMapping("/deals")
    public ResponseEntity<byte[]> exportDeals(@RequestParam String dealerCode) {
        log.info("Exporting deals for dealer {}", dealerCode);
        List<SalesDeal> deals = salesDealRepository.findByDealerCode(dealerCode, PageRequest.of(0, 10000)).getContent();

        String csv = csvExportService.exportToCsv(deals,
                new String[]{"Deal#", "Dealer", "Customer ID", "VIN", "Salesperson", "Type", "Status", "Vehicle Price", "Deal Date"},
                item -> {
                    SalesDeal d = (SalesDeal) item;
                    return new String[]{
                            d.getDealNumber(),
                            d.getDealerCode(),
                            String.valueOf(d.getCustomerId()),
                            d.getVin(),
                            d.getSalespersonId(),
                            d.getDealType(),
                            d.getDealStatus(),
                            d.getVehiclePrice() != null ? d.getVehiclePrice().toPlainString() : "",
                            d.getDealDate() != null ? d.getDealDate().format(DATE_FMT) : ""
                    };
                });

        return csvExportService.buildCsvResponse(csv, "deals-" + dealerCode + ".csv");
    }

    @GetMapping("/adjustments")
    public ResponseEntity<byte[]> exportAdjustments(@RequestParam String dealerCode) {
        log.info("Exporting stock adjustments for dealer {}", dealerCode);
        List<StockAdjustment> adjustments = stockAdjustmentRepository.findByDealerCode(dealerCode, PageRequest.of(0, 10000)).getContent();

        String csv = csvExportService.exportToCsv(adjustments,
                new String[]{"Adjust ID", "Dealer", "VIN", "Type", "Reason", "Old Status", "New Status", "Adjusted By", "Timestamp"},
                item -> {
                    StockAdjustment a = (StockAdjustment) item;
                    return new String[]{
                            String.valueOf(a.getAdjustId()),
                            a.getDealerCode(),
                            a.getVin(),
                            a.getAdjustType(),
                            a.getAdjustReason(),
                            a.getOldStatus(),
                            a.getNewStatus(),
                            a.getAdjustedBy(),
                            a.getAdjustedTs() != null ? a.getAdjustedTs().format(DATETIME_FMT) : ""
                    };
                });

        return csvExportService.buildCsvResponse(csv, "adjustments-" + dealerCode + ".csv");
    }
}
