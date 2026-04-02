# AUTOSALES Modernization Enhancements (Beyond Mainframe Parity)

> 12 enhancements that leverage the modern platform to deliver capabilities impossible on the mainframe.
> Date: 2026-03-29

---

## Enhancement Summary Table

| # | Enhancement | Priority | Effort | Wave |
|---|------------|----------|--------|------|
| 1 | Sales Pipeline Dashboard | Must-have | Medium | 5 |
| 2 | Inventory Health Dashboard | Must-have | Medium | 3 |
| 3 | Finance Calculator Suite | Must-have | Medium | 4 |
| 4 | Floor Plan Exposure Dashboard | Must-have | Small | 3 |
| 5 | Audit Trail (AOP-based) | Must-have | Medium | 1 |
| 6 | Excel/CSV Export | Must-have | Small | 1 |
| 7 | Real-time Deal Profitability | Should-have | Large | 5 |
| 8 | VIN Instant Decode | Should-have | Small | 3 |
| 9 | On-demand Reports | Should-have | Medium | 2 |
| 10 | System Health Dashboard | Should-have | Medium | 1 |
| 11 | User Management UI | Should-have | Small | 1 |
| 12 | Paginated Searchable Lists | Must-have | Medium | 1 |

---

## 1. Sales Pipeline Dashboard

### Description
A real-time visual dashboard showing all active deals across the sales pipeline stages (Lead -> Quote -> Negotiation -> Pending Approval -> Approved -> Completed), with drill-down by salesperson, time period, and deal value. Includes conversion rate metrics, average days-in-stage, and revenue forecasting.

### Business Value / User Impact
- Sales managers currently have zero visibility into pipeline health without running batch reports (RPTDLY00, RPTWKL00) that are hours old.
- Enables proactive management: identify stalled deals, redistribute workload, forecast weekly/monthly targets.
- Reduces "surprise" deal failures by surfacing aging deals in negotiation.

### Before (Mainframe) vs After (Modern)

| Aspect | Mainframe (Before) | Modern (After) |
|--------|-------------------|----------------|
| Visibility | Run RPTDLY00 batch report next morning. Fixed-format printout. | Real-time dashboard with auto-refresh. Interactive charts. |
| Drill-down | None. Call IT for ad-hoc query. | Click pipeline stage to see deals. Click deal for full detail. |
| Forecasting | Manual spreadsheet extrapolation from monthly report. | Automated weighted pipeline forecast based on stage probability. |
| Salesperson view | Not available. Manager runs team report. | Each salesperson sees their own pipeline. Manager sees team. |

### Technical Implementation
- **Backend:** New `GET /api/sales/pipeline/summary` endpoint aggregating SALES_DEAL by status, grouped by salesperson and date range. Use PostgreSQL `GROUP BY` with `FILTER` clauses.
- **Frontend:** React dashboard using Recharts or Chart.js. Kanban-style board for deal stages. Drag-and-drop not supported (deal progression requires business logic).
- **Data:** Query SALES_DEAL, CUSTOMER, VEHICLE, SYSTEM_USER tables. No new tables needed.
- **Caching:** Redis cache with 60-second TTL for pipeline summary (avoid repeated aggregation queries).

### Priority: Must-have
### Estimated Effort: 3-4 weeks (backend API + frontend dashboard + caching)

---

## 2. Inventory Health Dashboard

### Description
Visual dashboard showing inventory composition, aging distribution (0-30, 31-60, 61-90, 90+ days), total floor plan exposure, turn rate by model, and alerts for slow-moving stock. Replaces multiple COBOL programs (STKAGIN0, STKSUM00, STKVALS0, STKALRT0) with a single interactive view.

### Business Value / User Impact
- Aging inventory is the #1 cost driver for dealers (floor plan interest accrues daily on every vehicle).
- Currently requires running 4 separate transactions (SKAG, SKSM, SKVL, SKAL) to get a fragmented picture.
- Single-screen view enables faster purchasing decisions and targeted discounting of aged units.

### Before (Mainframe) vs After (Modern)

