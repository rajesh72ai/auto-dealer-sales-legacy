import { useState } from 'react';
import { FileText, Search, Printer } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import { generateDealDocument } from '@/api/finance';
import type { DealDocumentResponse } from '@/types/finance';

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

function formatCurrencyWhole(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

const DOC_TYPE_TITLES: Record<string, string> = {
  LOAN: 'Retail Installment Sales Contract',
  LEASE: 'Motor Vehicle Lease Agreement',
  CASH: 'Cash Purchase Receipt',
};

function DealDocumentPage() {
  const { addToast } = useToast();

  const [dealNumber, setDealNumber] = useState('');
  const [doc, setDoc] = useState<DealDocumentResponse | null>(null);
  const [loading, setLoading] = useState(false);

  const handleGenerate = async () => {
    if (!dealNumber.trim()) {
      addToast('warning', 'Please enter a deal number');
      return;
    }
    setLoading(true);
    try {
      const resp = await generateDealDocument(dealNumber.trim());
      setDoc(resp);
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to generate document');
    } finally {
      setLoading(false);
    }
  };

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="mx-auto max-w-5xl space-y-6">
      {/* Header (hidden when printing) */}
      <div className="flex items-center justify-between print:hidden">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-amber-50">
            <FileText className="h-5 w-5 text-amber-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Deal Closing Document</h1>
            <p className="mt-0.5 text-sm text-gray-500">Generate and print deal contracts</p>
          </div>
        </div>
        {doc && (
          <button
            onClick={handlePrint}
            className="inline-flex items-center gap-2 rounded-lg bg-gray-900 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-gray-800"
          >
            <Printer className="h-4 w-4" />
            Print Document
          </button>
        )}
      </div>

      {/* Deal Number Input (hidden when printing) */}
      <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm print:hidden">
        <div className="flex items-end gap-4">
          <div className="flex-1 max-w-sm">
            <label className="mb-1.5 block text-sm font-medium text-gray-700">Deal Number</label>
            <div className="relative">
              <input
                type="text"
                value={dealNumber}
                onChange={(e) => setDealNumber(e.target.value)}
                onKeyDown={(e) => { if (e.key === 'Enter') handleGenerate(); }}
                placeholder="e.g. DL-10042"
                className="block w-full rounded-lg border border-gray-300 py-2.5 pl-10 pr-3 text-sm text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
              />
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            </div>
          </div>
          <button
            onClick={handleGenerate}
            disabled={loading}
            className="inline-flex items-center gap-2 rounded-lg bg-amber-600 px-5 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-amber-700 disabled:opacity-50"
          >
            <FileText className="h-4 w-4" />
            {loading ? 'Generating...' : 'Generate'}
          </button>
        </div>
      </div>

      {/* Document Paper */}
      {doc && (
        <div className="rounded-xl border border-gray-300 bg-white shadow-lg print:border-0 print:shadow-none">
          {/* Document content */}
          <div className="px-12 py-10 print:px-0 print:py-0">
            {/* Title */}
            <div className="border-b-2 border-gray-900 pb-4 text-center">
              <h2 className="text-xl font-bold uppercase tracking-wide text-gray-900">
                {DOC_TYPE_TITLES[doc.documentType] || doc.documentType}
              </h2>
              <p className="mt-1 text-sm text-gray-500">
                Deal Number: <span className="font-mono font-semibold text-gray-900">{doc.dealNumber}</span>
              </p>
            </div>

            {/* Seller / Buyer */}
            <div className="mt-6 grid grid-cols-2 gap-8">
              {/* Seller */}
              <div className="rounded-lg border border-gray-200 p-4">
                <h3 className="text-xs font-bold uppercase tracking-wide text-gray-500">Seller (Dealer)</h3>
                <div className="mt-2 space-y-0.5 text-sm text-gray-900">
                  <p className="font-semibold">{doc.seller.dealerName}</p>
                  <p>{doc.seller.address}</p>
                  <p>{doc.seller.city}, {doc.seller.state} {doc.seller.zip}</p>
                </div>
              </div>

              {/* Buyer */}
              <div className="rounded-lg border border-gray-200 p-4">
                <h3 className="text-xs font-bold uppercase tracking-wide text-gray-500">Buyer (Customer)</h3>
                <div className="mt-2 space-y-0.5 text-sm text-gray-900">
                  <p className="font-semibold">{doc.buyer.customerName}</p>
                  <p>{doc.buyer.address}</p>
                  <p>{doc.buyer.city}, {doc.buyer.state} {doc.buyer.zip}</p>
                </div>
              </div>
            </div>

            {/* Vehicle Information */}
            <div className="mt-6">
              <h3 className="mb-3 text-xs font-bold uppercase tracking-wide text-gray-500">Vehicle Information</h3>
              <div className="rounded-lg border border-gray-200 bg-gray-50 p-4">
                <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
                  <DocField label="Year/Make/Model" value={`${doc.vehicle.year} ${doc.vehicle.make} ${doc.vehicle.modelName}`} />
                  <DocField label="VIN" value={doc.vehicle.vin} mono />
                  <DocField label="Stock #" value={doc.vehicle.stockNumber} />
                  <DocField label="Odometer" value={`${doc.vehicle.odometer?.toLocaleString() || '0'} miles`} />
                </div>
              </div>
            </div>

            {/* Pricing Breakdown */}
            <div className="mt-6">
              <h3 className="mb-3 text-xs font-bold uppercase tracking-wide text-gray-500">Itemized Pricing</h3>
              <div className="rounded-lg border border-gray-200 overflow-hidden">
                <table className="w-full text-sm">
                  <tbody className="divide-y divide-gray-100">
                    <PricingRow label="Vehicle Price" amount={doc.pricing.vehiclePrice} />
                    {doc.pricing.options > 0 && <PricingRow label="Options / Accessories" amount={doc.pricing.options} />}
                    {doc.pricing.destination > 0 && <PricingRow label="Destination Charge" amount={doc.pricing.destination} />}
                    {doc.pricing.rebates > 0 && <PricingRow label="Manufacturer Rebates" amount={-doc.pricing.rebates} />}
                    {doc.pricing.tradeAllowance > 0 && <PricingRow label="Trade-In Allowance" amount={-doc.pricing.tradeAllowance} />}
                    <PricingRow label="Taxes" amount={doc.pricing.taxes} />
                    <PricingRow label="Fees (Doc, Title, Registration)" amount={doc.pricing.fees} />
                    <PricingRow label="Total Price" amount={doc.pricing.totalPrice} bold />
                    <PricingRow label="Down Payment" amount={-doc.pricing.downPayment} />
                    <PricingRow label="Amount Financed" amount={doc.pricing.amountFinanced} bold highlight />
                  </tbody>
                </table>
              </div>
            </div>

            {/* Finance Terms */}
            {doc.financeTerms && doc.documentType !== 'CASH' && (
              <div className="mt-6">
                <h3 className="mb-3 text-xs font-bold uppercase tracking-wide text-gray-500">Finance Terms</h3>
                <div className="grid grid-cols-5 gap-3">
                  <TermBox label="Annual Percentage Rate" value={`${doc.financeTerms.apr?.toFixed(2) ?? '--'}%`} />
                  <TermBox label="Term" value={`${doc.financeTerms.termMonths} Months`} />
                  <TermBox label="Monthly Payment" value={formatCurrency(doc.financeTerms.monthlyPayment)} highlight />
                  <TermBox label="Total of Payments" value={formatCurrency(doc.financeTerms.totalOfPayments)} />
                  <TermBox label="Finance Charge" value={formatCurrency(doc.financeTerms.financeCharge)} />
                </div>
              </div>
            )}

            {/* F&I Products */}
            {doc.fiProducts && doc.fiProducts.length > 0 && (
              <div className="mt-6">
                <h3 className="mb-3 text-xs font-bold uppercase tracking-wide text-gray-500">Finance & Insurance Products</h3>
                <div className="rounded-lg border border-gray-200 overflow-hidden">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-gray-200 bg-gray-50">
                        <th className="px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-gray-500">Product</th>
                        <th className="px-4 py-2.5 text-right text-xs font-semibold uppercase tracking-wide text-gray-500">Price</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100">
                      {doc.fiProducts.map((prod, idx) => (
                        <tr key={idx} className="hover:bg-gray-50/50">
                          <td className="px-4 py-2.5 text-gray-900">{prod.productName}</td>
                          <td className="px-4 py-2.5 text-right font-medium text-gray-900">{formatCurrency(prod.retailPrice)}</td>
                        </tr>
                      ))}
                      <tr className="bg-gray-50 font-semibold">
                        <td className="px-4 py-2.5 text-gray-900">Total F&I Products</td>
                        <td className="px-4 py-2.5 text-right text-gray-900">
                          {formatCurrency(doc.fiProducts.reduce((sum, p) => sum + p.retailPrice, 0))}
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* Signature Lines */}
            <div className="mt-12 grid grid-cols-2 gap-12">
              <div>
                <div className="border-b border-gray-900" />
                <p className="mt-1 text-xs text-gray-500">Buyer Signature</p>
                <p className="mt-3 text-xs text-gray-400">Date: ____________________</p>
              </div>
              <div>
                <div className="border-b border-gray-900" />
                <p className="mt-1 text-xs text-gray-500">Dealer Representative Signature</p>
                <p className="mt-3 text-xs text-gray-400">Date: ____________________</p>
              </div>
            </div>

            {/* Disclaimer */}
            <div className="mt-8 rounded-lg bg-gray-50 p-4 text-xs leading-relaxed text-gray-500">
              <p>
                This document constitutes a binding agreement between the buyer and seller for the purchase/lease of the
                vehicle described above. By signing this document, the buyer acknowledges receipt of all disclosures
                required by federal and state law, including the Truth in Lending Act and the Consumer Leasing Act, as
                applicable. All terms and conditions are subject to the approval of the financing institution.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Empty state */}
      {!doc && !loading && (
        <div className="rounded-xl border-2 border-dashed border-gray-200 bg-gray-50/50 py-16 text-center">
          <FileText className="mx-auto h-12 w-12 text-gray-300" />
          <p className="mt-4 text-sm font-medium text-gray-500">
            Enter a deal number and click <span className="text-amber-600">Generate</span> to create the closing document
          </p>
        </div>
      )}

      {loading && (
        <div className="rounded-xl border border-gray-200 bg-white py-16 text-center shadow-sm">
          <div className="mx-auto h-8 w-8 animate-spin rounded-full border-4 border-gray-200 border-t-amber-600" />
          <p className="mt-4 text-sm font-medium text-gray-500">Generating document...</p>
        </div>
      )}
    </div>
  );
}

function DocField({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div>
      <p className="text-xs text-gray-500">{label}</p>
      <p className={`mt-0.5 text-sm font-semibold text-gray-900 ${mono ? 'font-mono' : ''}`}>{value}</p>
    </div>
  );
}

function PricingRow({ label, amount, bold, highlight }: { label: string; amount: number; bold?: boolean; highlight?: boolean }) {
  return (
    <tr className={`${bold ? 'bg-gray-50' : ''} ${highlight ? 'bg-blue-50' : ''}`}>
      <td className={`px-4 py-2.5 ${bold ? 'font-semibold text-gray-900' : 'text-gray-700'}`}>{label}</td>
      <td className={`px-4 py-2.5 text-right ${bold ? 'font-bold text-gray-900' : 'font-medium text-gray-700'} ${highlight ? 'text-blue-700' : ''}`}>
        {amount < 0 ? `(${formatCurrencyWhole(Math.abs(amount))})` : formatCurrencyWhole(amount)}
      </td>
    </tr>
  );
}

function TermBox({ label, value, highlight }: { label: string; value: string; highlight?: boolean }) {
  return (
    <div className={`rounded-lg border p-3 text-center ${highlight ? 'border-blue-300 bg-blue-50' : 'border-gray-200 bg-gray-50'}`}>
      <p className="text-xs text-gray-500">{label}</p>
      <p className={`mt-1 text-sm font-bold ${highlight ? 'text-blue-700' : 'text-gray-900'}`}>{value}</p>
    </div>
  );
}

export default DealDocumentPage;
