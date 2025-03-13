import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import helmet from 'helmet';
import path from 'node:path';
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import licenseRoutes from './routes/licenses';
import personRoutes from './routes/person';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Carrega as variáveis de ambiente do arquivo .env na raiz do projeto
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

// Validação das variáveis de ambiente necessárias
const requiredEnvVars = ['VITE_SUPABASE_URL', 'VITE_SUPABASE_ANON_KEY'];
requiredEnvVars.forEach(varName => {
  if (!process.env[varName]) {
    throw new Error(`Variável de ambiente ${varName} não encontrada`);
  }
});

const app = express();
const PORT = process.env.PORT || 3001;

// Configuração do CORS mais permissiva para desenvolvimento
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Logging middleware
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false,
  crossOriginResourcePolicy: false
}));

// Middleware para processar JSON
app.use(express.json());

// Rota raiz
app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'API Finance SaaS' });
});

// Rota de healthcheck
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Rotas da API
app.use('/api/licenses', licenseRoutes);
app.use('/api/person', personRoutes);

// Handler de erros global
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Erro interno do servidor',
    message: err.message,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
  });
});

// Handler para rotas não encontradas
app.use((req, res) => {
  res.status(404).json({ error: 'Rota não encontrada' });
});

app.listen(PORT, () => {
  console.log(`🚀 Servidor rodando em http://localhost:${PORT}`);
});

export default app;