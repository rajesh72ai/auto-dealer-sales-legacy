/** System user info returned from the API */
export interface SystemUserInfo {
  userId: string;
  userName: string;
  userType: string;       // A=Admin, M=Manager, S=Sales, F=Finance, C=Clerk
  dealerCode: string;
  activeFlag: string;     // Y or N
  lockedFlag: string;     // Y or N
  failedAttempts: number;
  lastLoginTs: string | null;
  createdTs: string;
  updatedTs: string;
}

/** Request payload for creating a new user */
export interface CreateUserRequest {
  userId: string;
  userName: string;
  password: string;
  userType: string;
  dealerCode: string;
  activeFlag: string;
}

/** Request payload for updating an existing user (no password field) */
export interface UpdateUserRequest {
  userName: string;
  userType: string;
  dealerCode: string;
  activeFlag: string;
}
