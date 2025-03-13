import { create } from 'zustand';
import { License } from '../services/api/licenses';
import { licenseAPI } from '../services/api/licenses';

interface SaaSState {
  licenses: License[];
  activeLicense: License | null;
  isLoading: boolean;
  error: string | null;
  fetchLicenses: () => Promise<void>;
  addLicense: (license: License) => void;
  updateLicense: (license: License) => void;
  setActiveLicense: (license: License | null) => void;
  setError: (error: string | null) => void;
}

export const useSaaSStore = create<SaaSState>((set) => ({
  licenses: [],
  activeLicense: null,
  isLoading: false,
  error: null,
  
  fetchLicenses: async () => {
    set({ isLoading: true, error: null });
    try {
      const data = await licenseAPI.findAll();
      set({ licenses: data || [] });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Erro ao carregar licenças';
      console.error('Erro ao carregar licenças:', message);
      set({ error: message, licenses: [] });
    } finally {
      set({ isLoading: false });
    }
  },

  addLicense: (license) => {
    set(state => ({
      licenses: [license, ...state.licenses]
    }));
  },
  
  updateLicense: (license) => {
    set(state => ({
      licenses: state.licenses.map(l => l.id === license.id ? license : l)
    }));
  },

  setActiveLicense: (license) => set({ activeLicense: license }),
  setError: (error) => set({ error }),
}));