import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  DollarSign,
  Car,
  BarChart3,
  Building2,
  UserPlus,
  Search,
  ShoppingCart,
  Clock,
  ArrowRight,
  Server,
  Loader2,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  Calculator,
  Layers,
  Briefcase,
  ShieldAlert,
} from 'lucide-react';
import { useAuth } from '@/auth/useAuth';
import { getBatchJobs } from '@/api/batch';
import { getStockSummary } from '@/api/stock';
import { getDeals } from '@/api/deals';
import { listFloorPlanVehicles } from '@/api/floorplan';
import { searchAuditLog } from '@/api/auditLog';
import type { AuditLogEntry } from '@/api/auditLog';
import type { BatchJob } from '@/types/batch';
import type { StockSummary } from '@/types/vehicle';

// ─── Formatters ────────────────────────────────────────────────────

function fmtCurrency(val: number): string {
  if (val >= 1_000_000) {
    return `$${(val / 1_000_000).toFixed(1)}M`;
  }
  return `$${val.toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`;
}

function fmtNumber(val: number): string {
  return val.toLocaleString('en-US');
}

function fmtTimestamp(ts: string): string {
  const d = new Date(ts);
  const now = new Date();
  const diffMs = now.getTime() - d.getTime();
  const diffMin = Math.floor(diffMs / 60_000);
  if (diffMin < 1) return 'Just now';
  if (diffMin < 60) return `${diffMin}m ago`;
  const diffHrs = Math.floor(diffMin / 60);
  if (diffHrs < 24) return `${diffHrs}h ago`;
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

// ─── KPI Card ──────────────────────────────────────────────────────

interface KpiCardProps {
  title: string;
  value: string;
  subtitle: string;
  icon: React.ReactNode;
  iconBg: string;
  loading?: boolean;
}

function KpiCard({ title, value, subtitle, icon, iconBg, loading }: KpiCardProps) {
  return (
    <div className="rounded-xl border border-gray-100 bg-white p-6 shadow-card transition-shadow hover:shadow-card-hover">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm font-medium text-gray-500">{title}</p>
          {loading ? (
            <div className="mt-2 flex items-center gap-2">
              <Loader2 className="h-5 w-5 animate-spin text-gray-400" />
              <span className="text-sm text-gray-400">Loading...</span>
            </div>
          ) : (
            <>
              <p className="mt-2 text-2xl font-bold text-gray-900">{value}</p>
              <p className="mt-1 text-xs text-gray-400">{subtitle}</p>
            </>
          )}
        </div>
        <div className={`flex h-11 w-11 items-center justify-center rounded-xl ${iconBg}`}>
          {icon}
        </div>
      </div>
    </div>
  );
}

// ─── Quick Action Card ─────────────────────────────────────────────

interface QuickActionProps {
  label: string;
  description: string;
  icon: React.ReactNode;
  iconBg: string;
  onClick: () => void;
}

function QuickAction({ label, description, icon, iconBg, onClick }: QuickActionProps) {
  return (
    <button
      onClick={onClick}
      className="group flex w-full items-center gap-4 rounded-xl border border-gray-100 bg-white p-4 text-left shadow-card transition-all hover:border-brand-200 hover:shadow-card-hover"
    >
      <div className={`flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-lg ${iconBg}`}>
        {icon}
      </div>
      <div className="min-w-0 flex-1">
        <p className="text-sm font-semibold text-gray-900">{label}</p>
        <p className="text-xs text-gray-500">{description}</p>
      </div>
      <ArrowRight className="h-4 w-4 flex-shrink-0 text-gray-300 transition-colors group-hover:text-brand-500" />
    </button>
  );
}

// ─── Audit Action Badge ────────────────────────────────────────────

const ACTION_BADGES: Record<string, { bg: string; text: string }> = {
  INS: { bg: 'bg-emerald-50', text: 'text-emerald-700' },
  UPD: { bg: 'bg-blue-50', text: 'text-blue-700' },
  DEL: { bg: 'bg-red-50', text: 'text-red-700' },
  APV: { bg: 'bg-amber-50', text: 'text-amber-700' },
};

function ActionBadge({ action }: { action: string }) {
  const style = ACTION_BADGES[action] ?? { bg: 'bg-gray-50', text: 'text-gray-700' };
  return (
    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide ${style.bg} ${style.text}`}>
      {action}
    </span>
  );
}

// ─── System Health helpers ─────────────────────────────────────────

function getJobHealthStatus(job: BatchJob): 'OK' | 'WARN' | 'CRIT' {
  if (!job.lastRunDate) return 'CRIT';
  const lastRun = new Date(job.lastRunDate);
  const now = new Date();
  const diffMs = now.getTime() - lastRun.getTime();
  const diffDays = diffMs / (1000 * 60 * 60 * 24);
  if (diffDays <= 1) return 'OK';
  if (diffDays <= 7) return 'WARN';
  return 'CRIT';
}

const HEALTH_BADGE: Record<string, { bg: string; text: string; icon: typeof CheckCircle2 }> = {
  OK: { bg: 'bg-green-50', text: 'text-green-700', icon: CheckCircle2 },
  WARN: { bg: 'bg-amber-50', text: 'text-amber-700', icon: AlertTriangle },
  CRIT: { bg: 'bg-red-50', text: 'text-red-700', icon: XCircle },
};

// ─── Dashboard Page ────────────────────────────────────────────────

function DashboardPage() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const dealerCode = user?.dealerCode ?? '';

  // KPI state
  const [kpiLoading, setKpiLoading] = useState(true);
  const [unitsSoldMtd, setUnitsSoldMtd] = useState(0);
  const [totalGrossProfit, setTotalGrossProfit] = useState(0);
  const [currentInventory, setCurrentInventory] = useState(0);
  const [floorPlanCount, setFloorPlanCount] = useState(0);

  // Audit log state
  const [auditEntries, setAuditEntries] = useState<AuditLogEntry[]>([]);
  const [auditLoading, setAuditLoading] = useState(true);
  const [auditError, setAuditError] = useState<string | null>(null);

  // Batch jobs state (System Health)
  const [batchJobs, setBatchJobs] = useState<BatchJob[]>([]);
  const [batchLoading, setBatchLoading] = useState(true);

  // ── Fetch KPIs ───────────────────────────────
  useEffect(() => {
    if (!dealerCode) return;

    async function fetchKpis() {
      setKpiLoading(true);
      try {
        const [stockSummary, dealsResp, fpResp] = await Promise.allSettled([
          getStockSummary(dealerCode),
          getDeals({ dealerCode, status: 'DL', page: 0, size: 100 }),
          listFloorPlanVehicles({ dealerCode, status: 'AC', page: 0, size: 1 }),
        ]);

        if (stockSummary.status === 'fulfilled') {
          const s = stockSummary.value as StockSummary;
          setUnitsSoldMtd(s.totalSoldMtd ?? 0);
          setCurrentInventory(s.totalOnHand ?? 0);
        }

        if (dealsResp.status === 'fulfilled') {
          const deals = dealsResp.value;
          const gross = (deals.content ?? []).reduce(
            (sum: number, d: { totalGross?: number }) => sum + (d.totalGross ?? 0),
            0,
          );
          setTotalGrossProfit(gross);
        }

        if (fpResp.status === 'fulfilled') {
          setFloorPlanCount(fpResp.value.totalElements ?? 0);
        }
      } catch {
        // partial failures handled via allSettled above
      } finally {
        setKpiLoading(false);
      }
    }

    fetchKpis();
  }, [dealerCode]);

  // ── Fetch Audit Log ──────────────────────────
  useEffect(() => {
    async function fetchAudit() {
      setAuditLoading(true);
      setAuditError(null);
      try {
        const resp = await searchAuditLog({ page: 0, size: 8 });
        setAuditEntries(resp.content ?? []);
      } catch (err: unknown) {
        const status = (err as { response?: { status?: number } })?.response?.status;
        if (status === 403) {
          setAuditError('Recent activity requires admin access');
        } else {
          setAuditError('Unable to load recent activity');
        }
      } finally {
        setAuditLoading(false);
      }
    }

    fetchAudit();
  }, []);

  // ── Fetch Batch Jobs (System Health) ─────────
  const fetchBatchJobs = useCallback(async () => {
    setBatchLoading(true);
    try {
      const jobs = await getBatchJobs();
      setBatchJobs(jobs);
    } catch {
      // silently fail — dashboard is not blocked by batch status
    } finally {
      setBatchLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchBatchJobs();
  }, [fetchBatchJobs]);

  const healthyCount = batchJobs.filter((j) => getJobHealthStatus(j) === 'OK').length;
  const lastDailyRun = batchJobs.find((j) => j.programId === 'BATEOD00')?.lastRunDate;

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Welcome banner */}
      <div className="rounded-xl bg-gradient-to-r from-brand-600 to-brand-700 p-6 text-white shadow-lg shadow-brand-600/20">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">
              Welcome back, {user?.userName ?? 'User'}
            </h1>
            <p className="mt-1 text-sm text-blue-100">
              Dealer: {user?.dealerCode ?? '---'} &middot; Here is your dealership overview for today.
            </p>
          </div>
          <div className="hidden rounded-lg bg-white/10 px-4 py-2 text-sm font-medium text-white backdrop-blur-sm md:block">
            {new Date().toLocaleDateString('en-US', {
              weekday: 'long',
              year: 'numeric',
              month: 'long',
              day: 'numeric',
            })}
          </div>
        </div>
      </div>

      {/* ── Row 1: KPI Cards ──────────────────────── */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KpiCard
          title="Units Sold MTD"
          value={fmtNumber(unitsSoldMtd)}
          subtitle="MTD"
          icon={<BarChart3 className="h-5 w-5 text-blue-600" />}
          iconBg="bg-blue-50"
          loading={kpiLoading}
        />
        <KpiCard
          title="Total Gross Profit"
          value={fmtCurrency(totalGrossProfit)}
          subtitle="Delivered deals"
          icon={<DollarSign className="h-5 w-5 text-emerald-600" />}
          iconBg="bg-emerald-50"
          loading={kpiLoading}
        />
        <KpiCard
          title="Current Inventory"
          value={fmtNumber(currentInventory)}
          subtitle="Current"
          icon={<Car className="h-5 w-5 text-purple-600" />}
          iconBg="bg-purple-50"
          loading={kpiLoading}
        />
        <KpiCard
          title="Floor Plan Exposure"
          value={fmtNumber(floorPlanCount) + ' vehicles'}
          subtitle="Active floor plan"
          icon={<Building2 className="h-5 w-5 text-amber-600" />}
          iconBg="bg-amber-50"
          loading={kpiLoading}
        />
      </div>

      {/* ── Row 2: Quick Actions + Recent Activity ── */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Quick Actions */}
        <div className="lg:col-span-1">
          <h2 className="mb-4 text-base font-semibold text-gray-900">Quick Actions</h2>
          <div className="space-y-3">
            <QuickAction
              label="New Deal"
              description="Start a new vehicle sale"
              icon={<ShoppingCart className="h-5 w-5 text-blue-600" />}
              iconBg="bg-blue-50"
              onClick={() => navigate('/deals')} // create modal can be triggered from deals page
            />
            <QuickAction
              label="Add Customer"
              description="Register a new customer"
              icon={<UserPlus className="h-5 w-5 text-emerald-600" />}
              iconBg="bg-emerald-50"
              onClick={() => navigate('/customers')}
            />
            <QuickAction
              label="Vehicle Lookup"
              description="Search inventory by VIN or stock"
              icon={<Search className="h-5 w-5 text-purple-600" />}
              iconBg="bg-purple-50"
              onClick={() => navigate('/vehicles')}
            />
            <QuickAction
              label="Finance Calculator"
              description="Loan and lease calculator"
              icon={<Calculator className="h-5 w-5 text-amber-600" />}
              iconBg="bg-amber-50"
              onClick={() => navigate('/finance/loan-calculator')}
            />
            <QuickAction
              label="Stock Dashboard"
              description="Positions, aging, and alerts"
              icon={<Layers className="h-5 w-5 text-teal-600" />}
              iconBg="bg-teal-50"
              onClick={() => navigate('/stock')}
            />
            <QuickAction
              label="Batch Jobs"
              description="Run and monitor batch programs"
              icon={<Briefcase className="h-5 w-5 text-indigo-600" />}
              iconBg="bg-indigo-50"
              onClick={() => navigate('/batch/jobs')}
            />
          </div>
        </div>

        {/* Recent Activity (Audit Log) */}
        <div className="lg:col-span-2">
          <h2 className="mb-4 text-base font-semibold text-gray-900">Recent Activity</h2>
          <div className="rounded-xl border border-gray-100 bg-white shadow-card">
            {auditLoading ? (
              <div className="flex items-center justify-center p-12">
                <Loader2 className="h-5 w-5 animate-spin text-blue-600" />
                <span className="ml-2 text-sm text-gray-500">Loading activity...</span>
              </div>
            ) : auditError ? (
              <div className="flex flex-col items-center justify-center gap-2 p-12 text-center">
                <ShieldAlert className="h-8 w-8 text-gray-300" />
                <p className="text-sm text-gray-500">{auditError}</p>
              </div>
            ) : auditEntries.length === 0 ? (
              <div className="p-12 text-center text-sm text-gray-400">
                No recent activity
              </div>
            ) : (
              <ul className="divide-y divide-gray-50">
                {auditEntries.map((entry) => (
                  <li
                    key={entry.auditId}
                    className="flex items-center gap-4 px-5 py-4 transition-colors hover:bg-gray-50/50"
                  >
                    <ActionBadge action={entry.actionType} />
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium text-gray-900">
                        {entry.tableName}
                        <span className="ml-1.5 font-normal text-gray-500">
                          &middot; {entry.keyValue}
                        </span>
                      </p>
                      <p className="truncate text-xs text-gray-500">
                        by {entry.userId}
                        {entry.programId ? ` via ${entry.programId}` : ''}
                      </p>
                    </div>
                    <div className="flex flex-shrink-0 items-center gap-1.5 text-xs text-gray-400">
                      <Clock className="h-3 w-3" />
                      {fmtTimestamp(entry.auditTs)}
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
      </div>

      {/* ── Row 3: System Health ───────────────────── */}
      <div>
        <h2 className="mb-4 text-base font-semibold text-gray-900">System Health</h2>

        {/* Summary card */}
        <div className="mb-4 flex items-center gap-4 rounded-xl border border-gray-100 bg-white p-5 shadow-card">
          <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-indigo-50">
            <Server className="h-5 w-5 text-indigo-600" />
          </div>
          <div className="flex-1">
            <p className="text-sm font-medium text-gray-500">Batch Jobs Status</p>
            <p className="mt-0.5 text-lg font-bold text-gray-900">
              {batchLoading ? '...' : `${healthyCount} / ${batchJobs.length} healthy`}
            </p>
          </div>
          <div className="text-right">
            <p className="text-xs text-gray-400">Last daily run</p>
            <p className="mt-0.5 text-sm font-medium text-gray-700">
              {lastDailyRun ? new Date(lastDailyRun).toLocaleDateString() : 'Never'}
            </p>
          </div>
        </div>

        {/* Batch jobs table */}
        {batchLoading ? (
          <div className="flex items-center justify-center rounded-xl border border-gray-100 bg-white p-12 shadow-card">
            <Loader2 className="h-6 w-6 animate-spin text-blue-600" />
            <span className="ml-2 text-sm text-gray-500">Loading batch jobs...</span>
          </div>
        ) : batchJobs.length === 0 ? (
          <div className="rounded-xl border border-gray-100 bg-white p-12 text-center text-sm text-gray-400 shadow-card">
            No batch jobs found
          </div>
        ) : (
          <div className="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-card">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-gray-200 bg-gray-50">
                  <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Program</th>
                  <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Description</th>
                  <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Last Run</th>
                  <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Status</th>
                  <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500 text-right">Records</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {batchJobs.map((job) => {
                  const health = getJobHealthStatus(job);
                  const badge = HEALTH_BADGE[health];
                  const BadgeIcon = badge.icon;
                  return (
                    <tr key={job.programId} className="hover:bg-gray-50/50">
                      <td className="whitespace-nowrap px-4 py-3 font-mono text-xs text-gray-600">
                        {job.programId}
                      </td>
                      <td className="px-4 py-3 text-gray-700">
                        {job.programName || job.statusDescription || '-'}
                      </td>
                      <td className="whitespace-nowrap px-4 py-3 text-gray-500">
                        {job.lastRunDate
                          ? new Date(job.lastRunDate).toLocaleDateString()
                          : 'Never'}
                      </td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium ${badge.bg} ${badge.text}`}>
                          <BadgeIcon className="h-3 w-3" />
                          {health}
                        </span>
                      </td>
                      <td className="whitespace-nowrap px-4 py-3 text-right font-medium text-gray-900">
                        {job.recordsProcessed?.toLocaleString() ?? 0}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

export default DashboardPage;
