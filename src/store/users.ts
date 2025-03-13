import { create } from 'zustand';
import { User, userAPI, CreateUserDTO, UpdateUserDTO } from '../services/api/users';

interface UserState {
  users: User[];
  isLoading: boolean;
  error: string | null;
  fetchUsers: () => Promise<void>;
  createUser: (data: CreateUserDTO) => Promise<User>;
  updateUser: (id: string, data: UpdateUserDTO) => Promise<User>;
}

export const useUserStore = create<UserState>((set) => ({
  users: [],
  isLoading: false,
  error: null,
  
  fetchUsers: async () => {
    set({ isLoading: true, error: null });
    try {
      const users = await userAPI.findAll();
      set({ users, error: null });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Erro ao carregar usuários';
      set({ error: message });
    } finally {
      set({ isLoading: false });
    }
  },

  createUser: async (data) => {
    try {
      const user = await userAPI.create(data);
      set(state => ({
        users: [user, ...state.users]
      }));
      return user;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Erro ao criar usuário';
      set({ error: message });
      throw error;
    }
  },

  updateUser: async (id, data) => {
    try {
      const user = await userAPI.update(id, data);
      set(state => ({
        users: state.users.map(u => u.id === id ? user : u)
      }));
      return user;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Erro ao atualizar usuário';
      set({ error: message });
      throw error;
    }
  }
}));