# AUTOSALES Modernization Prioritization Map

> Scoring framework for module-by-module modernization sequencing.
> Date: 2026-03-29

---

## Scoring Methodology

Each module is scored across 5 dimensions on a 1-5 scale:

| Score | Meaning |
|-------|---------|
| 1 | Low / Minimal |
| 2 | Below Average |
| 3 | Moderate |
| 4 | Above Average / Significant |
| 5 | High / Critical |

**Composite Score** = Business Criticality + Technical Complexity + Integration Density + Risk Level + Modernization Readiness (inverted: 6 - score, so higher readiness = lower barrier)

Lower composite scores indicate better candidates for early waves.

---

## Module Scoring Table

### ADM - Administration & Reference Data

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Business Criticality | 2 | Back-office function; not customer-facing. Dealer setup, user management, reference data maintenance. |
| Technical Complexity | 3 | 8 programs, 6,972 SLOC. Standard CRUD operations on reference tables. Multi-table master data (MODEL_MASTER, PRICE_MASTER, TAX_RATE, DEALER, SYSTEM_USER, SYSTEM_CONFIG). |
| Integration Density | 4 | Foundation module. All other modules depend on ADM reference data (pricing, tax rates, model master, dealer config). Changes here propagate everywhere. |
| Risk Level | 2 | No financial calculations. Data integrity matters but operations are straightforward. |
| Modernization Readiness | 5 | Pure CRUD on reference tables. Well-isolated. Maps directly to Spring Data JPA repositories. Standard REST API patterns. |
| **Composite** | **8** | **6 - 5 (readiness) + 2 + 3 + 4 + 2 = 12** |

### CUS - Customer Management

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Business Criticality | 4 | Customer-facing. Drives CRM, lead management, credit checks. Revenue pipeline starts here. |
| Technical Complexity | 3 | 7 programs, 5,326 SLOC. Customer CRUD, lead tracking, credit bureau integration (simulated), purchase history. |
| Integration Density | 2 | Relatively self-contained. Used by SAL and FIN for customer lookup, but few outbound dependencies. |
| Risk Level | 3 | PII data handling. Credit check integration. Data migration must preserve customer relationships. |
| Modernization Readiness | 4 | Clean domain model. Maps well to Customer aggregate in DDD. Standard search/list patterns. |
| **Composite** | **14** | **6 - 4 + 4 + 3 + 2 + 3 = 14** |

### VEH - Vehicle Management

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Business Criticality | 5 | Core inventory asset. Every sale, finance, and floor plan transaction references a vehicle. |
| Technical Complexity | 4 | 8 programs, 5,653 SLOC. VIN decode, vehicle receive, transfer, location tracking, aging analysis, status history. Multi-step workflows. |
| Integration Density | 5 | Most connected module. Shared VEHICLE table accessed by SAL, CUS, FPL, STK, PLI, WRC, REG, BAT, RPT. Calls 7 common modules. |
| Risk Level | 4 | VIN validation critical. Stock position accuracy affects financial reporting. Status transitions must be correct. |
| Modernization Readiness | 3 | Complex entity with rich behavior. VIN decode logic needs careful porting. Stock update calls are distributed across modules. |
| **Composite** | **21** | **6 - 3 + 5 + 4 + 5 + 4 = 21** |

### SAL - Sales / Deal Management

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Business Criticality | 5 | Core revenue transaction. Quotes, negotiations, trade-ins, approvals, deal completion. Direct revenue impact. |
| Technical Complexity | 5 | 8 programs, 6,295 SLOC. Deal state machine (Quote->Negotiate->Approve->Complete/Cancel). Pricing with holdback, incentives. Trade-in valuation. Multi-step deal workflow. SALQOT00 alone is 1,173 lines. |
| Integration Density | 5 | Depends on CUS, VEH, FIN, ADM, STK. Calls 7 common modules. Touches 14+ DB2 tables. Most complex cross-module program (SALQOT00). |
| Risk Level | 5 | Financial calculations (pricing, tax, trade-in). Deal state machine integrity. Incentive application rules. Regulatory compliance (Truth-in-Lending adjacency). |
| Modernization Readiness | 2 | Complex state machine. Tightly coupled to pricing, tax, stock, and finance modules. Requires all dependencies to be modernized first or stubbed. |
| **Composite** | **24** | **6 - 2 + 5 + 5 + 5 + 5 = 24** |

