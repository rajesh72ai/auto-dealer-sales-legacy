# AUTOSALES Modernization Risks & Challenges Register

> Comprehensive risk assessment for IMS DC/COBOL/DB2 to Spring Boot/React/PostgreSQL migration.
> Date: 2026-03-29

---

## Risk Severity Matrix

| | **High Likelihood** | **Medium Likelihood** | **Low Likelihood** |
|---|---|---|---|
| **Critical Impact** | Immediate Action | High Priority | Monitor Closely |
| **High Impact** | High Priority | Significant | Monitor |
| **Medium Impact** | Significant | Moderate | Low Priority |
| **Low Impact** | Moderate | Low Priority | Accept |

---

## Risk Register

### R-001: IMS Hierarchical Data Migration to Relational Model

| Field | Value |
|-------|-------|
| **Risk ID** | R-001 |
| **Category** | Data |
| **Severity** | Critical |
| **Likelihood** | High |
| **Description** | The AUTOSALES system uses IMS DB with hierarchical segments (defined in 13 DBD files) alongside DB2 relational tables (53 tables). The IMS hierarchical data model uses parent-child segment relationships, PCB masks (PSB definitions), and DL/I calls (GU, GN, GNP, ISRT, REPL, DLET) that have no direct PostgreSQL equivalent. All 80+ online programs use CBLTDLI calls for IMS I/O PCB message handling. |
| **Impact** | Incorrect data migration could corrupt customer records, vehicle inventory, and deal history. Loss of hierarchical relationships. IMS segment search arguments (SSAs) must be converted to SQL WHERE clauses. Orphaned records. |
| **Mitigation** | 1) Map every DBD segment hierarchy to PostgreSQL foreign key relationships before migration. 2) Create automated data migration scripts with row-count and checksum validation per table. 3) Run parallel data validation comparing IMS GU/GN results against PostgreSQL SELECT results for 100% of segments. 4) IMS I/O PCB message handling replaced by Spring MVC request/response pattern. 5) Build a DL/I-to-SQL mapping document for each program. |
| **Owner** | Data Migration Lead / Database Architect |

### R-002: Financial Calculation Precision (COBOL DECIMAL vs Java BigDecimal)

| Field | Value |
|-------|-------|
| **Risk ID** | R-002 |
| **Category** | Technical |
| **Severity** | Critical |
| **Likelihood** | High |
| **Description** | COBOL uses fixed-point DECIMAL arithmetic (PIC S9(9)V99 COMP-3) with deterministic truncation behavior. DB2 stores DECIMAL(11,2) and DECIMAL(9,2) columns. The system performs loan amortization (COMLONL0, 415 LOC), lease residual calculation (COMLESL0, 450 LOC), floor plan interest accrual (COMINTL0, 627 LOC), pricing with holdback/advertising fees (COMPRCL0, 627 LOC), and multi-jurisdiction tax calculation (COMTAXL0, 524 LOC). Java BigDecimal rounding modes differ from COBOL truncation. |
| **Impact** | Penny-level differences in loan payments, lease payments, tax amounts, or floor plan interest accumulate over thousands of transactions. Regulatory compliance issues (APR disclosure). Lender reconciliation failures. Customer disputes. |
| **Mitigation** | 1) Mandate `BigDecimal` with `RoundingMode.HALF_EVEN` (banker's rounding) throughout; verify against COBOL rounding behavior per module. 2) Create a "calculation parity test suite" with 10,000+ test cases extracted from production data. 3) Run parallel calculations on both systems for 30 days before cutover. 4) Document every rounding point in COMLONL0, COMLESL0, COMINTL0, COMPRCL0, COMTAXL0. 5) PostgreSQL NUMERIC type preserves exact precision -- use `NUMERIC(11,2)` not `DOUBLE PRECISION`. |
| **Owner** | Finance Module Lead / QA Lead |

### R-003: Deal State Machine Integrity

| Field | Value |
|-------|-------|
| **Risk ID** | R-003 |
| **Category** | Technical |
| **Severity** | Critical |
| **Likelihood** | Medium |
| **Description** | The sales deal lifecycle (SALQOT00 -> SALNEG00 -> SALAPV00 -> SALCMP00 / SALCAN00) implements a state machine with transitions: QUOTE -> NEGOTIATION -> PENDING_APPROVAL -> APPROVED -> COMPLETED / CANCELLED. Each transition involves multi-table updates (SALES_DEAL status, STOCK_POSITION via COMSTCK0, INCENTIVE_APPLICATION, TRADE_IN records). SALQOT00 alone is 1,173 lines with complex branching. State transitions trigger side effects (stock holds, finance app creation). |
| **Impact** | Incorrect state transitions could allow deals to be completed without approval, double-count stock, misapply incentives, or leave orphaned finance applications. Revenue recognition errors. |
| **Mitigation** | 1) Extract explicit state machine from COBOL IF/EVALUATE logic into a Spring State Machine or enum-based state pattern with guard conditions. 2) Document every valid transition with preconditions and postconditions. 3) Build integration tests for every transition path including error/rollback scenarios. 4) Implement optimistic locking on SALES_DEAL to prevent concurrent state mutations. 5) Add event sourcing for deal state changes to enable audit and replay. |
| **Owner** | Sales Module Lead |

