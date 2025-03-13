import api from '../api';
import { AxiosError } from 'axios';

const RETRY_DELAY = 1000;
const MAX_RETRIES = 3;

interface CNPJResponse {
  razao_social: string;
  nome_fantasia: string;
  cnpj: string;
  email: string;
  telefone: string;
  logradouro: string;
  numero: string;
  complemento: string;
  bairro: string;
  municipio: string;
  uf: string;
  cep: string;
}

class PersonAPI {
  async consultarCNPJ(cnpj: string): Promise<CNPJResponse> {
    const cnpjLimpo = cnpj.replace(/\D/g, '');
    
    console.log('Consultando CNPJ:', cnpjLimpo);
    
    try {
      const response = await api.get(`person/cnpj/${cnpjLimpo}`);
      return response.data;
    } catch (error) {
      if (error instanceof AxiosError) {
        if (error.response?.status === 404) {
          throw new Error('CNPJ não encontrado');
        }
        
        const errorMessage = error.response?.data?.error || 'Não foi possível consultar o CNPJ';
        console.error('Erro na consulta do CNPJ:', {
          status: error.response?.status,
          data: error.response?.data,
          message: error.message
        });
        throw new Error(errorMessage);
      }
      
      throw new Error('Erro ao consultar CNPJ');
    }
  }
}

export const personAPI = new PersonAPI();