### FIN - Finance & Insurance

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Business Criticality | 5 | F&I is highest-margin department. Finance applications, loan calculations, lease structuring, product sales. |
| Technical Complexity | 4 | 7 programs, 5,135 SLOC. Loan amortization (COMLONL0), lease residual (COMLESL0), finance approval workflow, document generation (FINDOC00 at 933 lines). |
| Integration Density | 3 | Depends on SAL (deal data) and CUS (credit). Self-contained calculation engines. |
| Risk Level | 5 | Financial precision critical (DECIMAL arithmetic). Regulatory compliance (APR disclosure, lease calculations). Rounding rules must be exact. |
| Modernization Readiness | 2 | COBOL DECIMAL(11,2) arithmetic must map to Java BigDecimal with identical rounding. Amortization schedule generation must produce bit-identical results. Extensive regression testing required. |
| **Composite** | **21** | **6 - 2 + 5 + 4 + 3 + 5 = 21** |

### FPL - Floor Plan Management

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Business Criticality | 4 | Floor plan interest is a major expense. Incorrect calculations directly cost money daily. |
| Technical Complexity | 3 | 5 programs, 2,531 SLOC. Interest accrual, payment processing, lender reporting. |
| Integration Density | 2 | Depends on VEH for vehicle data and ADM for lender config. COMINTL0 is self-contained. |
| Risk Level | 5 | Daily interest accrual. Financial precision. Lender reconciliation must be exact. |
| Modernization Readiness | 3 | Small module. Interest calculation is well-isolated in COMINTL0. But financial precision requires careful BigDecimal migration. |
| **Composite** | **17** | **6 - 3 + 4 + 3 + 2 + 5 = 17** |

### STK - Stock / Inventory Control

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Business Criticality | 4 | Inventory accuracy drives purchasing, aging, and financial reporting. |
| Technical Complexity | 3 | 10 programs, 4,886 SLOC. Position inquiry, adjustments, transfers, reconciliation, aging, snapshots, alerts. Many small programs (avg 489 LOC). |
| Integration Density | 4 | Central COMSTCK0 module called by VEH, PLI, SAL. Stock position is shared state. |
| Risk Level | 3 | Inventory counts must be accurate. Concurrent update handling. But no financial calculations beyond counting. |
| Modernization Readiness | 4 | Many simple inquiry/list programs. COMSTCK0 is the critical piece. Event-driven stock updates map well to Spring patterns. |
| **Composite** | **16** | **6 - 4 + 4 + 3 + 4 + 3 = 16** |

### REG - Registration & Title

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Business Criticality | 3 | Compliance-driven. Must generate correct registration documents per state. |
| Technical Complexity | 3 | 5 programs, 2,873 SLOC. Document generation, status tracking, validation, multi-state rules. |
| Integration Density | 3 | Depends on SAL, VEH, ADM (tax rates). |
| Risk Level | 4 | Multi-jurisdiction rules. Regulatory compliance. State-specific document requirements. |
| Modernization Readiness | 3 | Rule-based logic maps to strategy pattern. But state-specific rules need careful extraction and testing. |
| **Composite** | **16** | **6 - 3 + 3 + 3 + 3 + 4 = 16** |

### WRC - Warranty & Recall

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Business Criticality | 3 | Customer safety (recalls). Warranty claims impact profitability. |
| Technical Complexity | 3 | 6 programs, 3,294 SLOC. Warranty registration, recall campaign management, notification generation, recall batch feed. |
| Integration Density | 2 | Depends on VEH and CUS. Relatively isolated from sales/finance flow. |
| Risk Level | 3 | Recall tracking is safety-critical but the COBOL logic is straightforward DB operations. |
| Modernization Readiness | 4 | Clean domain. Recall campaign model maps well. Batch feed (WRCRCLB0) can become a REST endpoint. |
| **Composite** | **13** | **6 - 4 + 3 + 3 + 2 + 3 = 13** |

