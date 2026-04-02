import { useState } from 'react';
import {
  ShieldCheck,
  Search,
  Wrench,
  CarFront,
  Shield,
  Zap,
  Droplets,
  Key,
  Paintbrush,
  Disc3,
  Gem,
  BadgeCheck,
  Check,
} from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import { getProductCatalog, selectProducts } from '@/api/finance';
import type { ProductItem } from '@/types/finance';

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

// Map product codes to appropriate icons
const PRODUCT_ICONS: Record<string, React.ReactNode> = {
  VSC: <ShieldCheck className="h-6 w-6" />,
  GAP: <Shield className="h-6 w-6" />,
  MNT: <Wrench className="h-6 w-6" />,
  TW: <CarFront className="h-6 w-6" />,
  PPM: <Paintbrush className="h-6 w-6" />,
  ADH: <Zap className="h-6 w-6" />,
  PROT: <Droplets className="h-6 w-6" />,
  KEY: <Key className="h-6 w-6" />,
  TIRE: <Disc3 className="h-6 w-6" />,
  PREM: <Gem className="h-6 w-6" />,
};

const PRODUCT_COLORS: Record<string, { bg: string; text: string; border: string }> = {
  VSC: { bg: 'bg-blue-50', text: 'text-blue-600', border: 'border-blue-200' },
  GAP: { bg: 'bg-emerald-50', text: 'text-emerald-600', border: 'border-emerald-200' },
  MNT: { bg: 'bg-amber-50', text: 'text-amber-600', border: 'border-amber-200' },
  TW: { bg: 'bg-purple-50', text: 'text-purple-600', border: 'border-purple-200' },
  PPM: { bg: 'bg-pink-50', text: 'text-pink-600', border: 'border-pink-200' },
  ADH: { bg: 'bg-orange-50', text: 'text-orange-600', border: 'border-orange-200' },
  PROT: { bg: 'bg-cyan-50', text: 'text-cyan-600', border: 'border-cyan-200' },
  KEY: { bg: 'bg-indigo-50', text: 'text-indigo-600', border: 'border-indigo-200' },
  TIRE: { bg: 'bg-gray-50', text: 'text-gray-600', border: 'border-gray-300' },
  PREM: { bg: 'bg-yellow-50', text: 'text-yellow-600', border: 'border-yellow-200' },
};

function getProductIcon(code: string): React.ReactNode {
  return PRODUCT_ICONS[code] || <BadgeCheck className="h-6 w-6" />;
}

function getProductColors(code: string) {
  return PRODUCT_COLORS[code] || { bg: 'bg-gray-50', text: 'text-gray-600', border: 'border-gray-200' };
}

