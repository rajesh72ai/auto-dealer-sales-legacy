import { Routes, Route, Navigate } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import NotFoundPage from './pages/NotFoundPage';
import ProtectedRoute from './auth/ProtectedRoute';
import AppLayout from './components/layout/AppLayout';

// Admin pages
import DealersPage from './pages/admin/DealersPage';
import ModelsPage from './pages/admin/ModelsPage';
import PricingPage from './pages/admin/PricingPage';
import TaxRatesPage from './pages/admin/TaxRatesPage';
import IncentivesPage from './pages/admin/IncentivesPage';
import ConfigPage from './pages/admin/ConfigPage';
import SalespersonsPage from './pages/admin/SalespersonsPage';

// Customer pages
import CustomersPage from './pages/customer/CustomersPage';
import CustomerDetailPage from './pages/customer/CustomerDetailPage';
import CreditCheckPage from './pages/customer/CreditCheckPage';
import LeadsPage from './pages/customer/LeadsPage';

// Sales pages
import DealPipelinePage from './pages/sales/DealPipelinePage';
import DealDetailPage from './pages/sales/DealDetailPage';

// Finance pages
import FinanceApplicationsPage from './pages/finance/FinanceApplicationsPage';
import LoanCalculatorPage from './pages/finance/LoanCalculatorPage';
import LeaseCalculatorPage from './pages/finance/LeaseCalculatorPage';
import FinanceProductsPage from './pages/finance/FinanceProductsPage';
import DealDocumentPage from './pages/finance/DealDocumentPage';

// Floor Plan pages
import FloorPlanPage from './pages/floorplan/FloorPlanPage';
import FloorPlanInterestPage from './pages/floorplan/FloorPlanInterestPage';
import FloorPlanReportPage from './pages/floorplan/FloorPlanReportPage';

// Vehicle & Inventory pages
import VehicleListPage from './pages/vehicle/VehicleListPage';
import VehicleDetailPage from './pages/vehicle/VehicleDetailPage';
import VehicleAgingPage from './pages/vehicle/VehicleAgingPage';
import StockDashboardPage from './pages/vehicle/StockDashboardPage';
import StockPositionsPage from './pages/vehicle/StockPositionsPage';
import StockAdjustmentsPage from './pages/vehicle/StockAdjustmentsPage';
import StockTransfersPage from './pages/vehicle/StockTransfersPage';
import StockValuationPage from './pages/vehicle/StockValuationPage';
import StockReconciliationPage from './pages/vehicle/StockReconciliationPage';
import ProductionOrdersPage from './pages/vehicle/ProductionOrdersPage';
import ShipmentsPage from './pages/vehicle/ShipmentsPage';
import ShipmentDetailPage from './pages/vehicle/ShipmentDetailPage';
import PdiSchedulePage from './pages/vehicle/PdiSchedulePage';
import LotLocationsPage from './pages/admin/LotLocationsPage';
import UserManagementPage from './pages/admin/UserManagementPage';
import AuditLogPage from './pages/admin/AuditLogPage';
import AgentUsagePage from './pages/admin/AgentUsagePage';
import AgentTracePage from './pages/admin/AgentTracePage';
import AgentAnalyticsPage from './pages/admin/AgentAnalyticsPage';
import ApiDocsPage from './pages/admin/ApiDocsPage';
import CapabilityGapsPage from './pages/admin/CapabilityGapsPage';

// Registration & Warranty pages (Wave 6)
import RegistrationsPage from './pages/registration/RegistrationsPage';
import RegistrationDetailPage from './pages/registration/RegistrationDetailPage';
import WarrantyPage from './pages/registration/WarrantyPage';
import WarrantyClaimsPage from './pages/registration/WarrantyClaimsPage';
import WarrantyReportPage from './pages/registration/WarrantyReportPage';
import RecallCampaignsPage from './pages/registration/RecallCampaignsPage';
import RecallDetailPage from './pages/registration/RecallDetailPage';

// Batch & Integration pages (Wave 7)
import BatchJobsPage from './pages/batch/BatchJobsPage';
import BatchReportsPage from './pages/batch/BatchReportsPage';

