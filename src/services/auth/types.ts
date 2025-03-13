export interface User {
  id: string;
  email: string;
  name?: string;
  avatar_url?: string;
  role: 'admin' | 'user';
  tenant_id: string;
}

export interface AuthResponse {
  user: User | null;
  session: any | null;
  error?: Error;
}

export interface AuthProvider {
  signIn(email: string, password: string): Promise<AuthResponse>;
  signUp(email: string, password: string, data?: Record<string, any>): Promise<AuthResponse>;
  signOut(): Promise<void>;
  resetPassword(email: string): Promise<void>;
  updatePassword(password: string): Promise<void>;
  getUser(): Promise<User | null>;
}