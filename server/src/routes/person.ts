import express from 'express';
import axios from 'axios';

const router = express.Router();

router.get('/cnpj/:cnpj', async (req, res) => {
  try {
    const { cnpj } = req.params;
    
    if (!cnpj) {
      return res.status(400).json({ error: 'CNPJ não informado' });
    }
    
    if (!/^\d{14}$/.test(cnpj.replace(/\D/g, ''))) {
      return res.status(400).json({ error: 'CNPJ inválido' });
    }

    const response = await axios.get(`https://brasilapi.com.br/api/cnpj/v1/${cnpj}`, {
      timeout: 15000,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0'
      }
    });

    res.json(response.data);
  } catch (error) {
    console.error('Erro ao consultar CNPJ:', error);
    
    if (axios.isAxiosError(error)) {
      if (error.response?.status === 404) {
        return res.status(404).json({ error: 'CNPJ não encontrado' });
      }
      if (error.code === 'ECONNABORTED') {
        return res.status(504).json({ error: 'Tempo limite excedido ao consultar o CNPJ' });
      }
    }
    
    res.status(500).json({ error: 'Não foi possível consultar o CNPJ' });
  }
});

export default router;