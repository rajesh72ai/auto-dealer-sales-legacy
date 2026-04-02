import { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, CreditCard, ShieldCheck, AlertTriangle } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import { getCustomer } from '@/api/customers';
import { getCreditChecksByCustomer, runCreditCheck } from '@/api/creditChecks';
import type { Customer, CreditCheckResponse } from '@/types/customer';

const TIER_CONFIG: Record<string, { color: string; gaugeColor: string; label: string; desc: string }> = {
  A: { color: 'bg-emerald-100 text-emerald-800', gaugeColor: '#10b981', label: 'Tier A', desc: 'Excellent Credit' },
  B: { color: 'bg-blue-100 text-blue-800', gaugeColor: '#3b82f6', label: 'Tier B', desc: 'Good Credit' },
  C: { color: 'bg-amber-100 text-amber-800', gaugeColor: '#f59e0b', label: 'Tier C', desc: 'Fair Credit' },
  D: { color: 'bg-orange-100 text-orange-800', gaugeColor: '#f97316', label: 'Tier D', desc: 'Below Average' },
  E: { color: 'bg-red-100 text-red-800', gaugeColor: '#ef4444', label: 'Tier E', desc: 'Poor Credit' },
};

function CreditScoreArc({ score, tier }: { score: number; tier: string }) {
  const maxScore = 850;
  const minScore = 300;
  const pct = Math.max(0, Math.min(1, (score - minScore) / (maxScore - minScore)));
  const config = TIER_CONFIG[tier] || TIER_CONFIG.C;
  const angle = -90 + pct * 180;

  // Arc segments for colored background
  const segments = [
    { pctEnd: 0.36, color: '#ef4444' }, // 300-500 red
    { pctEnd: 0.51, color: '#f97316' }, // 500-580 orange
    { pctEnd: 0.67, color: '#f59e0b' }, // 580-670 amber
    { pctEnd: 0.82, color: '#3b82f6' }, // 670-750 blue
    { pctEnd: 1.0, color: '#10b981' },  // 750-850 green
  ];

  return (
    <div className="relative mx-auto h-44 w-72">
      <svg viewBox="0 0 240 130" className="w-full">
        {/* Multi-colored background arc */}
        {segments.map((seg, i) => {
          const prevEnd = i === 0 ? 0 : segments[i - 1].pctEnd;
          const arcLen = 251.2;
          return (
            <path
              key={i}
              d="M 20 115 A 100 100 0 0 1 220 115"
              fill="none"
              stroke={seg.color}
              strokeWidth="18"
              strokeLinecap="butt"
              strokeDasharray={`${(seg.pctEnd - prevEnd) * arcLen} ${arcLen}`}
              strokeDashoffset={`${-prevEnd * arcLen}`}
              opacity={0.2}
            />
          );
        })}
        {/* Active arc */}
        <path
          d="M 20 115 A 100 100 0 0 1 220 115"
          fill="none"
          stroke={config.gaugeColor}
          strokeWidth="18"
          strokeLinecap="round"
          strokeDasharray={`${pct * 314} 314`}
        />
        {/* Needle */}
        <g transform={`rotate(${angle}, 120, 115)`}>
          <line x1="120" y1="115" x2="120" y2="28" stroke="#374151" strokeWidth="3" strokeLinecap="round" />
          <circle cx="120" cy="115" r="6" fill="#374151" />
          <circle cx="120" cy="115" r="3" fill="white" />
        </g>
        {/* Score */}
        <text x="120" y="106" textAnchor="middle" fill="#111827" fontSize="36" fontWeight="bold">
          {score}
        </text>
      </svg>
      {/* Range labels */}
      <div className="flex justify-between px-4 -mt-1 text-xs font-medium text-gray-400">
        <span>300</span>
        <span>500</span>
        <span>670</span>
        <span>750</span>
        <span>850</span>
      </div>
    </div>
  );
}

function CreditCheckPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { addToast } = useToast();
  const customerId = Number(id);

  const [customer, setCustomer] = useState<Customer | null>(null);
  const [creditChecks, setCreditChecks] = useState<CreditCheckResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [monthlyDebt, setMonthlyDebt] = useState('');
  const [bureauCode, setBureauCode] = useState('EQ');
  const [running, setRunning] = useState(false);

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [cust, checks] = await Promise.all([
        getCustomer(customerId),
        getCreditChecksByCustomer(customerId),
      ]);
      setCustomer(cust);
      setCreditChecks(checks);
    } catch {
      addToast('error', 'Failed to load data');
    } finally {
      setLoading(false);
    }
  }, [customerId, addToast]);

  useEffect(() => { loadData(); }, [loadData]);

  const handleRun = async () => {
    setRunning(true);
    try {
      const result = await runCreditCheck({
        customerId,
        monthlyDebt: monthlyDebt ? Number(monthlyDebt) : undefined,
        bureauCode,
      });
      setCreditChecks((prev) => [result, ...prev]);
      setMonthlyDebt('');
      addToast('success', result.message || 'Credit check completed');
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Credit check failed');
    } finally {
      setRunning(false);
    }
  };

  if (loading) {
    return (
      <div className="mx-auto max-w-4xl animate-pulse space-y-4">
        <div className="h-8 w-48 rounded bg-gray-200" />
        <div className="h-48 rounded-xl bg-gray-200" />
      </div>
    );
  }

  const latest = creditChecks[0] ?? null;
  const tierCfg = latest ? TIER_CONFIG[latest.creditTier] : null;

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button
          onClick={() => navigate(`/customers/${customerId}`)}
          className="flex h-9 w-9 items-center justify-center rounded-lg border border-gray-300 text-gray-500 hover:bg-gray-50 hover:text-gray-700"
        >
          <ArrowLeft className="h-4 w-4" />
        </button>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Credit Pre-Qualification</h1>
          <p className="text-sm text-gray-500">{customer?.fullName} &middot; ID: {customerId}</p>
        </div>
      </div>

      {/* Customer Summary Strip */}
      {customer && (
        <div className="flex items-center gap-6 rounded-xl border border-gray-200 bg-white px-6 py-4 shadow-sm">
          <div>
            <p className="text-xs font-medium text-gray-500">Name</p>
            <p className="text-sm font-semibold text-gray-900">{customer.fullName}</p>
          </div>
          <div className="h-8 w-px bg-gray-200" />
          <div>
            <p className="text-xs font-medium text-gray-500">Income</p>
            <p className="text-sm font-semibold text-gray-900">{customer.annualIncome != null ? `$${customer.annualIncome.toLocaleString()}/yr` : '\u2014'}</p>
          </div>
          <div className="h-8 w-px bg-gray-200" />
          <div>
            <p className="text-xs font-medium text-gray-500">Employer</p>
            <p className="text-sm font-semibold text-gray-900">{customer.employerName || '\u2014'}</p>
          </div>
          <div className="h-8 w-px bg-gray-200" />
          <div>
            <p className="text-xs font-medium text-gray-500">Dealer</p>
            <p className="text-sm font-semibold text-gray-900">{customer.dealerCode}</p>
          </div>
        </div>
      )}

      {/* Run Check Form */}
      <div className="rounded-xl border border-gray-200 bg-white shadow-sm">
        <div className="border-b border-gray-100 px-6 py-4">
          <h3 className="flex items-center gap-2 text-base font-semibold text-gray-900">
            <ShieldCheck className="h-5 w-5 text-brand-600" />
            Run New Credit Check
          </h3>
        </div>
        <div className="flex items-end gap-4 p-6">
          <div className="w-48">
            <label className="mb-1.5 block text-sm font-medium text-gray-700">Monthly Debt</label>
            <div className="relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">$</span>
              <input
                type="number"
                value={monthlyDebt}
                onChange={(e) => setMonthlyDebt(e.target.value)}
                placeholder="0.00"
                className="block w-full rounded-lg border border-gray-300 pl-7 pr-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none"
              />
            </div>
          </div>
          <div className="w-36">
            <label className="mb-1.5 block text-sm font-medium text-gray-700">Bureau</label>
            <select
              value={bureauCode}
              onChange={(e) => setBureauCode(e.target.value)}
              className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:ring-2 focus:ring-brand-500/20 focus:outline-none"
            >
              <option value="EQ">Equifax</option>
              <option value="TU">TransUnion</option>
              <option value="EX">Experian</option>
            </select>
          </div>
          <button
            onClick={handleRun}
            disabled={running}
            className="inline-flex items-center gap-2 rounded-lg bg-brand-600 px-5 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-brand-700 disabled:opacity-50"
          >
            <CreditCard className="h-4 w-4" />
            {running ? 'Processing...' : 'Run Credit Check'}
          </button>
        </div>
      </div>

      {/* Latest Result Card */}
      {latest && (
        <div className="rounded-xl border border-gray-200 bg-white shadow-sm overflow-hidden">
          <div className="border-b border-gray-100 px-6 py-4 flex items-center justify-between">
            <h3 className="text-base font-semibold text-gray-900">Latest Result</h3>
            {latest.status === 'OK' ? (
              <span className="inline-flex items-center gap-1.5 text-xs font-medium text-emerald-700">
                <ShieldCheck className="h-3.5 w-3.5" /> Approved
              </span>
            ) : (
              <span className="inline-flex items-center gap-1.5 text-xs font-medium text-amber-700">
                <AlertTriangle className="h-3.5 w-3.5" /> Review Required
              </span>
            )}
          </div>
          <div className="p-6">
            <div className="flex flex-col items-center gap-8 lg:flex-row">
              {/* Score Gauge */}
              <div className="flex-shrink-0">
                <CreditScoreArc score={latest.creditScore} tier={latest.creditTier} />
                <div className="mt-2 text-center">
                  <span className={`inline-flex rounded-full px-4 py-1.5 text-sm font-bold ${tierCfg?.color || 'bg-gray-100 text-gray-700'}`}>
                    {latest.creditTierDesc || tierCfg?.desc || latest.creditTier}
                  </span>
                </div>
              </div>

              {/* Details Grid */}
              <div className="flex-1 grid grid-cols-2 gap-6">
                <ResultMetric label="Max Financing" value={`$${latest.maxFinancing.toLocaleString()}`} large />
                <ResultMetric label="DTI Ratio" value={`${latest.dtiRatio}%`} large warn={latest.dtiRatio > 43} />
                <ResultMetric label="Monthly Income" value={`$${latest.monthlyIncome.toLocaleString()}`} />
                <ResultMetric label="Monthly Debt" value={`$${latest.monthlyDebt.toLocaleString()}`} />
                <ResultMetric label="Annual Income" value={`$${latest.annualIncome.toLocaleString()}`} />
                <ResultMetric label="Bureau" value={latest.bureauCode === 'EQ' ? 'Equifax' : latest.bureauCode === 'TU' ? 'TransUnion' : 'Experian'} />
                <ResultMetric label="Credit ID" value={`#${latest.creditId}`} />
                <ResultMetric label="Expires" value={new Date(latest.expiryDate).toLocaleDateString()} />
              </div>
            </div>
          </div>
        </div>
      )}

      {/* History Table */}
      <div className="rounded-xl border border-gray-200 bg-white shadow-sm overflow-hidden">
        <div className="border-b border-gray-100 px-6 py-4">
          <h3 className="text-base font-semibold text-gray-900">Previous Credit Checks</h3>
        </div>
        {creditChecks.length <= 1 ? (
          <p className="px-6 py-8 text-center text-gray-400">
            {creditChecks.length === 0 ? 'No credit checks on file.' : 'No previous checks.'}
          </p>
        ) : (
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-gray-200 bg-gray-50">
                <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">ID</th>
                <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Score</th>
                <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Tier</th>
                <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Bureau</th>
                <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">DTI</th>
                <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500 text-right">Max Financing</th>
                <th className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Expires</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {creditChecks.slice(1).map((cc) => {
                const cfg = TIER_CONFIG[cc.creditTier];
                return (
                  <tr key={cc.creditId} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-gray-600">{cc.creditId}</td>
                    <td className="px-4 py-3 font-semibold text-gray-900">{cc.creditScore}</td>
                    <td className="px-4 py-3">
                      <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${cfg?.color || 'bg-gray-100 text-gray-700'}`}>
                        {cc.creditTierDesc || cc.creditTier}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-gray-600">{cc.bureauCode}</td>
                    <td className="px-4 py-3 text-gray-600">{cc.dtiRatio}%</td>
                    <td className="px-4 py-3 text-right font-medium text-gray-900">${cc.maxFinancing.toLocaleString()}</td>
                    <td className="px-4 py-3 text-gray-500 text-xs">{new Date(cc.expiryDate).toLocaleDateString()}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

function ResultMetric({ label, value, large, warn }: { label: string; value: string; large?: boolean; warn?: boolean }) {
  return (
    <div>
      <p className="text-xs font-medium uppercase text-gray-500">{label}</p>
      <p className={`mt-1 font-semibold ${large ? 'text-xl' : 'text-sm'} ${warn ? 'text-amber-600' : 'text-gray-900'}`}>
        {value}
      </p>
    </div>
  );
}

export default CreditCheckPage;
