type BadgeStatus = 'active' | 'inactive' | 'expired' | 'pending';

export interface StatusBadgeProps {
  status: BadgeStatus;
  label?: string;
}

const statusStyles: Record<BadgeStatus, { dot: string; bg: string; text: string }> = {
  active: {
    dot: 'bg-emerald-500',
    bg: 'bg-emerald-50',
    text: 'text-emerald-700',
  },
  inactive: {
    dot: 'bg-red-500',
    bg: 'bg-red-50',
    text: 'text-red-700',
  },
  expired: {
    dot: 'bg-gray-400',
    bg: 'bg-gray-100',
    text: 'text-gray-600',
  },
  pending: {
    dot: 'bg-yellow-500',
    bg: 'bg-yellow-50',
    text: 'text-yellow-700',
  },
};

const defaultLabels: Record<BadgeStatus, string> = {
  active: 'Active',
  inactive: 'Inactive',
  expired: 'Expired',
  pending: 'Pending',
};

export default function StatusBadge({ status, label }: StatusBadgeProps) {
  const style = statusStyles[status];
  const displayLabel = label ?? defaultLabels[status];

  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium ${style.bg} ${style.text}`}
    >
      <span className={`h-1.5 w-1.5 rounded-full ${style.dot}`} />
      {displayLabel}
    </span>
  );
}
