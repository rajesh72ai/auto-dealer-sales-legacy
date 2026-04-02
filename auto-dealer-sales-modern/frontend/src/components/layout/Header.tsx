import { useLocation, Link } from 'react-router-dom';
import { LogOut, ChevronRight, User as UserIcon } from 'lucide-react';
import { useAuth } from '@/auth/useAuth';

const routeLabels: Record<string, string> = {
  dashboard: 'Dashboard',
  customers: 'Customers',
  sales: 'Sales',
  finance: 'Finance',
  vehicles: 'Vehicles',
  'floor-plan': 'Floor Plan',
  registration: 'Registration',
  admin: 'Admin',
  dealers: 'Dealers',
  models: 'Models',
  pricing: 'Pricing',
  'tax-rates': 'Tax Rates',
  incentives: 'Incentives',
  config: 'Configuration',
  salespersons: 'Salespersons',
};

function roleBadgeColor(role: string): string {
  switch (role) {
    case 'ADMIN':
      return 'bg-red-100 text-red-700';
    case 'MANAGER':
      return 'bg-purple-100 text-purple-700';
    case 'FINANCE':
      return 'bg-green-100 text-green-700';
    case 'SALESPERSON':
      return 'bg-blue-100 text-blue-700';
    case 'CLERK':
      return 'bg-amber-100 text-amber-700';
    default:
      return 'bg-gray-100 text-gray-700';
  }
}

function Header() {
  const { user, logout } = useAuth();
  const location = useLocation();

  const segments = location.pathname.split('/').filter(Boolean);

  return (
    <header className="flex h-16 items-center justify-between border-b border-gray-200 bg-white px-6">
      {/* Breadcrumb */}
      <nav className="flex items-center gap-1.5 text-sm">
        <Link
          to="/dashboard"
          className="font-medium text-gray-500 transition-colors hover:text-brand-600"
        >
          Home
        </Link>
        {segments.map((segment, index) => {
          const path = '/' + segments.slice(0, index + 1).join('/');
          const label = routeLabels[segment] ?? segment;
          const isLast = index === segments.length - 1;

          return (
            <span key={path} className="flex items-center gap-1.5">
              <ChevronRight className="h-3.5 w-3.5 text-gray-400" />
              {isLast ? (
                <span className="font-semibold text-gray-900">{label}</span>
              ) : (
                <Link
                  to={path}
                  className="font-medium text-gray-500 transition-colors hover:text-brand-600"
                >
                  {label}
                </Link>
              )}
            </span>
          );
        })}
      </nav>

      {/* Right side */}
      <div className="flex items-center gap-4">
        {user && (
          <>
            <div className="flex items-center gap-2.5">
              <div className="flex h-8 w-8 items-center justify-center rounded-full bg-brand-100 text-brand-700">
                <UserIcon className="h-4 w-4" />
              </div>
              <div className="hidden sm:block">
                <p className="text-sm font-semibold leading-tight text-gray-900">
                  {user.userName}
                </p>
                <p className="text-xs text-gray-500">{user.dealerCode}</p>
              </div>
              <span
                className={`rounded-full px-2 py-0.5 text-[11px] font-semibold ${roleBadgeColor(
                  user.userType,
                )}`}
              >
                {user.userType}
              </span>
            </div>

            <div className="h-6 w-px bg-gray-200" />

            <button
              onClick={logout}
              className="flex items-center gap-1.5 rounded-lg px-2.5 py-1.5 text-sm font-medium text-gray-500 transition-colors hover:bg-gray-100 hover:text-gray-700"
              title="Sign out"
            >
              <LogOut className="h-4 w-4" />
              <span className="hidden sm:inline">Sign Out</span>
            </button>
          </>
        )}
      </div>
    </header>
  );
}

export default Header;