| Aspect | Mainframe (Before) | Modern (After) |
|--------|-------------------|----------------|
| Aging view | STKAGIN0: scrollable list, one dealer at a time. | Heat map by model/age bucket. Color-coded (green/yellow/red). |
| Valuation | STKVALS0: total inventory value, separate screen. | Integrated value display with cost-of-carry calculation. |
| Alerts | STKALRT0: list of over-aged vehicles. | Push notifications + dashboard badges. Configurable thresholds. |
| Trend | Not available. | 30/60/90-day trend lines for turn rate and average age. |

### Technical Implementation
- **Backend:** `GET /api/stock/health` endpoint joining VEHICLE, STOCK_POSITION, FLOOR_PLAN_VEHICLE tables with aging calculation (PostgreSQL `CURRENT_DATE - receive_date`).
- **Frontend:** Dashboard with donut chart (new/used/certified split), stacked bar (aging buckets by model), and KPI cards (total units, average age, total exposure, turn rate).
- **Alerts:** Spring `@Scheduled` job runs daily, compares against configurable thresholds, pushes WebSocket notifications to connected clients.

### Priority: Must-have
### Estimated Effort: 3-4 weeks

---

## 3. Finance Calculator Suite

### Description
Interactive loan and lease calculators accessible to F&I managers and customers. Input vehicle price, down payment, trade-in value, interest rate, and term; instantly see monthly payment, total interest, amortization schedule, and lease residual. Replaces the call-and-wait pattern of FINCAL00 -> COMLONL0 / COMLESL0.

### Business Value / User Impact
- F&I managers currently enter data into a 3270 screen, submit, wait for response, then re-enter to try different scenarios. Each scenario is a separate IMS transaction.
- Modern calculator enables instant "what-if" scenarios: change term from 60 to 72 months, see payment change immediately.
- Customer-facing potential: embed calculator in dealership website for lead generation.

### Before (Mainframe) vs After (Modern)

| Aspect | Mainframe (Before) | Modern (After) |
|--------|-------------------|----------------|
| Scenario comparison | One scenario per transaction. Manual recording. | Side-by-side comparison of up to 4 scenarios simultaneously. |
| Amortization schedule | Not available online. Must run FINDOC00. | Instant expandable amortization table with each calculation. |
| Lease vs Buy | Two separate screens (FINCAL00, FINLSE00). | Single calculator with toggle between loan and lease. |
| Response time | 2-3 seconds per IMS transaction round-trip. | <100ms client-side calculation (no server round-trip for basic calcs). |

### Technical Implementation
- **Backend:** `POST /api/finance/calculate` endpoint wrapping COMLONL0 and COMLESL0 logic in Java services. Returns payment, total interest, amortization array.
- **Frontend:** React calculator component with sliders for term/rate/down-payment. Instant recalculation on input change (debounced). Chart.js for payment breakdown (principal vs interest over time).
- **Client-side option:** Standard amortization formula can run in JavaScript for instant feedback; server validates before deal submission.
- **PDF export:** Generate amortization schedule as PDF for customer handoff.

### Priority: Must-have
### Estimated Effort: 3-4 weeks

---

## 4. Floor Plan Exposure Dashboard

### Description
Real-time view of total floor plan exposure (principal outstanding), daily interest accrual, payment due dates, and lender-level breakdown. Visual timeline showing when curtailment payments are due. Aging-based interest rate tier visualization.

### Business Value / User Impact
- Floor plan interest is typically the largest single expense for a dealership after payroll.
- Currently, managers must run FPLINQ00, FPLRPT00, and FPLINT00 transactions separately, then manually sum exposure.
- A single dashboard with projected 30-day interest cost enables better cash flow management.

### Before (Mainframe) vs After (Modern)

| Aspect | Mainframe (Before) | Modern (After) |
|--------|-------------------|----------------|
| Total exposure | FPLINQ00: per-vehicle inquiry only. | Single number at top of dashboard with lender breakdown. |
| Interest projection | FPLRPT00: historical report only. | Forward-looking 30/60/90-day interest projection. |
| Payment schedule | Manual tracking in spreadsheet. | Calendar view with payment due dates and amounts. |
| Cost analysis | Not available. | Cost-per-vehicle-per-day visualization. Identifies highest-cost units. |

