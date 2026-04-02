# AUTOSALES Mainframe Modernization Plan

## Executive Summary

**System:** AUTOSALES — Automotive Dealer Sales & Reporting Platform
**Current Platform:** IBM Mainframe (IMS DC / COBOL / DB2 / IMS Hierarchical DB / REXX / CLIST / MFS / JCL / EDI)
**Scale:** 103+ COBOL programs, 46+ DB2 tables, 5 IMS hierarchical databases, 10 business domains
**Industry:** Automotive retail — high-transaction, regulation-heavy, multi-party integration

This system is fundamentally different from prior CICS-based modernizations. The IMS DC transaction processing model, dual data stores, complex deal lifecycle state machine, EDI carrier integration, and deep financial calculation engine require a thoughtful architecture — not a lift-and-shift.

---

## 1. Current State Assessment

### 1.1 System Profile

| Dimension | Detail |
|-----------|--------|
| **Transaction Model** | IMS DC (Message Format Service screens, GU/ISRT message handling, PCB-based DB access) |
| **Data Architecture** | Dual: DB2 relational (46+ tables) + IMS hierarchical (5 DBDs with parent-child segments) |
| **Online Programs** | 76 across 10 modules (ADM, CUS, SAL, FIN, FPL, STK, VEH, PLI, REG, WRC) |
| **Batch Programs** | 11 (daily, weekly, monthly, quarterly cycles with checkpoint/restart) |
| **Common Libraries** | 16 reusable COBOL subroutines (financial calcs, validation, formatting, audit, EDI parsing) |
| **Screen Definitions** | 16 MFS (Message Format Service) — NOT BMS maps |
| **External Integrations** | EDI 214/856, CRM feed, DMS feed, GL posting, Data Lake, Manufacturer inbound |
| **Security** | IMS sign-on with password hash, account lockout at 5 failures |

### 1.2 Business Domain Map

```
┌─────────────────────────────────────────────────────────────────┐
│                     AUTOSALES DOMAIN MAP                        │
├─────────────┬───────────────┬───────────────┬──────────────────┤
│ CUSTOMER    │ SALES         │ FINANCE       │ VEHICLE          │
│ Management  │ Process       │ & Lending     │ Lifecycle        │
│ (7 programs)│ (8 programs)  │ (12 programs) │ (24+ programs)   │
│             │               │               │                  │
│ • Add/Edit  │ • Quote       │ • Loan calc   │ • Production     │
│ • Search    │ • Negotiate   │ • Lease calc  │ • Shipment       │
│ • Credit    │ • Trade-in    │ • Floor plan  │ • Receiving      │
│ • Leads     │ • Approve     │ • F&I products│ • Stock mgmt     │
│ • History   │ • Complete    │ • Documents   │ • Aging           │
│             │ • Cancel      │ • Credit check│ • Transfer       │
│             │ • Incentives  │               │ • PDI/Location   │
├─────────────┴───────┬───────┴───────────────┴──────────────────┤
│ REGISTRATION        │ WARRANTY & RECALL                         │
│ (5 programs)        │ (6 programs)                              │
│ • Generate/Validate │ • Warranty registration                   │
│ • Submit to DMV     │ • Recall campaigns                        │
│ • Track status      │ • Notification generation                 │
├─────────────────────┴──────────────────────────────────────────┤
│ ADMINISTRATION (8 programs)                                     │
│ Dealer master, Tax rates, Pricing, Models, Incentives, Config   │
├────────────────────────────────────────────────────────────────┤
│ BATCH PROCESSING (11 programs)                                  │
│ Daily EOD, Weekly aging, Monthly close, GL/CRM/DMS extracts     │
└────────────────────────────────────────────────────────────────┘
```

### 1.3 Critical Complexity Factors

1. **Deal Lifecycle State Machine:** WS(worksheet) → NE(negotiation) → PA(pending approval) → AP(approved) → FI(in finance) → DL(delivered) → CA(cancelled)/UW(unwound). Each transition has validation rules, side effects (stock updates, GL postings, warranty triggers), and authority requirements.

2. **Dual Data Store:** IMS hierarchical databases store vehicle/customer/finance data in parent-child segment trees. DB2 stores the same data in normalized tables. Both must be consolidated into a single relational model without data loss.

