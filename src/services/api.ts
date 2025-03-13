import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:3001/api',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  },
  timeout: 30000
});

// Interceptor para log de erros
api.interceptors.response.use(
  response => response,
  error => {
    const errorData = {
      url: error.config?.url,
      method: error.config?.method,
      status: error.response?.status || 500,
      code: error.code,
      data: error.response?.data,
      message: error.message
    };

    console.error('Erro na requisição:', errorData);

    return Promise.reject(error);
  }
);

export default api;