### Technical Implementation
- **Backend:** `GET /api/floorplan/exposure` aggregating FLOOR_PLAN_VEHICLE, FLOOR_PLAN_INTEREST, FLOOR_PLAN_LENDER. COMINTL0 logic (interest calculation) as a shared service used by both the dashboard and the payment processing.
- **Frontend:** KPI cards (total exposure, daily accrual, MTD interest, projected monthly). Lender-level donut chart. Sortable vehicle list by daily cost. Calendar component for payment schedule.

### Priority: Must-have
### Estimated Effort: 2-3 weeks

---

## 5. Audit Trail (AOP-based)

### Description
Replace the manual COMLGEL0 audit logging (called explicitly in 35+ programs) with an AOP (Aspect-Oriented Programming) audit system that automatically captures who changed what, when, and the before/after values. Covers all entity mutations across all modules without requiring explicit logging code.

### Business Value / User Impact
- Currently, audit logging depends on each program explicitly calling COMLGEL0. If a developer forgets, the change is unaudited.
- AOP guarantees 100% audit coverage for all data mutations.
- Before/after value capture enables "undo" reasoning and compliance auditing.
- Searchable audit trail replaces the flat AUDIT_LOG table queries.

### Before (Mainframe) vs After (Modern)

| Aspect | Mainframe (Before) | Modern (After) |
|--------|-------------------|----------------|
| Coverage | Manual: COMLGEL0 called in 35+ programs. Gaps possible. | Automatic: AOP intercepts all `@Service` mutations. 100% coverage. |
| Detail | User ID, timestamp, module ID, free-text description. | User, timestamp, entity, field, old value, new value, IP address, session ID. |
| Searchability | Direct SQL against AUDIT_LOG. No indexing on content. | Full-text search. Filter by entity, user, date range, field. |
| Retention | All in one table, no archiving. | Tiered: hot (90 days in PostgreSQL), warm (2 years in S3/cold storage). |

### Technical Implementation
- **Backend:** Spring AOP `@Around` advice on all `@Service` methods annotated with `@Audited`. Use Hibernate Envers or custom interceptor for entity-level change detection. `AuditEvent` published to async queue (Spring ApplicationEvent or Kafka).
- **Storage:** `audit_event` table with JSONB column for changed fields (PostgreSQL JSONB enables querying within the change payload).
- **Frontend:** Audit log viewer with filters. Timeline view per entity. "Show changes" diff view.

### Priority: Must-have
### Estimated Effort: 3-4 weeks (AOP infrastructure + viewer UI)

---

## 6. Excel/CSV Export

### Description
One-click export of any list view or report to Excel (.xlsx) or CSV format. Covers customer lists, vehicle inventory, deal reports, stock positions, floor plan exposure, and all existing COBOL report equivalents.

### Business Value / User Impact
- Mainframe reports produce fixed-format printouts that cannot be imported into Excel without manual reformatting.
- Dealership staff routinely retype report data into Excel for further analysis.
- Export capability eliminates hours of manual data entry and reduces transcription errors.

### Before (Mainframe) vs After (Modern)

| Aspect | Mainframe (Before) | Modern (After) |
|--------|-------------------|----------------|
| Format | Fixed-width print output (132-column). | .xlsx with headers, formatting, formulas. Or .csv for data import. |
| Delivery | Print queue -> physical printer or PDF. | Browser download. Email attachment option. Scheduled delivery. |
| Customization | Fixed layout, cannot change columns. | Column selection, sort order, filter criteria before export. |
| Volume | Full report only. | Export current view (with filters applied) or full dataset. |

### Technical Implementation
- **Backend:** Apache POI for .xlsx generation. Shared `ExportService` that accepts any `Page<T>` result and column mapping. `GET /api/export/{entity}?format=xlsx&filters=...`.
- **Frontend:** "Export" button on every list/table component. Format selector (Excel/CSV). Download via browser `Blob` API.
- **Async for large exports:** Queue large exports (>10K rows) as background jobs with notification when ready.

