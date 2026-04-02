export interface User {
  userId: string;
  userName: string;
  userType: string;
  dealerCode: string;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  userId: string;
  userName: string;
  userType: string;
  dealerCode: string;
}

export interface ApiResponse<T> {
  status: string;
  message: string | null;
  data: T;
  timestamp: string;
}

export interface NavItem {
  label: string;
  path: string;
  icon: string;
  roles: string[];
}

export interface NavGroup {
  label: string;
  items: NavItem[];
}

export interface KpiCard {
  title: string;
  value: string;
  change: number;
  changeLabel: string;
  icon: string;
}
