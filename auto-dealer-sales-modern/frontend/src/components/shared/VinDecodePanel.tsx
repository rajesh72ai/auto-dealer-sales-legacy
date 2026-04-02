import { useState, useEffect } from 'react';
import { Globe, Factory, Calendar, MapPin, Hash, Loader2 } from 'lucide-react';
import { decodeVin } from '@/api/vin';
import type { VinDecodedInfo } from '@/types/vin';

interface VinDecodePanelProps {
  vin: string;
}

function VinDecodePanel({ vin }: VinDecodePanelProps) {
  const [decoded, setDecoded] = useState<VinDecodedInfo | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!vin || vin.length !== 17) {
      setDecoded(null);
      setError(null);
      return;
    }

    let cancelled = false;
    setLoading(true);
    setError(null);

    decodeVin(vin)
      .then((info) => {
        if (!cancelled) setDecoded(info);
      })
      .catch(() => {
        if (!cancelled) setError('Failed to decode VIN');
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [vin]);

  if (!vin || vin.length !== 17) return null;

  if (loading) {
    return (
      <div className="flex items-center justify-center rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
        <Loader2 className="h-5 w-5 animate-spin text-blue-600" />
        <span className="ml-2 text-sm text-gray-500">Decoding VIN...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-600">
        {error}
      </div>
    );
  }

  if (!decoded) return null;

  const fields = [
    { label: 'Country', value: decoded.countryOfOrigin, icon: Globe },
    { label: 'Manufacturer', value: decoded.manufacturer, icon: Factory },
    { label: 'Model Year', value: String(decoded.modelYear), icon: Calendar },
    { label: 'Plant Code', value: decoded.plantCode, icon: MapPin },
    { label: 'Sequence', value: decoded.sequentialNumber, icon: Hash },
  ];

  return (
    <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
      <h3 className="mb-4 text-sm font-semibold uppercase tracking-wide text-gray-500">
        VIN Decode
      </h3>
      <div className="flex items-center gap-2 mb-4">
        <span className="rounded bg-blue-50 px-2 py-0.5 font-mono text-xs font-medium text-blue-700">
          WMI: {decoded.wmi}
        </span>
      </div>
      <dl className="space-y-3">
        {fields.map(({ label, value, icon: Icon }) => (
          <div key={label} className="flex items-center justify-between">
            <dt className="flex items-center gap-1.5 text-sm text-gray-500">
              <Icon className="h-3.5 w-3.5" />
              {label}
            </dt>
            <dd className="text-sm font-medium text-gray-900">{value}</dd>
          </div>
        ))}
      </dl>
    </div>
  );
}

export default VinDecodePanel;