### Priority: Must-have
### Estimated Effort: 2 weeks (reusable infrastructure + integration with 5-6 list views)

---

## 7. Real-time Deal Profitability

### Description
Live profitability calculation during deal negotiation showing gross profit, holdback, F&I income, trade-in margin, incentive cost, and total dealer profit -- updating as the salesperson adjusts pricing. Includes comparison to dealership targets and historical averages.

### Business Value / User Impact
- Currently, profitability is only known after deal completion when RPTPRF00 batch report runs.
- Managers approve/reject deals without seeing full profit picture (SALAPV00 shows deal amount but not decomposed profitability).
- Real-time profitability prevents "losing" deals from being approved and enables optimized negotiation.

### Before (Mainframe) vs After (Modern)

| Aspect | Mainframe (Before) | Modern (After) |
|--------|-------------------|----------------|
| Visibility | Post-deal only (RPTPRF00 report). | Live during negotiation. Updates on every price/trade-in change. |
| Decomposition | Total gross only. | Front-end gross + back-end gross + holdback + F&I reserve + trade-in spread. |
| Target comparison | Monthly spreadsheet from GM. | Green/yellow/red indicator vs. deal target. |
| Historical context | Not available during deal. | "Similar deals averaged $X profit" benchmark. |

### Technical Implementation
- **Backend:** `POST /api/sales/profitability` taking deal parameters, calling COMPRCL0 (pricing) service for invoice/holdback, computing: `Front Gross = Sale Price - Invoice + Holdback`, `Back Gross = F&I Products + Finance Reserve`, `Trade Spread = ACV - Trade Allowance`, `Total = Front + Back + Trade - Incentive Cost`.
- **Frontend:** Profitability panel embedded in deal negotiation screen. Waterfall chart showing profit components. Color-coded against configurable minimum thresholds.
- **WebSocket:** Optional real-time push when manager is watching a deal being negotiated.

### Priority: Should-have
### Estimated Effort: 4-5 weeks (requires COMPRCL0 service + new profitability logic + UI)

---

## 8. VIN Instant Decode

### Description
Replace the batch-oriented COMVINL0 (822 LOC of embedded VIN decode tables) with real-time NHTSA vPIC API integration. Entering a VIN instantly returns year, make, model, trim, engine, transmission, body style, plant of manufacture, and safety recall status.

### Business Value / User Impact
- COMVINL0 contains hardcoded VIN decode tables that must be manually updated when new models are released.
- NHTSA API provides authoritative, always-current decode data for all manufacturers.
- Adding recall status check at VIN entry catches safety issues immediately rather than waiting for batch recall feed (WRCRCLB0).

### Before (Mainframe) vs After (Modern)

| Aspect | Mainframe (Before) | Modern (After) |
|--------|-------------------|----------------|
| Data source | Embedded tables in COMVINL0 WORKING-STORAGE. Updated manually. | NHTSA vPIC API. Always current. Covers all OEMs. |
| Recall check | Not part of VIN decode. Separate WRCINQ00 transaction. | Automatic recall check included in decode response. |
| Response time | <1 second (local lookup). | <500ms (API call with caching). |
| Coverage | Limited to models in the decode table. | All vehicles registered in the US since 1981. |