function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />

      <Route element={<ProtectedRoute />}>
        <Route element={<AppLayout />}>
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="/dashboard" element={<DashboardPage />} />

          {/* Customer routes */}
          <Route path="/customers" element={<CustomersPage />} />
          <Route path="/customers/:id" element={<CustomerDetailPage />} />
          <Route path="/customers/:id/credit" element={<CreditCheckPage />} />
          <Route path="/leads" element={<LeadsPage />} />

          {/* Sales routes */}
          <Route path="/deals" element={<DealPipelinePage />} />
          <Route path="/deals/:dealNumber" element={<DealDetailPage />} />

          {/* Finance routes */}
          <Route path="/finance" element={<FinanceApplicationsPage />} />
          <Route path="/finance/applications" element={<FinanceApplicationsPage />} />
          <Route path="/finance/loan-calculator" element={<LoanCalculatorPage />} />
          <Route path="/finance/lease-calculator" element={<LeaseCalculatorPage />} />
          <Route path="/finance/products" element={<FinanceProductsPage />} />
          <Route path="/finance/documents" element={<DealDocumentPage />} />

          {/* Floor Plan routes */}
          <Route path="/floor-plan" element={<FloorPlanPage />} />
          <Route path="/floor-plan/interest" element={<FloorPlanInterestPage />} />
          <Route path="/floor-plan/reports" element={<FloorPlanReportPage />} />

          {/* Vehicle & Inventory routes */}
          <Route path="/vehicles" element={<VehicleListPage />} />
          <Route path="/vehicles/aging" element={<VehicleAgingPage />} />
          <Route path="/vehicles/:vin" element={<VehicleDetailPage />} />
          <Route path="/stock" element={<StockDashboardPage />} />
          <Route path="/stock/positions" element={<StockPositionsPage />} />
          <Route path="/stock/adjustments" element={<StockAdjustmentsPage />} />
          <Route path="/stock/transfers" element={<StockTransfersPage />} />
          <Route path="/stock/valuation" element={<StockValuationPage />} />
          <Route path="/stock/reconciliation" element={<StockReconciliationPage />} />
          <Route path="/production/orders" element={<ProductionOrdersPage />} />
          <Route path="/shipments" element={<ShipmentsPage />} />
          <Route path="/shipments/:id" element={<ShipmentDetailPage />} />
          <Route path="/pdi" element={<PdiSchedulePage />} />

          {/* Registration & Warranty routes */}
          <Route path="/registration" element={<RegistrationsPage />} />
          <Route path="/registration/:regId" element={<RegistrationDetailPage />} />
          <Route path="/warranty" element={<WarrantyPage />} />
          <Route path="/warranty-claims" element={<WarrantyClaimsPage />} />
          <Route path="/warranty-report" element={<WarrantyReportPage />} />
          <Route path="/recall" element={<RecallCampaignsPage />} />
          <Route path="/recall/:recallId" element={<RecallDetailPage />} />

          {/* Batch & Integration routes */}
          <Route path="/batch/jobs" element={<BatchJobsPage />} />
          <Route path="/batch/reports" element={<BatchReportsPage />} />

          {/* Admin routes */}
          <Route path="/admin/lot-locations" element={<LotLocationsPage />} />
          <Route path="/admin/dealers" element={<DealersPage />} />
          <Route path="/admin/models" element={<ModelsPage />} />
          <Route path="/admin/pricing" element={<PricingPage />} />
          <Route path="/admin/tax-rates" element={<TaxRatesPage />} />
          <Route path="/admin/incentives" element={<IncentivesPage />} />
          <Route path="/admin/config" element={<ConfigPage />} />
          <Route path="/admin/salespersons" element={<SalespersonsPage />} />
          <Route path="/admin/users" element={<UserManagementPage />} />
          <Route path="/admin/audit-log" element={<AuditLogPage />} />
          <Route path="/admin/agent-usage" element={<AgentUsagePage />} />
          <Route path="/admin/agent-trace" element={<AgentTracePage />} />
          <Route path="/admin/agent-analytics" element={<AgentAnalyticsPage />} />
          <Route path="/admin/api-docs" element={<ApiDocsPage />} />
          <Route path="/admin/capability-gaps" element={<CapabilityGapsPage />} />
        </Route>
      </Route>

      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
}

export default App;