3. **Financial Calculation Engine:** Loan amortization (M = P[r(1+r)^n]/[(1+r)^n-1]), lease structures (cap cost, residual, money factor), floor plan daily interest accrual with 3 day-count conventions (30/360, 365, actual), multi-jurisdiction tax calculations.

4. **EDI Integration:** ANSI X12 214 (carrier shipment status) and 856 (advance ship notice) with ISA/GS/ST envelope validation, segment parsing, and vehicle tracking through transit.

5. **VIN Intelligence:** NHTSA check digit algorithm with transliteration table, WMI decoding, model year extraction — used across multiple modules.

---

## 2. Architecture Options Analysis

### Option A: Microservices (Spring Boot) — *Prior Project Pattern*
- 8 services, each with own DB schema
- REST APIs between services
- API Gateway for routing

**Pros:** Proven in 3 prior projects, independent deployment, team scalability
**Cons:** For THIS system — excessive service-to-service calls for deal operations that span Customer + Vehicle + Finance + Stock + Registration. A single deal completion touches 6+ tables across 4 would-be services. Network latency and distributed transaction complexity would be painful.

### Option B: Modular Monolith (Spring Boot) — *Recommended*
- Single deployable application with clearly separated modules (packages)
- Shared database with module-owned table conventions
- Internal method calls (not REST) between modules
- Can be decomposed into microservices later if needed