### R-004: EDI Integration Replacement

| Field | Value |
|-------|-------|
| **Risk ID** | R-004 |
| **Category** | Integration |
| **Severity** | High |
| **Likelihood** | Medium |
| **Description** | COMEDIL0 (738 LOC) parses EDI 214 (shipment status), EDI 856 (advance ship notice), and EDI 997 (functional acknowledgment) transactions. BATINB00 (613 LOC) processes inbound EDI files. PLITRNS0 calls COMEDIL0 for real-time transit updates. These EDI transactions are exchanged with vehicle manufacturers and follow ANSI X12 standards with partner-specific variations. |
| **Impact** | Loss of manufacturer communication. Inability to track vehicle shipments. Production order confirmations disrupted. Potential SLA violations with OEM partners. |
| **Mitigation** | 1) Survey OEM partners for modern API availability (REST/GraphQL alternatives to EDI). 2) If EDI must continue, use a Java EDI library (e.g., BerryWorks, Smooks, or Spring Integration EDI) rather than hand-parsing. 3) Implement an integration layer (Apache Camel or Spring Integration) to abstract the transport (AS2, SFTP, API). 4) Create an EDI sandbox with sample transactions for each type. 5) Plan 4-week partner testing window. |
| **Owner** | Integration Lead / Pipeline Module Lead |

### R-005: VIN Validation and Decode Accuracy

| Field | Value |
|-------|-------|
| **Risk ID** | R-005 |
| **Category** | Technical |
| **Severity** | High |
| **Likelihood** | Medium |
| **Description** | COMVINL0 (822 LOC) implements VIN decode logic including World Manufacturer Identifier (WMI), Vehicle Descriptor Section (VDS), and Vehicle Identifier Section (VIS) parsing. COMVALD0 (619 LOC) validates VIN check digits per NHTSA algorithm. These are called by 8+ programs across VEH, PLI, SAL, FPL, WRC modules. VIN decode tables are embedded in COBOL working storage. |
| **Impact** | Invalid VINs accepted into inventory. Incorrect vehicle identification. Registration errors. Recall notification failures for wrong vehicles. |
| **Mitigation** | 1) Replace embedded VIN tables with NHTSA vPIC API integration for real-time decode (modernization enhancement). 2) Maintain COMVALD0 check-digit algorithm as a Java utility with identical logic. 3) Test with 50,000+ real VINs from production data. 4) Implement fallback to local decode tables if API is unavailable. 5) VIN validation is stateless -- ideal for unit testing. |
| **Owner** | Vehicle Module Lead |

### R-006: Multi-Jurisdiction Tax Calculation

| Field | Value |
|-------|-------|
| **Risk ID** | R-006 |
| **Category** | Business |
| **Severity** | High |
| **Likelihood** | Medium |
| **Description** | COMTAXL0 (524 LOC) calculates sales tax, registration fees, and documentary fees based on state/county/city jurisdiction. TAX_RATE table stores rates per jurisdiction with effective dates. Called by SAL (quote/negotiate), REG (registration generation), and ADM (tax rate maintenance). Tax rules vary by state (e.g., trade-in credit, cap on tax, exempt categories). COMPRCL0 calls COMTAXL0 internally. |
| **Impact** | Incorrect tax calculations lead to regulatory violations, customer overcharges/undercharges, and potential state audit liability. Multi-state dealers face compounded risk. |
| **Mitigation** | 1) Consider integrating Avalara, Vertex, or similar tax-as-a-service for production (modernization enhancement). 2) Migrate existing TAX_RATE table as fallback. 3) Create state-by-state test cases covering trade-in credits, exemptions, rate tiers. 4) Run parallel tax calculations for 90 days before cutover. 5) Implement tax calculation audit log showing inputs, rates applied, and output for every transaction. |
| **Owner** | Finance Module Lead / Compliance |

### R-007: Floor Plan Interest Accrual Precision

