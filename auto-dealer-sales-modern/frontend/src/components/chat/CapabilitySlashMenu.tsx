import { useEffect, useMemo, useRef, useState } from 'react';
import type { AgentCapability } from '@/api/agent';
import { ShieldAlert } from 'lucide-react';

interface Props {
  /** Filter text — what the user typed AFTER the leading "/". */
  filter: string;
  capabilities: AgentCapability[];
  onPick: (prompt: string) => void;
  onClose: () => void;
}

/**
 * Floating dropdown that opens when the user types "/" in the chat input.
 * Each capability surfaces its FIRST example prompt as the insertable line —
 * the rationale being that a power user typing "/" wants speed, not a
 * branching menu of variants. (The Atlas modal is the right place for the
 * full multi-prompt browse.)
 *
 * Keyboard: ↑↓ to navigate, Enter to insert, Esc to close.
 */
export function CapabilitySlashMenu({ filter, capabilities, onPick, onClose }: Props) {
  const [activeIdx, setActiveIdx] = useState(0);
  const listRef = useRef<HTMLDivElement>(null);

  // Score each capability by name + first-prompt overlap with the filter.
  // Cheap fuzzy: substring match wins, otherwise startsWith on any token.
  const filtered = useMemo(() => {
    const q = filter.trim().toLowerCase();
    const candidates = capabilities.filter((c) => c.examplePrompts.length > 0);
    if (!q) return candidates.slice(0, 12);
    return candidates
      .filter(
        (c) =>
          c.displayName.toLowerCase().includes(q) ||
          c.examplePrompts[0].toLowerCase().includes(q) ||
          c.category.toLowerCase().includes(q),
      )
      .slice(0, 12);
  }, [filter, capabilities]);

  // Reset highlight when filter changes
  useEffect(() => {
    setActiveIdx(0);
  }, [filter]);

  // Keep highlighted item in view
  useEffect(() => {
    const el = listRef.current?.querySelector(`[data-slash-idx="${activeIdx}"]`);
    el?.scrollIntoView({ block: 'nearest' });
  }, [activeIdx]);

  // Bind global key handlers while open. Parent component is responsible
  // for un-mounting us when the user clears or sends; we just manage the
  // ↑↓/Enter/Esc events.
  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        setActiveIdx((i) => Math.min(filtered.length - 1, i + 1));
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        setActiveIdx((i) => Math.max(0, i - 1));
      } else if (e.key === 'Enter') {
        if (filtered.length === 0) return;
        e.preventDefault();
        const cap = filtered[activeIdx];
        if (cap) onPick(cap.examplePrompts[0]);
      } else if (e.key === 'Escape') {
        e.preventDefault();
        onClose();
      }
    }
    window.addEventListener('keydown', onKey, true);
    return () => window.removeEventListener('keydown', onKey, true);
  }, [filtered, activeIdx, onPick, onClose]);

  if (filtered.length === 0) {
    return (
      <div className="absolute bottom-full left-0 right-0 mb-1 rounded-xl border border-gray-200 bg-white p-3 shadow-xl">
        <p className="text-xs text-gray-500">
          No capabilities match "<span className="font-mono">{filter}</span>". Press
          <kbd className="mx-1 rounded border border-gray-300 bg-gray-50 px-1 font-mono text-[10px]">Esc</kbd>
          to close, or open the Capability Atlas (<kbd className="mx-1 rounded border border-gray-300 bg-gray-50 px-1 font-mono text-[10px]">?</kbd> icon) to browse.
        </p>
      </div>
    );
  }

  return (
    <div className="absolute bottom-full left-0 right-0 mb-1 max-h-72 overflow-hidden rounded-xl border border-gray-200 bg-white shadow-xl">
      <div className="border-b border-gray-100 bg-gray-50 px-3 py-1.5">
        <p className="text-[10px] uppercase tracking-wide text-gray-500">
          {filtered.length} {filtered.length === 1 ? 'match' : 'matches'} — ↑↓ to navigate, Enter to insert, Esc to close
        </p>
      </div>
      <div ref={listRef} className="max-h-60 overflow-y-auto py-1">
        {filtered.map((c, idx) => (
          <button
            key={c.id}
            data-slash-idx={idx}
            onMouseEnter={() => setActiveIdx(idx)}
            onClick={() => onPick(c.examplePrompts[0])}
            className={`flex w-full items-start gap-2 px-3 py-2 text-left transition-colors ${
              idx === activeIdx ? 'bg-violet-50' : 'bg-white hover:bg-gray-50'
            }`}
          >
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-1.5">
                <p
                  className={`truncate text-[13px] font-semibold ${
                    idx === activeIdx ? 'text-violet-800' : 'text-gray-800'
                  }`}
                >
                  {c.displayName}
                </p>
                {c.requiresProposal && (
                  <ShieldAlert className="h-3 w-3 flex-shrink-0 text-amber-600" />
                )}
                <span className="text-[10px] uppercase tracking-wide text-gray-400">
                  {c.category}
                </span>
              </div>
              <p className="mt-0.5 truncate text-[11px] text-gray-500">
                {c.examplePrompts[0]}
              </p>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}