### PLI - Pipeline & Logistics

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Business Criticality | 3 | Supports vehicle ordering and tracking. Not directly revenue-generating but operationally important. |
| Technical Complexity | 4 | 8 programs, 5,709 SLOC. Production orders, shipment tracking, transit status (EDI 214), delivery, allocation, reconciliation, VPD schedule. |
| Integration Density | 4 | Depends on VEH, STK, ADM. EDI interface (COMEDIL0) is external integration point. |
| Risk Level | 3 | EDI parsing must be accurate. Stock updates on receive are critical. But no financial calculations. |
| Modernization Readiness | 3 | EDI integration needs modern replacement (AS2/API). Complex multi-step workflows. But well-structured programs. |
| **Composite** | **17** | **6 - 3 + 3 + 4 + 4 + 3 = 17** |

### BAT - Batch Processing

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Business Criticality | 4 | Daily/weekly/monthly processing. Sales summaries, CRM feeds, data lake extract, GL integration, purge/archive. |
| Technical Complexity | 4 | 11 programs, 7,003 SLOC. Checkpoint/restart logic. Cursor-based processing. Multi-phase jobs. |
| Integration Density | 5 | Reads/writes across ALL tables. Generates summary data consumed by reports. GL integration. CRM feed. Data lake extract. |
| Risk Level | 4 | Data integrity across large volumes. Checkpoint/restart must work correctly. GL postings must balance. |
| Modernization Readiness | 3 | Spring Batch maps well. Checkpoint/restart -> Spring Batch job repository. But GL integration and data lake patterns need redesign. |
| **Composite** | **20** | **6 - 3 + 4 + 4 + 5 + 4 = 20** |

### RPT - Reports

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Business Criticality | 3 | Management reporting. Daily, weekly, monthly sales/inventory/finance reports. |
| Technical Complexity | 3 | 14 programs, 9,312 SLOC (high SLOC but repetitive report generation patterns). Largest single program: RPTSUP00 at 1,154 lines. |
| Integration Density | 2 | Read-only. No common module calls. Direct SQL against all tables. |
| Risk Level | 2 | Read-only operations. Number formatting must match. But no data mutation risk. |
| Modernization Readiness | 5 | Reports can be rebuilt with modern reporting tools. SQL queries port to PostgreSQL with minor syntax changes. |
| **Composite** | **11** | **6 - 5 + 3 + 3 + 2 + 2 = 11** |

---

## Composite Score Summary & Wave Assignment

| Module | Bus.Crit | Tech.Cmplx | Integ.Dens | Risk | Mod.Ready (inv) | Composite | Wave |
|--------|----------|------------|------------|------|-----------------|-----------|------|
| ADM | 2 | 3 | 4 | 2 | 1 (=6-5) | **12** | 1 |
| RPT | 3 | 3 | 2 | 2 | 1 (=6-5) | **11** | 1 |
| WRC | 3 | 3 | 2 | 3 | 2 (=6-4) | **13** | 1 |
| CUS | 4 | 3 | 2 | 3 | 2 (=6-4) | **14** | 2 |
| STK | 4 | 3 | 4 | 3 | 2 (=6-4) | **16** | 2 |
| REG | 3 | 3 | 3 | 4 | 3 (=6-3) | **16** | 2 |
| FPL | 4 | 3 | 2 | 5 | 3 (=6-3) | **17** | 3 |
| PLI | 3 | 4 | 4 | 3 | 3 (=6-3) | **17** | 3 |
| BAT | 4 | 4 | 5 | 4 | 3 (=6-3) | **20** | 4 |
| VEH | 5 | 4 | 5 | 4 | 3 (=6-3) | **21** | 3 |
| FIN | 5 | 4 | 3 | 5 | 4 (=6-2) | **21** | 4 |
| SAL | 5 | 5 | 5 | 5 | 4 (=6-2) | **24** | 5 |

---

## Recommended Wave Sequence

### Wave 1: Foundation (Weeks 1-8)
**Modules: ADM, RPT, WRC + Common Modules Infrastructure**