| Field | Value |
|-------|-------|
| **Risk ID** | R-007 |
| **Category** | Business |
| **Severity** | High |
| **Likelihood** | Medium |
| **Description** | COMINTL0 (627 LOC) calculates daily interest on floor-planned vehicles using lender-specific rates, day-count conventions (30/360 vs actual/365), and rate tiers based on aging buckets. BATDLY00 runs daily to accrue interest. FPLPAY00 processes curtailment payments. Interest calculations reference FLOOR_PLAN_VEHICLE, FLOOR_PLAN_INTEREST, and FLOOR_PLAN_LENDER tables. |
| **Impact** | Incorrect daily interest accrual compounds over vehicle holding periods (avg 60-90 days). Lender reconciliation discrepancies. Overpayment or underpayment of floor plan interest ($100K+ monthly exposure for large dealers). |
| **Mitigation** | 1) Extract day-count convention logic as a pluggable strategy (30/360, actual/360, actual/365). 2) Verify accrual calculations with lender statements for 6 months of historical data. 3) Implement daily reconciliation report comparing system accrual vs lender statement. 4) Use BigDecimal with 6+ decimal precision for intermediate calculations, round to 2 for posting. 5) Spring Batch `@Scheduled` job replaces BATDLY00 with identical checkpoint logic. |
| **Owner** | Floor Plan Module Lead / Finance |

### R-008: Batch Processing Migration (Checkpoint/Restart)

| Field | Value |
|-------|-------|
| **Risk ID** | R-008 |
| **Category** | Technical |
| **Severity** | High |
| **Likelihood** | Medium |
| **Description** | All 11 batch programs use COMCKPL0 (569 LOC) for IMS checkpoint/restart. COMCKPL0 issues CHKP and XRST calls via CBLTDLI. Checkpoint frequency varies (200-1000 records). BATRSTRT (449 LOC) manages restart positioning. Batch jobs process cursor-based result sets of 10K-500K+ records. RESTART_CONTROL table tracks checkpoint state. |
| **Impact** | Without proper checkpoint/restart, a failure at record 400K of 500K requires full reprocessing. Batch window exceeded. Data consistency issues if partial run is not properly rolled back. |
| **Mitigation** | 1) Use Spring Batch with `JdbcJobRepository` for checkpoint/restart (direct equivalent). 2) Map COMCKPL0 checkpoint frequency to Spring Batch `commit-interval`. 3) Implement `ItemReader` with restartable cursors. 4) Test failure/restart scenarios for each batch job. 5) Monitor batch execution time vs. mainframe baseline -- PostgreSQL may be faster but verify. |
| **Owner** | Batch Module Lead |

### R-009: Security Model Migration

| Field | Value |
|-------|-------|
| **Risk ID** | R-009 |
| **Category** | Technical |
| **Severity** | High |
| **Likelihood** | Low |
| **Description** | ADMSEC00 (615 LOC) manages user authentication with PASSWORD_HASH, failed attempt tracking, and account locking. SYSTEM_USER table stores user types (Admin, Manager, Salesperson, F&I, Clerk) with dealer-code-level authorization. IMS DC provides transaction-level security (RACF/ACF2). The current system has 5 user types with implicit authorization rules embedded in each program's logic. |
| **Impact** | Improper security migration could expose sensitive data (PII, financial records). Missing authorization checks could allow unauthorized deal approvals or price changes. |
| **Mitigation** | 1) Implement Spring Security with JWT tokens. 2) Map 5 COBOL user types to Spring Security roles with `@PreAuthorize` annotations. 3) Extract implicit authorization rules from each program and implement as method-level security. 4) Replace PASSWORD_HASH with BCrypt. 5) Add dealer-code tenant isolation at the JPA repository level. 6) Implement OWASP security testing. |
| **Owner** | Security Lead / Admin Module Lead |

### R-010: Data Volume and Performance

| Field | Value |
|-------|-------|
| **Risk ID** | R-010 |
| **Category** | Technical |
| **Severity** | Medium |
| **Likelihood** | Medium |
| **Description** | The system manages potentially millions of records across 53 tables. VEHICLE table is the most accessed (10+ modules). AUDIT_LOG grows continuously (every operation logs). Batch jobs process large volumes. Report queries join multiple large tables (RPTSUP00 at 1,154 LOC joins 15+ tables). Mainframe DB2 has specific optimizer behavior and index strategies. |
| **Impact** | Performance degradation in PostgreSQL if indexes are not tuned. Slow reports. Batch processing exceeding time windows. User experience degradation on high-volume queries. |
| **Mitigation** | 1) Profile top 20 SQL queries from mainframe (explain plans) and create equivalent PostgreSQL indexes. 2) Implement connection pooling (HikariCP). 3) Add pagination to all list queries (CUSLST00, VEHLST00, etc. currently fetch unbounded result sets). 4) Implement read replicas for reporting queries. 5) Archive audit log older than 2 years to cold storage. 6) Load test with 2x expected production volume. |
| **Owner** | Database Architect / Performance Lead |