function FinanceProductsPage() {
  const { addToast } = useToast();

  const [dealNumber, setDealNumber] = useState('');
  const [catalog, setCatalog] = useState<ProductItem[]>([]);
  const [selectedCodes, setSelectedCodes] = useState<Set<string>>(new Set());
  const [loaded, setLoaded] = useState(false);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);

  const handleLoadCatalog = async () => {
    if (!dealNumber.trim()) {
      addToast('warning', 'Please enter a deal number');
      return;
    }
    setLoading(true);
    try {
      const resp = await getProductCatalog(dealNumber.trim());
      setCatalog(resp.catalog);
      const preSelected = new Set(resp.catalog.filter((p) => p.selected).map((p) => p.code));
      setSelectedCodes(preSelected);
      setLoaded(true);
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to load product catalog');
    } finally {
      setLoading(false);
    }
  };

  const toggleProduct = (code: string) => {
    setSelectedCodes((prev) => {
      const next = new Set(prev);
      if (next.has(code)) {
        next.delete(code);
      } else {
        next.add(code);
      }
      return next;
    });
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const resp = await selectProducts({
        dealNumber: dealNumber.trim(),
        selectedProducts: Array.from(selectedCodes),
      });
      setCatalog(resp.catalog);
      addToast('success', `${resp.selectedCount} products saved. Total profit: ${formatCurrency(resp.totalProfit)}`);
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to save product selection');
    } finally {
      setSaving(false);
    }
  };

  // Summary calculations
  const selectedProducts = catalog.filter((p) => selectedCodes.has(p.code));
  const totalRetail = selectedProducts.reduce((sum, p) => sum + p.retailPrice, 0);
  const totalCost = selectedProducts.reduce((sum, p) => sum + p.dealerCost, 0);
  const totalProfit = selectedProducts.reduce((sum, p) => sum + p.profit, 0);

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-50">
          <ShieldCheck className="h-5 w-5 text-indigo-600" />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">F&I Product Menu</h1>
          <p className="mt-0.5 text-sm text-gray-500">Select finance and insurance products for the deal</p>
        </div>
      </div>

      {/* Deal Number Search */}
      <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
        <div className="flex items-end gap-4">
          <div className="flex-1 max-w-sm">
            <label className="mb-1.5 block text-sm font-medium text-gray-700">Deal Number</label>
            <div className="relative">
              <input
                type="text"
                value={dealNumber}
                onChange={(e) => setDealNumber(e.target.value)}
                onKeyDown={(e) => { if (e.key === 'Enter') handleLoadCatalog(); }}
                placeholder="e.g. DL-10042"
                className="block w-full rounded-lg border border-gray-300 py-2.5 pl-10 pr-3 text-sm text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
              />
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            </div>
          </div>
          <button
            onClick={handleLoadCatalog}
            disabled={loading}
            className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-5 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-indigo-700 disabled:opacity-50"
          >
            {loading ? 'Loading...' : 'Load Products'}
          </button>
        </div>
      </div>

      {/* Product Grid */}
      {loaded && catalog.length > 0 && (
        <>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
            {catalog.map((product) => {
              const isSelected = selectedCodes.has(product.code);
              const colors = getProductColors(product.code);
              return (
                <button
                  key={product.code}
                  type="button"
                  onClick={() => toggleProduct(product.code)}
                  className={`group relative rounded-xl border-2 p-5 text-left transition-all ${
                    isSelected
                      ? `${colors.border} bg-white shadow-md ring-2 ring-blue-500/20`
                      : 'border-gray-200 bg-white hover:border-gray-300 hover:shadow-sm'
                  }`}
                >
                  {/* Selected indicator */}
                  {isSelected && (
                    <div className="absolute right-3 top-3 flex h-6 w-6 items-center justify-center rounded-full bg-blue-600">
                      <Check className="h-3.5 w-3.5 text-white" />
                    </div>
                  )}

                  {/* Icon */}
                  <div className={`flex h-12 w-12 items-center justify-center rounded-xl ${colors.bg} ${colors.text}`}>
                    {getProductIcon(product.code)}
                  </div>

                  {/* Name & details */}
                  <h3 className="mt-3 text-sm font-semibold text-gray-900">{product.name}</h3>
                  <div className="mt-2 space-y-1 text-xs text-gray-500">
                    <p>{product.term} months / {product.miles?.toLocaleString() || '--'} miles</p>
                  </div>

                  {/* Pricing */}
                  <div className="mt-3 border-t border-gray-100 pt-3">
                    <div className="flex items-baseline justify-between">
                      <span className="text-lg font-bold text-gray-900">{formatCurrency(product.retailPrice)}</span>
                    </div>
                    <div className="mt-1 flex justify-between text-xs">
                      <span className="text-gray-400">Cost: {formatCurrency(product.dealerCost)}</span>
                      <span className="font-semibold text-emerald-600">+{formatCurrency(product.profit)}</span>
                    </div>
                  </div>
                </button>
              );
            })}
          </div>

          {/* Summary Bar */}
          <div className="sticky bottom-0 z-10 rounded-xl border border-gray-200 bg-white/95 px-6 py-4 shadow-lg backdrop-blur-sm">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-8">
                <div>
                  <p className="text-xs font-medium uppercase text-gray-500">Selected</p>
                  <p className="text-lg font-bold text-gray-900">{selectedProducts.length} products</p>
                </div>
                <div className="h-8 w-px bg-gray-200" />
                <div>
                  <p className="text-xs font-medium uppercase text-gray-500">Total Retail</p>
                  <p className="text-lg font-bold text-gray-900">{formatCurrency(totalRetail)}</p>
                </div>
                <div className="h-8 w-px bg-gray-200" />
                <div>
                  <p className="text-xs font-medium uppercase text-gray-500">Total Cost</p>
                  <p className="text-lg font-bold text-gray-700">{formatCurrency(totalCost)}</p>
                </div>
                <div className="h-8 w-px bg-gray-200" />
                <div>
                  <p className="text-xs font-medium uppercase text-gray-500">Total Profit</p>
                  <p className="text-lg font-bold text-emerald-600">{formatCurrency(totalProfit)}</p>
                </div>
              </div>
              <button
                onClick={handleSave}
                disabled={saving}
                className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-6 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 disabled:opacity-50"
              >
                {saving ? 'Saving...' : 'Save Selection'}
              </button>
            </div>
          </div>
        </>
      )}

      {/* Empty state */}
      {loaded && catalog.length === 0 && (
        <div className="rounded-xl border-2 border-dashed border-gray-200 bg-gray-50/50 py-16 text-center">
          <ShieldCheck className="mx-auto h-12 w-12 text-gray-300" />
          <p className="mt-4 text-sm font-medium text-gray-500">No products found for this deal</p>
        </div>
      )}

      {!loaded && (
        <div className="rounded-xl border-2 border-dashed border-gray-200 bg-gray-50/50 py-16 text-center">
          <ShieldCheck className="mx-auto h-12 w-12 text-gray-300" />
          <p className="mt-4 text-sm font-medium text-gray-500">
            Enter a deal number above to load the F&I product catalog
          </p>
        </div>
      )}
    </div>
  );
}

export default FinanceProductsPage;
