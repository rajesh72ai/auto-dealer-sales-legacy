// Client-side export helpers for AI Agent replies.
// PDF generation is delegated to the backend (/api/agent/report/pdf) for reliability.

function timestampSlug(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}-${pad(d.getHours())}${pad(d.getMinutes())}`;
}

function authHeaders(): Record<string, string> {
  const token = sessionStorage.getItem('autosales_token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

function triggerDownload(filename: string, blob: Blob) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

export function downloadMarkdown(content: string, when: Date = new Date()) {
  const header = `# AutoSales Agent Report\n\n_Generated ${when.toLocaleString()}_\n\n---\n\n`;
  const blob = new Blob([header + content], { type: 'text/markdown;charset=utf-8' });
  triggerDownload(`autosales-agent-${timestampSlug(when)}.md`, blob);
}

export async function downloadPdf(
  content: string,
  when: Date = new Date(),
  userPrompt?: string,
): Promise<string> {
  const filename = `autosales-agent-${timestampSlug(when)}.pdf`;
  const response = await fetch('/api/agent/report/pdf', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...authHeaders(),
    },
    body: JSON.stringify({
      markdown: content,
      generatedAt: when.toLocaleString(),
      userPrompt: userPrompt ?? '',
    }),
  });
  if (!response.ok) {
    throw new Error(`PDF render failed: ${response.status} ${response.statusText}`);
  }
  const blob = await response.blob();
  triggerDownload(filename, blob);
  return filename;
}

// Derive a meaningful email subject from the user's prompt. Recognizes the
// built-in workflow recipes so the recipient sees what kind of report they're
// getting (e.g. "Morning Briefing for DLR01"), not just "AutoSales Agent Report".
function deriveSubject(userPrompt: string | undefined, when: Date): string {
  const prompt = (userPrompt ?? '').trim();
  const dateStr = when.toLocaleDateString();
  if (!prompt) return `AutoSales Agent Report — ${dateStr}`;

  const patterns: Array<{ re: RegExp; label: (m: RegExpMatchArray) => string }> = [
    { re: /deal health check (?:on )?(\S+)/i, label: (m) => `Deal Health Check — ${m[1]}` },
    { re: /customer 360 (?:for )?(?:customer )?(\S+)/i, label: (m) => `Customer 360 — ${m[1]}` },
    { re: /morning briefing (?:for )?(\S+)/i, label: (m) => `Morning Briefing — ${m[1]}` },
    { re: /inventory aging triage (?:for )?(\S+)/i, label: (m) => `Inventory Aging Triage — ${m[1]}` },
    { re: /qualify lead (\S+)/i, label: (m) => `Lead-to-Deal Funnel — Lead ${m[1]}` },
    { re: /finance (?:deal )?review (?:for )?(?:deal )?(\S+)/i, label: (m) => `Finance Deal Review — ${m[1]}` },
    { re: /rebalance inventory/i, label: () => `Inventory Rebalance` },
    { re: /recall impact report (?:for )?(\S+)/i, label: (m) => `Recall Impact Report — ${m[1]}` },
  ];

  for (const p of patterns) {
    const m = prompt.match(p.re);
    if (m) return `AutoSales — ${p.label(m)} (${dateStr})`;
  }

  // Generic fallback: use the first ~60 chars of the prompt
  const cleaned = prompt.replace(/\s+/g, ' ');
  const snippet = cleaned.length > 60 ? cleaned.slice(0, 57) + '…' : cleaned;
  // Strip trailing punctuation for cleanliness
  const snippetClean = snippet.replace(/[?.!,;:]+$/, '');
  return `AutoSales Agent: ${snippetClean} (${dateStr})`;
}

// Download the PDF, then open the user's default mail client with a short body
// referencing the attachment. User drags the downloaded PDF into the draft.
// (mailto: cannot attach files — hard OS/browser limit.)
export async function emailWithPdfAttachment(
  content: string,
  when: Date = new Date(),
  userPrompt?: string,
) {
  const filename = await downloadPdf(content, when, userPrompt);
  const subject = deriveSubject(userPrompt, when);
  const body =
    `Please find the AutoSales Agent report attached: ${filename}\n\n` +
    `The PDF was just downloaded to your Downloads folder. Attach it to this email before sending.`;
  const url = `mailto:?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
  window.location.href = url;
  return filename;
}

export async function copyToClipboard(content: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(content);
    return true;
  } catch {
    return false;
  }
}
