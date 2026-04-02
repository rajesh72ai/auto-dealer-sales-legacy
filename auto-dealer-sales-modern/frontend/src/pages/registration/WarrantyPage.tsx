import { useState } from 'react';
import { Shield, Search } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import FormField from '@/components/shared/FormField';
import { getWarrantiesByVin } from '@/api/warranty';
import type { Warranty } from '@/types/registration';

const WARRANTY_STATUS_CONFIG: Record<string, { bg: string; text: string }> = {
  Active: { bg: 'bg-green-50', text: 'text-green-700' },
  Expired: { bg: 'bg-red-50', text: 'text-red-700' },
};

function WarrantyPage() {
  const { addToast } = useToast();

  const [vin, setVin] = useState('');
  const [warranties, setWarranties] = useState<Warranty[]>([]);
  const [searched, setSearched] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSearch = async () => {
    if (!vin || vin.length !== 17) {
      addToast('error', 'Please enter a valid 17-character VIN');
      return;
    }
    setLoading(true);
    try {
      const results = await getWarrantiesByVin(vin);
      setWarranties(results);
      setSearched(true);
      if (results.length === 0) addToast('warning', 'No warranty records found for this VIN');
    } catch {
      addToast('error', 'Failed to load warranty data');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
          <Shield className="h-7 w-7 text-emerald-600" /> Warranty Coverage
        </h1>
        <p className="text-sm text-gray-500 mt-1">Look up warranty coverage by VIN</p>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div className="flex items-end gap-4">
          <div className="flex-1 max-w-md">
            <FormField label="Vehicle VIN" required>
              <input type="text" value={vin} maxLength={17} placeholder="Enter 17-character VIN"
                onChange={(e) => setVin(e.target.value.toUpperCase())}
                onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
                className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm font-mono text-gray-900 placeholder-gray-400 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20" />
            </FormField>
          </div>
          <button onClick={handleSearch} disabled={loading}
            className="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 disabled:opacity-50">
            <Search className="h-4 w-4" /> Search
          </button>
        </div>
      </div>

      {loading && (
        <div className="flex justify-center p-8">
          <div className="animate-spin h-8 w-8 border-4 border-emerald-500 border-t-transparent rounded-full" />
        </div>
      )}

      {searched && !loading && warranties.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {warranties.map((w) => {
            const statusCfg = WARRANTY_STATUS_CONFIG[w.status] || { bg: 'bg-gray-100', text: 'text-gray-700' };
            return (
              <div key={w.warrantyId} className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-semibold text-gray-900">{w.warrantyTypeName}</h3>
                  <span className={`px-2.5 py-0.5 rounded-full text-xs font-medium ${statusCfg.bg} ${statusCfg.text}`}>
                    {w.status}
                  </span>
                </div>
                <dl className="space-y-2">
                  {[
                    ['Start Date', w.startDate],
                    ['Expiry Date', w.expiryDate],
                    ['Mileage Limit', w.mileageLimit === 999999 ? 'Unlimited' : w.mileageLimit.toLocaleString() + ' mi'],
                    ['Deductible', w.formattedDeductible],
                    ['Remaining', w.remainingDays > 0 ? `${w.remainingDays} days` : 'Expired'],
                    ['Deal #', w.dealNumber],
                  ].map(([label, value]) => (
                    <div key={String(label)} className="flex justify-between text-sm">
                      <span className="text-gray-500">{label}</span>
                      <span className="font-medium text-gray-900">{String(value)}</span>
                    </div>
                  ))}
                </dl>
              </div>
            );
          })}
        </div>
      )}

      {searched && !loading && warranties.length === 0 && (
        <div className="text-center py-12 bg-white rounded-xl border border-gray-200">
          <Shield className="h-12 w-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">No warranty records found for VIN {vin}</p>
        </div>
      )}
    </div>
  );
}

export default WarrantyPage;
