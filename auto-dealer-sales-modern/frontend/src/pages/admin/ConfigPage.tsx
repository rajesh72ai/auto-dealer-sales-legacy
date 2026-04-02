import { useState, useEffect, useCallback, useRef } from 'react';
import { Settings, Check, X, Pencil, RefreshCw } from 'lucide-react';
import { useToast } from '@/components/shared/Toast';
import { getConfigs, updateConfig } from '@/api/config';
import type { SystemConfig } from '@/types/admin';

function ConfigPage() {
  const { addToast } = useToast();
  const [items, setItems] = useState<SystemConfig[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingKey, setEditingKey] = useState<string | null>(null);
  const [editValue, setEditValue] = useState('');
  const [editDesc, setEditDesc] = useState('');
  const [saving, setSaving] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const result = await getConfigs({ page: 0, size: 100 });
      setItems(result.content);
    } catch {
      addToast('error', 'Failed to load configuration');
    } finally {
      setLoading(false);
    }
  }, [addToast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  useEffect(() => {
    if (editingKey && inputRef.current) {
      inputRef.current.focus();
      inputRef.current.select();
    }
  }, [editingKey]);

  const startEdit = (item: SystemConfig) => {
    setEditingKey(item.configKey);
    setEditValue(item.configValue);
    setEditDesc(item.configDesc ?? '');
  };

  const cancelEdit = () => {
    setEditingKey(null);
    setEditValue('');
    setEditDesc('');
  };

  const saveEdit = async () => {
    if (!editingKey) return;
    setSaving(true);
    try {
      await updateConfig(editingKey, { configValue: editValue, configDesc: editDesc || undefined });
      addToast('success', `Configuration "${editingKey}" updated`);
      setEditingKey(null);
      fetchData();
    } catch (err: any) {
      addToast('error', err.response?.data?.message || 'Failed to save configuration');
    } finally {
      setSaving(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') saveEdit();
    if (e.key === 'Escape') cancelEdit();
  };

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-slate-100">
            <Settings className="h-5 w-5 text-slate-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">System Configuration</h1>
            <p className="mt-0.5 text-sm text-gray-500">Manage application settings and system parameters</p>
          </div>
        </div>
        <button
          onClick={fetchData}
          disabled={loading}
          className="inline-flex items-center gap-2 rounded-lg border border-gray-300 px-4 py-2.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
        >
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {/* Config cards */}
      {loading ? (
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="animate-pulse rounded-xl border border-gray-200 bg-white p-5">
              <div className="mb-3 h-4 w-1/3 rounded bg-gray-200" />
              <div className="mb-2 h-5 w-2/3 rounded bg-gray-200" />
              <div className="h-3 w-1/2 rounded bg-gray-100" />
            </div>
          ))}
        </div>
      ) : items.length === 0 ? (
        <div className="rounded-xl border border-gray-200 bg-white px-6 py-12 text-center">
          <Settings className="mx-auto mb-3 h-10 w-10 text-gray-300" />
          <p className="text-sm text-gray-400">No configuration entries found.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          {items.map((item) => {
            const isEditing = editingKey === item.configKey;
            return (
              <div
                key={item.configKey}
                className={`rounded-xl border bg-white p-5 shadow-sm transition-all ${
                  isEditing ? 'border-brand-300 ring-2 ring-brand-500/20' : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                <div className="mb-2 flex items-start justify-between">
                  <div className="min-w-0 flex-1">
                    <p className="text-xs font-semibold uppercase tracking-wider text-gray-400">
                      {item.configKey}
                    </p>
                  </div>
                  {!isEditing && (
                    <button
                      onClick={() => startEdit(item)}
                      className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
                      title="Edit value"
                    >
                      <Pencil className="h-3.5 w-3.5" />
                    </button>
                  )}
                </div>

                {isEditing ? (
                  <div className="space-y-2">
                    <input
                      ref={inputRef}
                      type="text"
                      value={editValue}
                      onChange={(e) => setEditValue(e.target.value)}
                      onKeyDown={handleKeyDown}
                      className="block w-full rounded-lg border border-brand-300 px-3 py-2 text-sm text-gray-900 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
                      disabled={saving}
                    />
                    <input
                      type="text"
                      value={editDesc}
                      onChange={(e) => setEditDesc(e.target.value)}
                      onKeyDown={handleKeyDown}
                      placeholder="Description (optional)"
                      className="block w-full rounded-lg border border-gray-300 px-3 py-1.5 text-xs text-gray-600 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
                      disabled={saving}
                    />
                    <div className="flex items-center gap-2">
                      <button
                        onClick={saveEdit}
                        disabled={saving}
                        className="inline-flex items-center gap-1 rounded-md bg-blue-600 px-3 py-1.5 text-xs font-medium text-white transition-colors hover:bg-blue-700 disabled:opacity-50"
                      >
                        {saving ? (
                          <div className="h-3 w-3 animate-spin rounded-full border-2 border-white border-t-transparent" />
                        ) : (
                          <Check className="h-3 w-3" />
                        )}
                        Save
                      </button>
                      <button
                        onClick={cancelEdit}
                        disabled={saving}
                        className="inline-flex items-center gap-1 rounded-md border border-gray-300 px-3 py-1.5 text-xs font-medium text-gray-600 transition-colors hover:bg-gray-50"
                      >
                        <X className="h-3 w-3" />
                        Cancel
                      </button>
                    </div>
                  </div>
                ) : (
                  <>
                    <p className="text-sm font-semibold text-gray-900">{item.configValue}</p>
                    {item.configDesc && (
                      <p className="mt-1 text-xs text-gray-500">{item.configDesc}</p>
                    )}
                    <div className="mt-2 flex items-center gap-2 text-xs text-gray-400">
                      {item.updatedBy && <span>Updated by {item.updatedBy}</span>}
                      {item.updatedBy && <span>&middot;</span>}
                      <span>{item.updatedTs}</span>
                    </div>
                  </>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

export default ConfigPage;
