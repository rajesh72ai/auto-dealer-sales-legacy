import { createContext, useState, useCallback, type ReactNode } from 'react';
import { login as apiLogin } from '@/api/auth';
import { setAccessToken } from '@/api/axios';
import type { User } from '@/types';

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  login: (userId: string, password: string) => Promise<void>;
  logout: () => void;
}

export const AuthContext = createContext<AuthContextType>({
  user: null,
  isAuthenticated: false,
  login: async () => {},
  logout: () => {},
});

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(() => {
    const stored = sessionStorage.getItem('autosales_user');
    if (stored) {
      // Restore the access token from sessionStorage on page load/refresh
      const token = sessionStorage.getItem('autosales_token');
      if (token) {
        setAccessToken(token);
      }
      return JSON.parse(stored);
    }
    return null;
  });

  const isAuthenticated = user !== null;

  const login = useCallback(async (userId: string, password: string) => {
    const response = await apiLogin(userId, password);
    setAccessToken(response.accessToken);

    const userInfo: User = {
      userId: response.userId,
      userName: response.userName,
      userType: response.userType,
      dealerCode: response.dealerCode,
    };

    setUser(userInfo);
    sessionStorage.setItem('autosales_user', JSON.stringify(userInfo));
    sessionStorage.setItem('autosales_token', response.accessToken);
  }, []);

  const logout = useCallback(() => {
    setAccessToken(null);
    setUser(null);
    sessionStorage.removeItem('autosales_user');
    sessionStorage.removeItem('autosales_token');
  }, []);

  return (
    <AuthContext.Provider value={{ user, isAuthenticated, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}