### Technical Implementation
- **Backend:** `VinDecodeService` calling NHTSA vPIC API (`https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVin/{vin}`). Cache decoded results in Redis (VINs don't change). Fallback to local decode tables if API is unavailable.
- **Recall check:** NHTSA Recalls API (`/api/Recalls/vehicle/modelyear/{year}/make/{make}/model/{model}`).
- **Frontend:** Auto-decode on VIN field blur. Populate vehicle details form fields automatically. Show recall badge if active recalls found.

### Priority: Should-have
### Estimated Effort: 1-2 weeks

---

## 9. On-demand Reports

### Description
Replace the 14 batch COBOL report programs with on-demand, parameterized report generation. Users select report type, date range, dealer, and other filters, then generate PDF/Excel output immediately rather than waiting for overnight batch.

### Business Value / User Impact
- Currently, reports run as overnight batch jobs (RPTDLY00, RPTWKL00, RPTMTH00, etc.). Data is always at least one day old.
- Managers needing a mid-day sales update must call IT for an ad-hoc query.
- On-demand reports with real-time data enable faster decision-making.

### Before (Mainframe) vs After (Modern)

| Aspect | Mainframe (Before) | Modern (After) |
|--------|-------------------|----------------|
| Availability | Overnight batch. Output next morning. | On-demand. Any time. |
| Parameters | Fixed (report for current period only). | User-selectable date range, dealer, salesperson, model, status. |
| Format | Fixed-width print (132 columns). | PDF (formatted), Excel (data), or on-screen interactive table. |
| Distribution | Print queue. | Email, download, scheduled delivery, shared link. |

### Technical Implementation
- **Backend:** JasperReports or Apache POI for report generation. Report definitions as JRXML templates matching existing layouts. `POST /api/reports/generate` with report type and parameters.
- **Async generation:** Large reports queued as Spring Batch jobs. WebSocket notification when complete.
- **Scheduling:** Users can schedule recurring report delivery (e.g., "email me the daily sales summary at 7 AM").
- **Caching:** Cache report output for frequently-requested parameter combinations.

### Priority: Should-have
### Estimated Effort: 4-5 weeks (template creation for 14 reports + generation infrastructure)

---

## 10. System Health Dashboard

### Description
Operational monitoring dashboard showing application health, database connection pool status, active users, transaction throughput, error rates, batch job status, and integration endpoint health (EDI/API). Replaces the "check the console log" approach of the mainframe.

### Business Value / User Impact
- Mainframe monitoring requires SDSF access and system programmer skills.
- Modern dashboard enables IT support staff and managers to see system status without specialized knowledge.
- Proactive alerting prevents issues from becoming outages.

### Before (Mainframe) vs After (Modern)

| Aspect | Mainframe (Before) | Modern (After) |
|--------|-------------------|----------------|
| Health check | SDSF job status. Manual console check. | /actuator/health endpoint + visual dashboard. |
| Performance | SMF records analyzed by systems programmer. | Real-time Grafana/custom dashboard with response time percentiles. |
| Errors | JES2 spool review. | Structured logging with error aggregation and alerting. |
| Batch status | JCL job status in JES. | Spring Batch admin console with execution history, duration, status. |

### Technical Implementation
- **Backend:** Spring Boot Actuator endpoints (health, metrics, info). Micrometer for metrics collection. Custom health indicators for PostgreSQL, Redis, external APIs.
- **Frontend:** React dashboard with WebSocket for real-time updates. Cards for each service component. Traffic light status indicators. Error log tail view.
- **Alerting:** Integration with PagerDuty/Slack/email for threshold breaches (error rate > 1%, response time > 5s, batch job failure).
- **Batch monitoring:** Spring Batch admin UI showing job execution history, step details, and restart capability.

### Priority: Should-have
### Estimated Effort: 3-4 weeks

---

## 11. User Management UI

### Description
Self-service user administration interface replacing the ADMSEC00 terminal-based user management. Includes user creation, role assignment, password reset, dealer assignment, activity log, and session management. Adds capabilities impossible on the mainframe: SSO integration, MFA, and fine-grained permissions.

### Business Value / User Impact
- Currently, user management requires a system administrator to access ADMSEC00 on a 3270 terminal.
- No self-service password reset (users call IT).
- No visibility into user activity or concurrent sessions.
- Modern UI enables delegated admin (dealer principal manages their own users).

### Before (Mainframe) vs After (Modern)

| Aspect | Mainframe (Before) | Modern (After) |
|--------|-------------------|----------------|
| User creation | ADMSEC00 screen. Admin only. | Web form. Delegated to dealer principal. |
| Password reset | Call IT -> admin runs ADMSEC00. | Self-service with email verification. |
| Role management | 5 fixed types (A/M/S/F/C) in SYSTEM_USER. | Flexible role/permission matrix. Custom roles. |
| Authentication | Password hash in DB. | Spring Security + BCrypt. Optional SSO (SAML/OIDC). Optional MFA (TOTP). |
| Session visibility | None. | Active session list. Force logout capability. |

### Technical Implementation
- **Backend:** Spring Security with `UserDetailsService` backed by PostgreSQL. `@PreAuthorize` for role-based access. JWT token management with refresh tokens. BCrypt password encoding.
- **Frontend:** User list with search/filter. User detail form with role checkboxes. Activity log tab. Session management tab.
- **SSO ready:** Spring Security SAML or OIDC auto-configuration for enterprise SSO integration.
- **MFA ready:** TOTP (Google Authenticator compatible) as optional second factor.

### Priority: Should-have
### Estimated Effort: 2-3 weeks

---

## 12. Paginated Searchable Lists

### Description
Replace the COBOL list screens (CUSLST00, VEHLST00, and others) that return limited fixed-size result sets with modern paginated, sortable, filterable, and searchable list views. Server-side pagination handles large datasets efficiently.

### Business Value / User Impact
- COBOL list programs (e.g., CUSLST00 at 520 LOC) return a fixed number of rows per screen. Scrolling requires multiple IMS transactions. No search beyond the primary key or a few hardcoded filters.
- Modern lists with type-ahead search, column sorting, and multi-criteria filtering dramatically reduce time-to-find.
- Dealers with 500+ vehicles or 10,000+ customers currently cannot efficiently browse their data.

### Before (Mainframe) vs After (Modern)

| Aspect | Mainframe (Before) | Modern (After) |
|--------|-------------------|----------------|
| Results per page | ~15 rows (3270 screen limit). | Configurable (25/50/100). Infinite scroll option. |
| Search | Key-based lookup only (e.g., customer by last name starts-with). | Full-text search across multiple fields. Type-ahead suggestions. |
| Sorting | Fixed sort order (primary key). | Click any column header to sort asc/desc. |
| Filtering | None or single field. | Multi-criteria: status, date range, model, salesperson, etc. |
| Navigation | PF7/PF8 scroll. New IMS transaction per page. | Client-side pagination with prefetch. URL-based deep linking. |
| Export | Not available. | Export filtered results to Excel/CSV (see Enhancement #6). |

### Technical Implementation
- **Backend:** Spring Data JPA `Pageable` parameter on all list endpoints. `Specification<T>` pattern for dynamic filtering. `@Query` with `LIKE` and `ILIKE` for search. PostgreSQL `GIN` indexes for full-text search on key fields (customer name, VIN, stock number).
- **Frontend:** Reusable `DataTable` React component with: sortable column headers, filter row, search input with debounce, pagination controls, row click for detail navigation. Built on TanStack Table (React Table v8) or AG Grid community.
- **Performance:** Keyset pagination (`WHERE id > :lastId LIMIT :size`) for large tables instead of `OFFSET`. Estimated row count via `pg_stat` for total display.

### Priority: Must-have
### Estimated Effort: 3-4 weeks (reusable component + integration with 8-10 list views)

---

## Effort Summary

| Priority | Enhancements | Total Effort |
|----------|-------------|-------------|
| **Must-have** (6) | Sales Pipeline Dashboard, Inventory Health Dashboard, Finance Calculator Suite, Floor Plan Exposure Dashboard, Audit Trail (AOP), Excel/CSV Export, Paginated Lists | 19-25 weeks |
| **Should-have** (6) | Real-time Deal Profitability, VIN Instant Decode, On-demand Reports, System Health Dashboard, User Management UI | 14.5-19.5 weeks |
| **Total** | 12 enhancements | 33.5-44.5 weeks |

Note: Many enhancements can be developed in parallel across team members and delivered incrementally within their respective modernization waves. The effort estimates assume a single developer; actual calendar time depends on team size and parallelization.
