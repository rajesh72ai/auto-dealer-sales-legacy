import { useState } from 'react';
import { Download, Loader2 } from 'lucide-react';
import { downloadExport } from '@/api/exports';
import { useToast } from '@/components/shared/Toast';

export interface ExportButtonProps {
  type: string;
  dealerCode: string;
  label?: string;
}

/**
 * Reusable CSV export download button.
 * Shows a loading spinner during download and displays toast on error.
 */
export default function ExportButton({ type, dealerCode, label }: ExportButtonProps) {
  const [loading, setLoading] = useState(false);
  const { addToast } = useToast();

  const handleExport = async () => {
    if (!dealerCode) {
      addToast('error', 'Please select a dealer code first');
      return;
    }
    setLoading(true);
    try {
      await downloadExport(type, dealerCode);
      addToast('success', 'Export downloaded successfully');
    } catch {
      addToast('error', 'Failed to download export');
    } finally {
      setLoading(false);
    }
  };

  return (
    <button
      onClick={handleExport}
      disabled={loading || !dealerCode}
      title={label || `Export ${type}`}
      className="inline-flex items-center gap-1.5 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-medium text-gray-700 shadow-sm transition-colors hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-brand-500/20 disabled:cursor-not-allowed disabled:opacity-50"
    >
      {loading ? (
        <Loader2 className="h-4 w-4 animate-spin" />
      ) : (
        <Download className="h-4 w-4" />
      )}
      {label || 'Export CSV'}
    </button>
  );
}
