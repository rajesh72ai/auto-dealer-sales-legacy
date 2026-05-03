import { useEffect, useRef, useState } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import {
  LayoutDashboard,
  Users,
  UserPlus,
  ShoppingCart,
  DollarSign,
  Car,
  Building2,
  FileText,
  Settings,
  ChevronLeft,
  ChevronRight,
  ChevronDown,
  CarFront,
  Percent,
  Gift,
  Calculator,
  ClipboardList,
  Package,
  TrendingUp,
  Landmark,
  BarChart3,
  Warehouse,
  ArrowLeftRight,
  Truck,
  Factory,
  ClipboardCheck,
  MapPin,
  Timer,
  Shield,
  Wrench,
  AlertTriangle,
  PlayCircle,
  UserCog,
  ScrollText,
  Sparkles,
  Lightbulb,
  Activity,
} from 'lucide-react';
import { useAuth } from '@/auth/useAuth';

interface NavItemDef {
  label: string;
  path: string;
  icon: React.ReactNode;
  roles: string[];
}

interface NavGroupDef {
  label: string;
  collapsible: boolean;
  items: NavItemDef[];
}

const iconClass = 'h-5 w-5 flex-shrink-0';

const navGroups: NavGroupDef[] = [
  {
    label: 'Main',
    collapsible: false,
    items: [
      { label: 'Dashboard', path: '/dashboard', icon: <LayoutDashboard className={iconClass} />, roles: ['ADMIN', 'MANAGER', 'SALESPERSON', 'FINANCE', 'CLERK'] },
    ],
  },
  {
    label: 'Operations',
    collapsible: true,
    items: [
      { label: 'Customers', path: '/customers', icon: <Users className={iconClass} />, roles: ['ADMIN', 'MANAGER', 'SALESPERSON', 'FINANCE', 'CLERK'] },
      { label: 'Leads', path: '/leads', icon: <UserPlus className={iconClass} />, roles: ['ADMIN', 'MANAGER', 'SALESPERSON', 'FINANCE', 'CLERK'] },
      { label: 'Deal Pipeline', path: '/deals', icon: <ShoppingCart className={iconClass} />, roles: ['ADMIN', 'MANAGER', 'SALESPERSON', 'FINANCE'] },
      { label: 'Finance Apps', path: '/finance/applications', icon: <DollarSign className={iconClass} />, roles: ['ADMIN', 'MANAGER', 'FINANCE'] },
      { label: 'Loan Calculator', path: '/finance/loan-calculator', icon: <Calculator className={iconClass} />, roles: ['ADMIN', 'MANAGER', 'FINANCE', 'SALESPERSON'] },
      { label: 'Lease Calculator', path: '/finance/lease-calculator', icon: <Calculator className={iconClass} />, roles: ['ADMIN', 'MANAGER', 'FINANCE', 'SALESPERSON'] },
      { label: 'F&I Products', path: '/finance/products', icon: <Package className={iconClass} />, roles: ['ADMIN', 'MANAGER', 'FINANCE'] },
      { label: 'Deal Documents', path: '/finance/documents', icon: <ClipboardList className={iconClass} />, roles: ['ADMIN', 'MANAGER', 'FINANCE', 'SALESPERSON'] },
    ],
  },
  {
    label: 'Vehicles',
    collapsible: true,
    items: [
      { label: 'Inventory', path: '/vehicles', icon: <Car className={iconClass} />, roles: ['ADMIN', 'MANAGER', 'SALESPERSON', 'FINANCE', 'CLERK'] },
      { label: 'Vehicle Aging', path: '/vehicles/aging', icon: <Timer className={iconClass} />, roles: ['ADMIN', 'MANAGER'] },
      { label: 'Floor Plan', path: '/floor-plan', icon: <Landmark className={iconClass} />, roles: ['ADMIN', 'MANAGER', 'FINANCE'] },
      { label: 'FP Interest', path: '/floor-plan/interest', icon: <TrendingUp className={iconClass} />, roles: ['ADMIN', 'MANAGER', 'FINANCE'] },
      { label: 'FP Exposure', path: '/floor-plan/reports', icon: <BarChart3 className={iconClass} />, roles: ['ADMIN', 'MANAGER', 'FINANCE'] },
    ],
  },
  {
    label: 'Inventory',
    collapsible: true,
    items: [
      { label: 'Stock Dashboard', path: '/stock', icon: <Warehouse className={iconClass} />, roles: ['ADMIN', 'MANAGER'] },
      { label: 'Positions', path: '/stock/positions', icon: <BarChart3 className={iconClass} />, roles: ['ADMIN', 'MANAGER'] },
      { label: 'Adjustments', path: '/stock/adjustments', icon: <ClipboardList className={iconClass} />, roles: ['ADMIN', 'MANAGER'] },
      { label: 'Transfers', path: '/stock/transfers', icon: <ArrowLeftRight className={iconClass} />, roles: ['ADMIN', 'MANAGER'] },
      { label: 'Valuation', path: '/stock/valuation', icon: <DollarSign className={iconClass} />, roles: ['ADMIN', 'MANAGER'] },
      { label: 'Reconciliation', path: '/stock/reconciliation', icon: <ClipboardCheck className={iconClass} />, roles: ['ADMIN', 'MANAGER'] },
    ],
  },
  {
    label: 'Supply Chain',
    collapsible: true,
    items: [
      { label: 'Production Orders', path: '/production/orders', icon: <Factory className={iconClass} />, roles: ['ADMIN', 'MANAGER'] },
      { label: 'Shipments', path: '/shipments', icon: <Truck className={iconClass} />, roles: ['ADMIN', 'MANAGER'] },
      { label: 'PDI Schedule', path: '/pdi', icon: <ClipboardCheck className={iconClass} />, roles: ['ADMIN', 'MANAGER'] },
    ],
  },
  {
    label: 'Registration',
    collapsible: true,
    items: [
      { label: 'Registrations', path: '/registration', icon: <FileText className={iconClass} />, roles: ['ADMIN', 'MANAGER', 'FINANCE'] },
      { label: 'Warranty', path: '/warranty', icon: <Shield className={iconClass} />, roles: ['ADMIN', 'MANAGER', 'SALESPERSON', 'FINANCE', 'CLERK'] },
      { label: 'Claims', path: '/warranty-claims', icon: <Wrench className={iconClass} />, roles: ['ADMIN', 'MANAGER', 'FINANCE'] },
      { label: 'Claims Report', path: '/warranty-report', icon: <BarChart3 className={iconClass} />, roles: ['ADMIN', 'MANAGER'] },
      { label: 'Recalls', path: '/recall', icon: <AlertTriangle className={iconClass} />, roles: ['ADMIN', 'MANAGER'] },
    ],
  },
  {
    label: 'Batch',
    collapsible: true,
    items: [
      { label: 'Batch Jobs', path: '/batch/jobs', icon: <PlayCircle className={iconClass} />, roles: ['ADMIN', 'MANAGER'] },
      { label: 'Batch Reports', path: '/batch/reports', icon: <BarChart3 className={iconClass} />, roles: ['ADMIN', 'MANAGER'] },
    ],
  },
  {
    label: 'Admin',
    collapsible: true,
    items: [
      { label: 'Dealers', path: '/admin/dealers', icon: <Building2 className={iconClass} />, roles: ['ADMIN'] },
      { label: 'Models', path: '/admin/models', icon: <Car className={iconClass} />, roles: ['ADMIN'] },
      { label: 'Pricing', path: '/admin/pricing', icon: <DollarSign className={iconClass} />, roles: ['ADMIN'] },
      { label: 'Tax Rates', path: '/admin/tax-rates', icon: <Percent className={iconClass} />, roles: ['ADMIN'] },
      { label: 'Incentives', path: '/admin/incentives', icon: <Gift className={iconClass} />, roles: ['ADMIN'] },
      { label: 'Lot Locations', path: '/admin/lot-locations', icon: <MapPin className={iconClass} />, roles: ['ADMIN'] },
      { label: 'Salespersons', path: '/admin/salespersons', icon: <Users className={iconClass} />, roles: ['ADMIN'] },
      { label: 'Users', path: '/admin/users', icon: <UserCog className={iconClass} />, roles: ['ADMIN'] },
      { label: 'Audit Log', path: '/admin/audit-log', icon: <ScrollText className={iconClass} />, roles: ['ADMIN'] },
      { label: 'AI Usage & Cost', path: '/admin/agent-usage', icon: <Sparkles className={iconClass} />, roles: ['ADMIN'] },
      { label: 'AI Tool-Call Trace', path: '/admin/agent-trace', icon: <Activity className={iconClass} />, roles: ['ADMIN', 'MANAGER'] },
      { label: 'AI Capability Backlog', path: '/admin/capability-gaps', icon: <Lightbulb className={iconClass} />, roles: ['ADMIN'] },
      { label: 'Config', path: '/admin/config', icon: <Settings className={iconClass} />, roles: ['ADMIN'] },
    ],
  },
];