**Rationale:**
- ADM provides the reference data foundation (dealers, models, pricing, tax rates, users) that all other modules need. Must be migrated first.
- RPT is read-only and low risk. Provides early proof of data migration success by validating report outputs match mainframe.
- WRC is relatively isolated and provides a complete vertical slice (online + batch recall feed) for pattern validation.
- Common modules (COMDBEL0, COMLGEL0, COMFMTL0, COMDTEL0, COMSEQL0, COMMSGL0) become Spring `@Service` classes in this wave.

**Deliverables:**
- Spring Boot application scaffold with module structure
- PostgreSQL schema migration (all 53 tables)
- Admin module REST APIs + React UI
- Report generation (replace COBOL reports with JasperReports or equivalent)
- Warranty/Recall module full stack
- Common services layer (audit, error handling, formatting, sequence generation)

### Wave 2: Customer & Inventory (Weeks 9-16)
**Modules: CUS, STK, REG**

**Rationale:**
- CUS is the second foundational entity (after Vehicle). Customer data is needed by Sales and Finance.
- STK depends on ADM (Wave 1) and feeds into VEH (Wave 3). COMSTCK0 becomes a Spring service.
- REG depends on ADM (tax rates) and is compliance-driven.

**Deliverables:**
- Customer management full stack (CRUD, leads, credit check, history)
- Stock management full stack (inquiry, adjustments, transfers, reconciliation, aging, alerts)
- Registration module (document generation, status tracking, multi-state rules)
- COMSTCK0, COMVALD0, COMTAXL0 migrated as Spring services

### Wave 3: Vehicle & Pipeline (Weeks 17-24)
**Modules: VEH, PLI, FPL**

**Rationale:**
- VEH is the most connected module but depends on STK (Wave 2) and ADM (Wave 1).
- PLI provides the vehicle lifecycle from order to delivery. EDI replacement is a major effort.
- FPL is small but financially sensitive. Benefits from having VEH complete.

**Deliverables:**
- Vehicle management full stack (receive, update, transfer, inquiry, aging, location)
- Pipeline module (production orders, shipments, transit tracking, delivery, allocation)
- Floor plan module (add to plan, interest calculation, payments, reporting)
- COMVINL0, COMPRCL0, COMINTL0, COMEDIL0 migrated
- EDI replaced with REST APIs or modern AS2

### Wave 4: Batch & Finance (Weeks 25-32)
**Modules: BAT, FIN**

**Rationale:**
- BAT aggregates data from all online modules. By Wave 4, all source tables are in PostgreSQL.
- FIN requires the most rigorous testing (financial precision). Benefits from having CUS (credit) and SAL dependencies partially available.
- COMLONL0 and COMLESL0 (loan/lease calculators) require extensive parallel testing.

**Deliverables:**
- Spring Batch jobs replacing all 11 batch programs
- Finance module full stack (applications, approvals, calculations, lease, document generation)
- GL integration modernization
- Data lake extract modernization
- CRM feed modernization

### Wave 5: Sales Core (Weeks 33-40)
**Modules: SAL**

**Rationale:**
- SAL is the most complex module (highest composite score: 24). It depends on ALL other modules.
- By Wave 5, all dependencies are modernized: CUS, VEH, FIN, ADM, STK.
- Deal state machine requires extensive parallel testing with the mainframe.
- This is the highest-risk, highest-value migration. Dedicate a full wave.

**Deliverables:**
- Sales deal lifecycle (quote, negotiate, trade-in, approve, complete, cancel)
- Deal state machine with full workflow
- Pricing engine (COMPRCL0 integration)
- Tax calculation (COMTAXL0 integration)
- Incentive management
- Trade-in valuation
- Sales approval workflow

---

## Risk-Adjusted Timeline

| Wave | Duration | Parallel Run | Go-Live |
|------|----------|-------------|---------|
| Wave 1 | 8 weeks dev | 2 weeks | Week 10 |
| Wave 2 | 8 weeks dev | 2 weeks | Week 18 |
| Wave 3 | 8 weeks dev | 3 weeks | Week 27 |
| Wave 4 | 8 weeks dev | 4 weeks | Week 36 |
| Wave 5 | 8 weeks dev | 4 weeks | Week 44 |
| Stabilization | -- | -- | Weeks 44-48 |

**Total estimated timeline: 48 weeks (12 months)** including parallel run periods and stabilization.