**Pros:**
- Deal lifecycle can span Customer → Vehicle → Finance → Stock → Registration in a single @Transactional boundary — critical for data consistency
- No distributed transaction headaches (no saga patterns needed)
- Simpler deployment and operations (Rajesh's 8GB RAM constraint)
- Faster development — no inter-service contract negotiation
- **Can always extract services later** when/if scaling demands it

**Cons:** Monolith discipline required (module boundaries must be enforced by convention)

### Option C: Event-Driven Microservices
- Services communicate via events (Kafka/RabbitMQ)
- Eventually consistent

**Pros:** Loose coupling, good for high-scale
**Cons:** Massive complexity for this use case. Financial calculations require strong consistency. Overkill for a modernization pilot.

### **Recommendation: Option B — Modular Monolith**

The AUTOSALES system has **deep cross-domain dependencies** that make microservices a poor initial fit:
- Completing a sale requires Customer + Vehicle + Stock + Finance + Registration changes atomically
- Floor plan interest calculation reads Vehicle + Lender + rates in a single pass
- GL posting reads Deals + Vehicles + Finance to generate entries
- VIN validation is used by Sales, Vehicle, Production, and Registration modules

A modular monolith gives us **the discipline of domain separation** (clear package boundaries, module-level ownership) with **the simplicity of local calls and shared transactions**. This is the pragmatic choice.

---

## 3. Target Architecture — Modular Monolith

### 3.1 Module Structure

```
autosales-app/
├── common/                    # Shared infrastructure
│   ├── security/              # JWT, authentication, RBAC
│   ├── audit/                 # @Auditable AOP + audit_log
│   ├── util/                  # VIN decoder, date utils, formatting
│   └── exception/             # Global exception handling
├── modules/
│   ├── admin/                 # Dealer, Model, Pricing, Tax, Config, Incentives
│   ├── customer/              # Customer CRUD, Credit, Leads, History
│   ├── sales/                 # Deal lifecycle, Quote, Negotiate, Approve, Complete
│   ├── finance/               # Loan, Lease, F&I, Credit check, Floor plan
│   ├── vehicle/               # Vehicle CRUD, Stock, Inventory, Production, Logistics
│   ├── registration/          # Reg lifecycle, DMV submission, Warranty, Recall
│   └── batch/                 # Scheduled jobs: daily, weekly, monthly, quarterly
├── integration/               # External system adapters
│   ├── edi/                   # EDI 214/856 parser (from COMEDIL0)
│   ├── crm/                   # CRM feed generator
│   ├── dms/                   # DMS interface
│   ├── gl/                    # GL posting interface
│   └── datalake/              # Data lake extract
└── frontend/                  # React SPA
    ├── pages/
    │   ├── dashboard/
    │   ├── customers/
    │   ├── sales/             # Deal workspace, negotiation desk, pipeline
    │   ├── finance/           # Calculators, floor plan, F&I
    │   ├── vehicles/          # Inventory, stock, aging, shipments
    │   ├── registration/
    │   ├── warranty/
    │   ├── admin/
    │   └── reports/
    └── components/            # Shared UI components
```

### 3.2 Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **Frontend** | React 18 + Vite + Tailwind CSS | Proven, component-rich, fast DX |
| **Backend** | Spring Boot 3.3 (single app) | Modular monolith, single JVM |
| **ORM** | Spring Data JPA + Hibernate | Module-level repositories |
| **Database** | PostgreSQL 16 | Single instance, all modules |
| **Migrations** | Flyway | Ordered scripts per module |
| **Auth** | Spring Security + JWT | Stateless auth with RBAC |
| **Batch** | Spring @Scheduled + REST triggers | Replace JCL batch with on-demand + scheduled |
| **Audit** | AOP @Auditable annotation | Replaces COMLGEL0 across all modules |
| **Charts** | Recharts | Dashboard KPIs |
| **Export** | Apache POI (XLSX) + CSV | All list views |
| **Build** | Maven | Single pom.xml |
| **VIN** | Custom Java utility | Port NHTSA algorithm from COMVALD0/COMVINL0 |
| **Financial Calc** | Java BigDecimal | Port from COMLONL0/COMLESL0/COMINTL0/COMTAXL0 |

### 3.3 IMS DC → Spring Boot Mapping

| IMS DC Concept | Modular Monolith Equivalent |
|----------------|----------------------------|
| MFS screen (MID/MOD) | React page + REST endpoint |
| IMS transaction code (ADMC, CSAD, etc.) | REST API route (/api/admin/config, /api/customers, etc.) |
| IMS GU (Get Unique) message input | @RequestBody DTO |
| IMS ISRT message output | @ResponseBody DTO |
| PSB (Program Spec Block) | @Transactional service method scope |
| DBD segments (hierarchical) | JPA entities with @OneToMany/@ManyToOne |
| DL/I GU/GN/ISRT/REPL/DLET | JPA findById/findAll/save/save/delete |
| PCB status codes | JPA exceptions (EntityNotFound, DataIntegrity) |
| DB2 EXEC SQL cursors | Spring Data JPA queries + Pageable |
| COBOL CALL subroutines (COM*) | Spring @Service beans in common/ or module-internal |
| Checkpoint/Restart (COMCKPL0) | @Transactional + @Scheduled with idempotent design |
| MFS field attributes (protected/unprotected) | React form validation (disabled/required) |
| IMS ROLL (abort) | @Transactional rollback |
| REXX automation scripts | REST API endpoints + admin UI |
| CLIST TSO scripts | Eliminated (replaced by modern DevOps) |
| JCL batch scheduling | Spring @Scheduled + manual trigger endpoints |
| EDI 214/856 (COMEDIL0) | Java EDI parser in integration/edi/ module |

### 3.4 Database Schema — IMS Hierarchical → PostgreSQL Relational

**DBDAUTO1 (Vehicle/Inventory) → 4 tables:**
```sql
vehicle (PK: vin VARCHAR(17))
  ├── vehicle_option (FK: vin) — 1:N, options/packages
  ├── vehicle_status_hist (FK: vin) — 1:N, status audit trail
  └── lot_location (FK: vin) — 1:1, physical location
```

**DBDAUTO2 (Customer/Sales) → 5 tables:**
```sql
customer (PK: customer_id SERIAL)
  ├── customer_lead (FK: customer_id) — 1:N, lead pipeline
  └── sales_deal (FK: customer_id) — 1:N, deals
       ├── deal_line_item (FK: deal_number) — 1:N, pricing components
       └── trade_in (FK: deal_number) — 0:N, trade vehicles
```

**DBDAUTO3 (Finance/Lending) → 5 tables:**
```sql
finance_app (PK: finance_id)
  ├── finance_product (FK: finance_id) — 1:N, F&I products on deal
  ├── lease_terms (FK: finance_id) — 0:1, lease-specific terms
  └── floor_plan_vehicle (PK: fp_vehicle_id)
       └── floor_plan_interest (FK: fp_vehicle_id) — 1:N, daily accruals
```

**DBDAUTO4 (Pricing/Rates) → 3 tables:**
```sql
price_master (PK: model_year + make_code + model_code + effective_date)
tax_rate (PK: state + county + city + effective_date)
incentive_program (PK: incentive_id)
```

**DBDAUTO5 (Reporting) → 3 tables:**
```sql
monthly_snapshot, stock_snapshot, audit_log
```

**DB2 tables (direct migration) → ~30 tables:**
All remaining DB2 tables migrate 1:1 with `CHAR(n) → VARCHAR(n)` to avoid Hibernate padding.

**Total PostgreSQL tables: ~46**

### 3.5 Port Configuration

| Component | Port |
|-----------|------|
| Spring Boot App | 8480 |
| React Frontend | 3004 |
| PostgreSQL | 5432 (shared) |

*Single application port — no gateway needed for monolith.*

---

## 4. Wave Plan

### Wave 0: Foundation (Auth + Common + Database)
**Source Programs:** ADMSEC00 + all COM* utility patterns
**Deliverables:**
- Spring Boot application scaffold (modular monolith structure)
- PostgreSQL schema with Flyway migrations (all 46 tables)
- Spring Security + JWT authentication
- User management (login, lockout at 5 failures, RBAC)
- Common utilities: VIN decoder (from COMVALD0/COMVINL0), date utils (COMDTEL0), formatting (COMFMTL0)
- @Auditable AOP (replaces COMLGEL0)
- Global exception handling (replaces COMDBEL0)
- React app scaffold with login, sidebar navigation, protected routes

### Wave 1: Reference Data (Admin Module)
**Source Programs:** ADMCFG00, ADMDLR00, ADMINC00, ADMMFG00, ADMPRC00, ADMPRD00, ADMTAX00
**Deliverables:**
- Admin module: Dealer CRUD, Model/Make master, Pricing with effective dates, Tax rates (state/county/city), Incentive programs, F&I product catalog, System configuration
- React: Admin pages with data tables, add/edit forms, search

### Wave 2: Customer Module
**Source Programs:** CUSADD00, CUSCRED0, CUSHIS00, CUSINQ00, CUSLEAD0, CUSLST00, CUSUPD00
**Deliverables:**
- Customer module: CRUD + search + duplicate detection
- Credit pre-qualification (simulated bureau, tier A-E)
- Lead tracking lifecycle (NW→CT→AP→TS→QT→WN/LS)
- Purchase history with aggregations
- React: Customer list, detail, add/edit, credit check, lead board

### Wave 3: Sales Process (Core)
**Source Programs:** SALQOT00, SALNEG00, SALTRD00, SALINC00, SALVAL00, SALAPV00, SALCMP00, SALCAN00
**Deliverables:**
- Sales module: Complete deal lifecycle state machine
- Quote generation with pricing breakdown (line items, options, fees, taxes)
- Negotiation desk (margin visibility for managers, counter offers)
- Trade-in evaluation (VIN decode, condition-based ACV, payoff)
- Incentive application (stackable/non-stackable, eligibility validation)
- Deal validation (comprehensive pre-approval checks)
- Approval workflow (auto-approve < $500, GM for negative gross)
- Completion (checklist, stock update, warranty trigger, registration trigger)
- Cancellation/unwind (reverse all downstream effects atomically)
- React: Deal workspace, pipeline board, negotiation desk, approval queue

### Wave 4: Finance & Floor Plan
**Source Programs:** FIN* (7) + FPL* (5)
**Deliverables:**
- Finance module: Application capture + approval workflow (AP/CD/DN)
- Loan calculator (amortization table, multi-term comparison: 36/48/60/72)
- Lease calculator (cap cost, residual, money factor, drive-off breakdown)
- Credit check interface (simulated bureau, DTI ratio)
- F&I product selection (10 products, multi-select, deal total recalc)
- Document generation (loan/lease/cash closing documents)
- Floor plan: Add vehicle, inquiry with filters, interest calculation (3 day-count bases), payoff, exposure report by lender
- React: Finance application form, calculators, F&I menu, floor plan dashboard

### Wave 5: Vehicle & Inventory
**Source Programs:** VEH* (8) + STK* (8+) + PLI* (8)
**Deliverables:**
- Vehicle module: Complete inventory lifecycle (Production → Ship → Receive → Stock → Sell)
- Vehicle CRUD with VIN validation/decode
- Stock position tracking (on-hand, in-transit, allocated, on-hold, sold MTD/YTD)
- Inventory aging buckets (0-30, 31-60, 61-90, 91-120, 120+)
- Hold/release, stock reconciliation, dealer-to-dealer transfer
- Lot location management (zone/row/spot)
- Production order processing, shipment creation
- Transit status (EDI 214 webhook endpoint), ETA tracking with timeline
- PDI scheduling and completion, low stock alerts
- React: Vehicle search, stock dashboard, aging report, shipment tracker, transfer workflow

### Wave 6: Registration & Warranty/Recall
**Source Programs:** REG* (5) + WRC* (6)
**Deliverables:**
- Registration module: Generate → Validate → Submit → Track status
- DMV submission with tracking number
- Warranty auto-registration on sale completion (4 coverages: basic, powertrain, corrosion, emission)
- Warranty coverage inquiry with remaining days/miles
- Recall campaign management (create, track vehicles, update status)
- Recall notification generation
- Warranty claims summary
- React: Registration tracker, warranty lookup, recall dashboard

### Wave 7: Batch & Integration
**Source Programs:** BAT* (11) + integration adapters
**Deliverables:**
- Batch module: All scheduled jobs (daily/weekly/monthly/quarterly)
  - Daily: Delivery status update, pending deal expiry (30 days), floor plan interest accrual
  - Weekly: Inventory aging recalc, warranty expiry notices, recall completion %
  - Monthly: Dealer snapshots, MTD counter roll, 18-month deal archival
  - Quarterly: Registration archive (2yr), audit purge (3yr), notification purge (1yr)
- Integration adapters: CRM feed, DMS interface, GL posting, Data lake extract, Manufacturer inbound feed, EDI 214/856 parser
- React: Batch job dashboard, run history, on-demand trigger buttons, integration status

---

## 5. Enhancement Plan (Beyond Mainframe Parity)

| # | Enhancement | Business Value |
|---|------------|----------------|
| 1 | **Sales Pipeline Dashboard** | Kanban board: deals by stage (WS→NE→PA→AP→DL) with drag-and-drop |
| 2 | **Inventory Health Dashboard** | Aging heat map, stock turn rate, days-supply by model, value at risk |
| 3 | **Finance Calculator Suite** | Side-by-side loan vs lease comparison with what-if scenarios |
| 4 | **Floor Plan Exposure Dashboard** | Total exposure by lender, curtailment alerts, interest trend charts |
| 5 | **Audit Trail with AOP** | @Auditable on all operations, searchable audit log UI |
| 6 | **Excel/CSV Export** | Every list view exportable (Apache POI for XLSX) |
| 7 | **Real-time Deal Profitability** | Live gross calculation as deal terms change (front/back/total) |
| 8 | **VIN Instant Decode** | Type VIN → immediate make/model/year/plant decode |
| 9 | **On-demand Reports** | Any batch report runnable instantly (vs waiting for nightly cycle) |
| 10 | **System Health Dashboard** | Batch job status, last run times, integration health |
| 11 | **User Management UI** | RBAC administration with role assignment |
| 12 | **Paginated + Searchable Lists** | All list views with server-side pagination, filter, sort |

---

## 6. Testing Strategy

| Level | Scope | Tool | Est. Count |
|-------|-------|------|-----------|
| Unit (Backend) | Service layer, calculators, VIN validation | JUnit 5 + Mockito | ~130 |
| Integration (Backend) | Controller endpoints + database | @SpringBootTest | ~70 |
| Frontend | React components + pages | Vitest + Testing Library | ~60 |
| Financial Precision | Loan/lease/interest/tax calculations | Parameterized JUnit | ~30 |
| **Total** | | | **~290** |

### Known Patterns (applied from Day 1):
- UUID suffix for all test data IDs
- `isString()` for mutable field assertions
- Standalone MockMvc (not @WebMvcTest)
- BigDecimal assertions to 2 decimal places for financial calcs
- VARCHAR for all string columns (no CHAR)
- `scanBasePackages` includes common package

---

## 7. Risk Register

| # | Risk | Sev | Like | Mitigation |
|---|------|-----|------|------------|
| 1 | IMS hierarchical data flattening loses relationships | High | Med | Map every DBD segment chain; validate with test data |
| 2 | Financial calc precision divergence | High | Low | Port exact COBOL algorithms using BigDecimal; test with known values |
| 3 | Deal state machine edge cases | High | Med | Comprehensive state transition matrix; test every valid/invalid transition |
| 4 | Cross-module transaction consistency | Med | Low | Monolith advantage: single @Transactional boundary spans modules |
| 5 | EDI parsing regression | Med | Low | Port COMEDIL0 logic; test with sample EDI 214/856 messages |
| 6 | Floor plan interest day-count variance | Med | Med | Support all 3 bases (360/365/ACT); validate against COBOL output |
| 7 | Multi-jurisdiction tax complexity | Med | Low | Port COMTAXL0; test representative state/county/city combos |
| 8 | 8GB RAM constraint for dev/test | Med | High | Monolith advantage: single JVM (~512MB) vs 8 separate services |
| 9 | Hibernate CHAR padding | Low | High | All VARCHAR from Day 1 (known from 3 prior projects) |
| 10 | Test DB state collisions | Low | High | UUID suffix pattern enforced from Wave 0 |

---

## 8. Why Modular Monolith Over Microservices (for THIS system)

| Factor | Microservices | Modular Monolith |
|--------|--------------|------------------|
| **Deal completion** (touches Customer + Vehicle + Stock + Finance + Registration) | 5 service calls, distributed transaction, saga pattern | Single @Transactional — atomic, consistent |
| **Sale cancellation/unwind** (reverses 6+ tables) | Complex compensation logic across services | Single rollback — all or nothing |
| **Floor plan interest batch** (reads Vehicle + Lender + rates) | Cross-service queries or data duplication | Direct JPA queries — no network hop |
| **GL posting** (reads Deals + Vehicles + Finance) | 3 API calls per deal | Single database query |
| **Memory footprint** (8GB laptop) | 8 JVMs × ~256MB = 2GB+ | 1 JVM × ~512MB |
| **Deployment simplicity** | 8 services + gateway + config | 1 JAR file |
| **Future extraction** | Already decomposed | Module boundaries ready to extract when needed |

The modular monolith is **not a compromise** — it's the right architecture for a system where business operations span multiple domains atomically. Microservices can be extracted later from well-defined module boundaries when scaling demands it.

---

## 9. Documentation Deliverables

### Legacy System (pre-modernization)
1. Codebase overview, program inventory, business functions, data flows
2. Per-program documentation (~103 files)
3. Per-domain data flow documentation (~10 files)
4. Program index and cross-program synthesis

### Modernized Application
1. API reference, architecture overview, developer setup guide
2. Database schema with COBOL→PostgreSQL mapping
3. Traceability matrix (COBOL program → Java class, MFS → React page)
4. Test inventory and strategy

### Planning & Presentations
1. This modernization plan
2. Executive summary approval deck (PPTX)
3. Risk register and mitigation plan
4. Demo video (post-completion)

---

## 10. Success Metrics

| Metric | Target |
|--------|--------|
| Functional parity | 100% of 103+ COBOL programs |
| Tests | ~290, 0 failures |
| Enhancements beyond parity | 12 |
| API response time | < 500ms |
| Documentation files | 130+ |
| Pre-production bugs | < 10 (trending: 15→9→8→?) |

---

## 11. Cross-Project Context

| Project | Source | Target | Stack | Architecture |
|---------|--------|--------|-------|-------------|
| #1 CardDemo | 48 COBOL (CICS/VSAM) | 9 microservices | Spring Boot + React + PostgreSQL | Microservices |
| #2 GenApp | 31 COBOL (CICS/VSAM) | 4 microservices | Spring Boot + React + PostgreSQL | Microservices |
| #3 Portfolio | 38 COBOL (CICS/DB2/VSAM) | 5 microservices | Spring Boot + React + PostgreSQL | Microservices |
| **#4 AUTOSALES** | **103+ COBOL (IMS DC/DB2/IMS)** | **Modular monolith** | **Spring Boot + React + PostgreSQL** | **Modular Monolith** |

**Why the architecture shift:** Prior systems were CICS-based with relatively independent domains. AUTOSALES has deeply interdependent domains (a single deal operation spans 6+ domains) making a modular monolith the pragmatic choice. This also demonstrates architectural flexibility — choosing the right pattern for the problem, not repeating the same solution.

---

*Generated: 2026-03-29 | Project #4 in AI-Assisted Mainframe Modernization Series*