function Sidebar() {
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [expandedGroups, setExpandedGroups] = useState<Set<string>>(new Set(['Main', 'Operations']));
  const { user } = useAuth();
  const location = useLocation();
  const userRole = user?.userType ?? '';

  const filteredGroups = navGroups
    .map((group) => ({
      ...group,
      items: group.items.filter((item) => item.roles.includes(userRole)),
    }))
    .filter((group) => group.items.length > 0);

  // Auto-expand group that contains the active route — only on route changes
  const prevPathRef = useRef(location.pathname);
  useEffect(() => {
    if (prevPathRef.current !== location.pathname) {
      prevPathRef.current = location.pathname;
      const activeGroup = filteredGroups.find((g) =>
        g.items.some((item) => location.pathname === item.path || location.pathname.startsWith(item.path + '/'))
      );
      if (activeGroup && !expandedGroups.has(activeGroup.label)) {
        setExpandedGroups((prev) => new Set([...prev, activeGroup.label]));
      }
    }
  }, [location.pathname]);

  const toggleGroup = (label: string) => {
    setExpandedGroups((prev) => {
      const next = new Set(prev);
      if (next.has(label)) {
        next.delete(label);
      } else {
        next.add(label);
      }
      return next;
    });
  };

  return (
    <aside
      className={`
        flex flex-col bg-sidebar text-white transition-all duration-300 ease-in-out
        ${sidebarCollapsed ? 'w-16' : 'w-64'}
      `}
    >
      {/* Brand */}
      <div className="flex h-16 items-center gap-3 border-b border-sidebar-border px-4">
        <div className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-lg bg-brand-600">
          <CarFront className="h-5 w-5 text-white" />
        </div>
        {!sidebarCollapsed && (
          <div className="min-w-0">
            <h1 className="text-base font-bold tracking-wide text-white">AUTOSALES</h1>
          </div>
        )}
      </div>

      {/* Dealer info */}
      {!sidebarCollapsed && user && (
        <div className="border-b border-sidebar-border px-4 py-3">
          <p className="truncate text-xs font-medium text-slate-400">DEALER</p>
          <p className="truncate text-sm font-semibold text-slate-200">
            {user.dealerCode}
          </p>
        </div>
      )}

      {/* Navigation */}
      <nav className="flex-1 overflow-y-auto px-2 py-3">
        {filteredGroups.map((group) => {
          const isExpanded = !group.collapsible || expandedGroups.has(group.label);
          const hasActiveItem = group.items.some(
            (item) => location.pathname === item.path || location.pathname.startsWith(item.path + '/')
          );

          return (
            <div key={group.label} className="mb-1">
              {!sidebarCollapsed && group.collapsible ? (
                <button
                  onClick={() => toggleGroup(group.label)}
                  className={`flex w-full items-center justify-between rounded-lg px-2 py-1.5 text-[11px] font-semibold uppercase tracking-wider transition-colors
                    ${hasActiveItem && !isExpanded
                      ? 'text-brand-400'
                      : 'text-slate-500 hover:text-slate-300'
                    }`}
                >
                  <span>{group.label}</span>
                  <ChevronDown
                    className={`h-3.5 w-3.5 transition-transform duration-200 ${isExpanded ? '' : '-rotate-90'}`}
                  />
                </button>
              ) : !sidebarCollapsed ? (
                <p className="mb-1 px-2 py-1.5 text-[11px] font-semibold uppercase tracking-wider text-slate-500">
                  {group.label}
                </p>
              ) : null}

              <div
                className={`overflow-hidden transition-all duration-200 ease-in-out ${
                  isExpanded ? 'max-h-[500px] opacity-100' : sidebarCollapsed ? 'max-h-[500px] opacity-100' : 'max-h-0 opacity-0'
                }`}
              >
                <ul className="space-y-0.5">
                  {group.items.map((item) => (
                    <li key={item.path}>
                      <NavLink
                        to={item.path}
                        className={({ isActive }) =>
                          `group flex items-center gap-3 rounded-lg px-2.5 py-2 text-sm font-medium transition-colors
                          ${isActive
                            ? 'bg-brand-600/20 text-brand-400'
                            : 'text-slate-400 hover:bg-sidebar-hover hover:text-slate-200'
                          }
                          ${sidebarCollapsed ? 'justify-center' : ''}
                        `}
                        title={sidebarCollapsed ? item.label : undefined}
                      >
                        {item.icon}
                        {!sidebarCollapsed && <span>{item.label}</span>}
                      </NavLink>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          );
        })}
      </nav>

      {/* Collapse toggle */}
      <div className="border-t border-sidebar-border p-2">
        <button
          onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
          className="flex w-full items-center justify-center rounded-lg p-2 text-slate-400 transition-colors hover:bg-sidebar-hover hover:text-slate-200"
          aria-label={sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
        >
          {sidebarCollapsed ? (
            <ChevronRight className="h-5 w-5" />
          ) : (
            <ChevronLeft className="h-5 w-5" />
          )}
        </button>
      </div>
    </aside>
  );
}

export default Sidebar;
