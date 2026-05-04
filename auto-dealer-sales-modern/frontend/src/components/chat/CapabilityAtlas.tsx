import { useMemo, useState } from 'react';
import {
  X,
  Search,
  Car,
  UserCircle,
  TrendingUp,
  Banknote,
  ShieldCheck,
  Sparkles,
  FileText,
  Monitor,
  Shuffle,
  ShieldAlert,
} from 'lucide-react';
import type { AgentCapability, AutoDiscoveredTile } from '@/api/agent';

interface Props {
  isOpen: boolean;
  onClose: () => void;
  capabilities: AgentCapability[];
  autoDiscoveredTile: AutoDiscoveredTile | null;
  personaRole: string | null;
  onPickPrompt: (prompt: string) => void;
}

// Map yaml category → icon + Tailwind classes. Adding a new category here is
// a one-line change; keeping this colocated with the modal so the rendering
// language stays declarative.
const CATEGORY_STYLE: Record<
  string,
  { Icon: typeof Car; accent: string; label: string }
> = {
  INVENTORY: { Icon: Car, accent: 'border-blue-200 bg-blue-50 text-blue-700', label: 'Inventory' },
  CUSTOMERS: { Icon: UserCircle, accent: 'border-emerald-200 bg-emerald-50 text-emerald-700', label: 'Customers & Leads' },
  DEALS: { Icon: TrendingUp, accent: 'border-violet-200 bg-violet-50 text-violet-700', label: 'Deals' },
  FINANCE: { Icon: Banknote, accent: 'border-amber-200 bg-amber-50 text-amber-700', label: 'Finance' },
  WARRANTY: { Icon: ShieldCheck, accent: 'border-rose-200 bg-rose-50 text-rose-700', label: 'Warranty & Recalls' },
  INCENTIVES: { Icon: Sparkles, accent: 'border-fuchsia-200 bg-fuchsia-50 text-fuchsia-700', label: 'Incentives' },
  REPORTS: { Icon: FileText, accent: 'border-slate-200 bg-slate-50 text-slate-700', label: 'Reports' },
  ADMIN: { Icon: Monitor, accent: 'border-zinc-200 bg-zinc-50 text-zinc-700', label: 'Admin' },
  CALC: { Icon: Banknote, accent: 'border-amber-200 bg-amber-50 text-amber-700', label: 'Calculators' },
};

const FALLBACK_STYLE = { Icon: Sparkles, accent: 'border-gray-200 bg-gray-50 text-gray-700', label: 'Other' };

