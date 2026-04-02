import apiClient from './axios';
import type { ApiResponse, AuthResponse } from '@/types';

export async function login(
  userId: string,
  password: string,
): Promise<AuthResponse> {
  const response = await apiClient.post<AuthResponse>(
    '/auth/login',
    { userId, password },
  );
  return response.data;
}

export async function refreshToken(
  token: string,
): Promise<AuthResponse> {
  const response = await apiClient.post<AuthResponse>(
    '/auth/refresh',
    { refreshToken: token },
  );
  return response.data;
}