### R-011: IMS DC Transaction Semantics vs REST API

| Field | Value |
|-------|-------|
| **Risk ID** | R-011 |
| **Category** | Technical |
| **Severity** | Medium |
| **Likelihood** | High |
| **Description** | IMS DC provides conversational and non-conversational transaction processing with automatic rollback on failure (ROLL call in COMDBEL0). Each IMS transaction is a single GU-process-ISRT cycle with ACID guarantees managed by IMS. COMDBEL0 (550 LOC) issues IMS ROLL to back out DB2 and DL/I changes atomically. REST APIs have different transaction boundaries (per-request). |
| **Impact** | Lost atomicity in multi-step operations. Partial updates without proper transaction management. Race conditions in concurrent deal updates that IMS serialization prevented. |
| **Mitigation** | 1) Use Spring `@Transactional` with appropriate isolation levels. 2) Map IMS ROLL behavior to Spring transaction rollback rules. 3) Implement optimistic locking (`@Version`) on frequently updated entities (SALES_DEAL, VEHICLE, STOCK_POSITION). 4) For multi-step workflows (deal completion), use saga pattern or compensating transactions. 5) Add idempotency keys to prevent duplicate submissions. |
| **Owner** | Architecture Lead |

### R-012: MFS (Message Format Service) Screen Migration

| Field | Value |
|-------|-------|
| **Risk ID** | R-012 |
| **Category** | Technical |
| **Severity** | Medium |
| **Likelihood** | Low |
| **Description** | The system has MFS definitions (message format services) that define IMS DC terminal screen layouts (3270 format). These define field positions, attributes (protected, numeric, bright), and message output formats. Each online program reads/writes fixed-format messages via IO PCB. The React UI is a complete replacement, not a migration. |
| **Impact** | Screen layout expectations from users. Workflow muscle memory disruption. Field validation rules embedded in MFS definitions may be lost. |
| **Mitigation** | 1) Extract field validation rules from MFS definitions and COBOL programs into a validation specification document. 2) Design React forms to match logical workflow, not physical screen layout. 3) Conduct user acceptance testing with actual dealership users. 4) Provide training materials showing old-to-new workflow mapping. 5) Consider a "classic view" option for power users during transition. |
| **Owner** | UX Lead / Frontend Lead |

### R-013: Data Migration Completeness and Integrity

| Field | Value |
|-------|-------|
| **Risk ID** | R-013 |
| **Category** | Data |
| **Severity** | Critical |
| **Likelihood** | Medium |
| **Description** | Migration of 53 DB2 tables plus IMS hierarchical data to PostgreSQL. Column-level data type mapping (CHAR vs VARCHAR, TIMESTAMP precision, DECIMAL scale). Character encoding (EBCDIC to UTF-8). Date formats. NULL handling differences between DB2 and PostgreSQL. Foreign key relationships must be preserved. Historical data (archived deals, expired incentives) volume. |
| **Impact** | Data loss or corruption. Broken referential integrity. Character encoding issues in customer names/addresses. Date calculation errors from format mismatches. |
| **Mitigation** | 1) Create column-by-column mapping document for all 53 tables. 2) Automated migration with row counts, checksums, and sample verification. 3) EBCDIC-to-UTF-8 conversion testing with international characters. 4) Dry-run migration on production data copy. 5) Build data validation reports comparing source and target. 6) Define cutover window and rollback procedure. |
| **Owner** | Data Migration Lead |

### R-014: Parallel Run and Cutover Risk

| Field | Value |
|-------|-------|
| **Risk ID** | R-014 |
| **Category** | Business |
| **Severity** | High |
| **Likelihood** | Medium |
| **Description** | During parallel run, both mainframe and modern system must produce identical results. Maintaining two systems doubles operational overhead. Data synchronization between systems during parallel run. Determining "go/no-go" criteria for cutover. Rollback plan if modern system fails post-cutover. |
| **Impact** | Extended parallel run costs ($$$). User confusion. Data divergence between systems. Delayed cutover erodes stakeholder confidence. |
| **Mitigation** | 1) Define clear go/no-go metrics (transaction accuracy rate > 99.99%, response time < 2s, zero financial discrepancies). 2) Implement automated comparison tooling (run same transaction on both systems, compare output). 3) Wave-based cutover reduces blast radius. 4) Maintain mainframe "warm standby" for 30 days post-cutover per wave. 5) Assign a dedicated parallel-run coordinator. |
| **Owner** | Project Manager / QA Lead |