export function CapabilityAtlas({
  isOpen,
  onClose,
  capabilities,
  autoDiscoveredTile,
  personaRole,
  onPickPrompt,
}: Props) {
  const [query, setQuery] = useState('');

  // Filter + group by category. Within a category, capabilities keep their
  // server-supplied displayPriority order (persona-aware).
  const grouped = useMemo(() => {
    const q = query.trim().toLowerCase();
    const filtered = q
      ? capabilities.filter(
          (c) =>
            c.displayName.toLowerCase().includes(q) ||
            c.description.toLowerCase().includes(q) ||
            c.examplePrompts.some((p) => p.toLowerCase().includes(q)) ||
            c.backedBy.some((b) => b.toLowerCase().includes(q)),
        )
      : capabilities;
    const buckets = new Map<string, AgentCapability[]>();
    for (const c of filtered) {
      const arr = buckets.get(c.category) ?? [];
      arr.push(c);
      buckets.set(c.category, arr);
    }
    return Array.from(buckets.entries());
  }, [capabilities, query]);

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 p-4 animate-in fade-in duration-150"
      onClick={onClose}
    >
      <div
        className="flex max-h-[85vh] w-full max-w-3xl flex-col overflow-hidden rounded-2xl bg-white shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-start justify-between border-b border-gray-200 bg-gradient-to-r from-violet-50 to-indigo-50 px-5 py-4">
          <div>
            <h2 className="text-lg font-semibold text-gray-900">What can the agent do?</h2>
            <p className="mt-0.5 text-xs text-gray-600">
              Click any prompt below to load it. Curated capabilities are organized by area;
              {personaRole ? ` ordered for your role (${personaRole}).` : ' default ordering.'}
            </p>
          </div>
          <button
            onClick={onClose}
            className="rounded-lg p-1.5 text-gray-500 transition-colors hover:bg-gray-200 hover:text-gray-800"
            title="Close"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        {/* Search */}
        <div className="border-b border-gray-200 bg-white px-5 py-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <input
              autoFocus
              type="search"
              placeholder="Search capabilities, prompts, or tool names…"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="w-full rounded-lg border border-gray-200 bg-white py-2 pl-9 pr-3 text-sm text-gray-800 placeholder-gray-400 focus:border-violet-400 focus:outline-none focus:ring-1 focus:ring-violet-400"
            />
          </div>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto px-5 py-4">
          {grouped.length === 0 && (
            <p className="mt-4 text-center text-sm text-gray-500">
              No capabilities match "{query}". Try a broader term, or use the
              auto-discovered endpoint surface below.
            </p>
          )}

          {grouped.map(([category, items]) => {
            const style = CATEGORY_STYLE[category] ?? FALLBACK_STYLE;
            const Icon = style.Icon;
            return (
              <section key={category} className="mb-6 last:mb-0">
                <div className="mb-2 flex items-center gap-2">
                  <div
                    className={`flex h-7 w-7 items-center justify-center rounded-lg border ${style.accent}`}
                  >
                    <Icon className="h-3.5 w-3.5" />
                  </div>
                  <h3 className="text-xs font-semibold uppercase tracking-wide text-gray-700">
                    {style.label}
                  </h3>
                  <span className="text-[10px] text-gray-400">{items.length}</span>
                </div>
                <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
                  {items.map((c) => (
                    <div
                      key={c.id}
                      className="rounded-xl border border-gray-200 bg-white p-3 transition-colors hover:border-violet-300 hover:bg-violet-50/40"
                    >
                      <div className="flex items-center justify-between gap-2">
                        <p className="text-[13px] font-semibold text-gray-800">{c.displayName}</p>
                        {c.requiresProposal && (
                          <span
                            className="inline-flex items-center gap-1 rounded-full border border-amber-200 bg-amber-50 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-amber-700"
                            title="Write action — agent will propose; you confirm before commit"
                          >
                            <ShieldAlert className="h-2.5 w-2.5" /> Confirm
                          </span>
                        )}
                      </div>
                      <p className="mt-1 line-clamp-2 text-[11px] leading-snug text-gray-500">
                        {c.description}
                      </p>
                      {c.examplePrompts.length > 0 && (
                        <div className="mt-2 flex flex-wrap gap-1">
                          {c.examplePrompts.map((prompt, i) => (
                            <button
                              key={i}
                              onClick={() => {
                                onPickPrompt(prompt);
                                onClose();
                              }}
                              className="rounded-md border border-violet-200 bg-violet-50 px-2 py-1 text-left text-[11px] leading-tight text-violet-800 transition-colors hover:border-violet-400 hover:bg-violet-100"
                              title="Load this prompt into the chat input"
                            >
                              {prompt}
                            </button>
                          ))}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </section>
            );
          })}

          {/* Auto-discovered tile — separate from curated, per the design
              decision to expose the long tail honestly without burying it. */}
          {autoDiscoveredTile && !query && (
            <section className="mb-2 rounded-xl border-2 border-dashed border-indigo-200 bg-indigo-50/40 p-3">
              <div className="mb-2 flex items-center gap-2">
                <div className="flex h-7 w-7 items-center justify-center rounded-lg border border-indigo-200 bg-indigo-50 text-indigo-700">
                  <Shuffle className="h-3.5 w-3.5" />
                </div>
                <h3 className="text-xs font-semibold uppercase tracking-wide text-indigo-700">
                  Beyond the curated catalog
                </h3>
              </div>
              <p className="text-[13px] font-semibold text-gray-800">
                {autoDiscoveredTile.displayName}
              </p>
              <p className="mt-1 text-[11px] leading-snug text-gray-600">
                {autoDiscoveredTile.description}
              </p>
              <div className="mt-2 flex flex-wrap gap-1">
                {autoDiscoveredTile.examplePrompts.map((prompt, i) => (
                  <button
                    key={i}
                    onClick={() => {
                      onPickPrompt(prompt);
                      onClose();
                    }}
                    className="rounded-md border border-indigo-200 bg-white px-2 py-1 text-left text-[11px] leading-tight text-indigo-700 transition-colors hover:border-indigo-400 hover:bg-indigo-50"
                  >
                    {prompt}
                  </button>
                ))}
              </div>
            </section>
          )}
        </div>

        {/* Footer */}
        <div className="border-t border-gray-200 bg-gray-50 px-5 py-2">
          <p className="text-[10px] text-gray-500">
            Tip: type <kbd className="rounded border border-gray-300 bg-white px-1 font-mono text-[10px]">/</kbd> in the input to open a quick capability menu without leaving the chat.
          </p>
        </div>
      </div>
    </div>
  );
}