### R-015: Organizational Change and User Adoption

| Field | Value |
|-------|-------|
| **Risk ID** | R-015 |
| **Category** | Business |
| **Severity** | Medium |
| **Likelihood** | High |
| **Description** | Dealership staff have used 3270 terminal screens for years. New React UI changes every workflow. F&I managers depend on exact calculation behaviors. Service advisors use warranty/recall screens daily. Power users have memorized transaction codes (e.g., SQOT for sales quote, VRCV for vehicle receive). |
| **Impact** | Productivity drop during transition. User resistance. Increased support calls. Workaround behaviors that bypass new system controls. |
| **Mitigation** | 1) Involve dealership power users in UAT from Wave 1. 2) Provide role-specific training (sales, F&I, service, admin). 3) Build keyboard shortcuts that map to old transaction codes. 4) Deploy to pilot dealer before fleet-wide rollout per wave. 5) Establish super-user network at each dealership for peer support. |
| **Owner** | Change Management Lead / Training Lead |

### R-016: COBOL Working Storage and State Management

| Field | Value |
|-------|-------|
| **Risk ID** | R-016 |
| **Category** | Technical |
| **Severity** | Medium |
| **Likelihood** | Medium |
| **Description** | COBOL programs maintain state in WORKING-STORAGE SECTION with complex level-88 condition names, REDEFINES, and OCCURS DEPENDING ON. Some programs use scratch pad areas (SPA) for conversational IMS transactions. Working storage is initialized per transaction invocation in IMS DC. Java object lifecycle and state management differs fundamentally. |
| **Impact** | State leaks between requests if not properly managed. Incorrect initialization leading to stale data. REDEFINES-based data reinterpretation lost in translation. |
| **Mitigation** | 1) Use request-scoped Spring beans for per-transaction state (equivalent to COBOL WS initialization). 2) Map level-88 conditions to Java enums or boolean methods. 3) Replace REDEFINES with explicit type conversion methods. 4) Eliminate SPA usage -- use stateless REST with client-side state or server-side session. 5) Code review every WS->Java mapping for initialization correctness. |
| **Owner** | Development Lead |

### R-017: Report Output Format Compatibility

| Field | Value |
|-------|-------|
| **Risk ID** | R-017 |
| **Category** | Business |
| **Severity** | Low |
| **Likelihood** | High |
| **Description** | 14 COBOL report programs (9,312 SLOC) generate fixed-format print output with WRITE AFTER ADVANCING, page breaks, and columnar alignment. Reports are used for GL reconciliation, management review, regulatory filing. Some reports may be fed to downstream systems that parse fixed positions. |
| **Impact** | Format changes break downstream integrations. Management expects identical report layout. Regulatory filings may require specific formats. |
| **Mitigation** | 1) Catalog all report consumers (human, system, regulatory). 2) For system consumers, provide CSV/JSON alternatives. 3) For human consumers, use PDF generation matching existing layout. 4) For regulatory, preserve exact format until requirements confirmed. 5) Implement as modern reporting service with multiple output format support. |
| **Owner** | Reports Module Lead |

---

## Risk Summary Heat Map

| Risk ID | Risk Name | Severity | Likelihood | Priority |
|---------|-----------|----------|------------|----------|
| R-001 | IMS Hierarchical Data Migration | Critical | High | **Immediate** |
| R-002 | Financial Calculation Precision | Critical | High | **Immediate** |
| R-013 | Data Migration Completeness | Critical | Medium | **High** |
| R-003 | Deal State Machine Integrity | Critical | Medium | **High** |
| R-004 | EDI Integration Replacement | High | Medium | **High** |
| R-005 | VIN Validation Accuracy | High | Medium | **High** |
| R-006 | Multi-Jurisdiction Tax | High | Medium | **High** |
| R-007 | Floor Plan Interest Precision | High | Medium | **High** |
| R-008 | Batch Checkpoint/Restart | High | Medium | **High** |
| R-014 | Parallel Run and Cutover | High | Medium | **High** |
| R-009 | Security Model Migration | High | Low | **Significant** |
| R-011 | IMS Transaction Semantics | Medium | High | **Significant** |
| R-015 | User Adoption | Medium | High | **Significant** |
| R-016 | COBOL State Management | Medium | Medium | **Moderate** |
| R-010 | Data Volume / Performance | Medium | Medium | **Moderate** |
| R-012 | MFS Screen Migration | Medium | Low | **Monitor** |
| R-017 | Report Format Compatibility | Low | High | **Monitor** |
