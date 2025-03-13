import React from 'react';
import { Link } from 'react-router-dom';
import {
  Users,
  CreditCard,
  ArrowUpRight,
  ArrowDownRight,
  Activity,
  Package,
  Building2,
  MessageSquare,
  TicketCheck,
  Clock,
  MoreVertical,
} from 'lucide-react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  AreaChart,
  Area,
} from 'recharts';

const revenueData = [
  { name: 'Jan', value: 12000 },
  { name: 'Fev', value: 19000 },
  { name: 'Mar', value: 15000 },
  { name: 'Abr', value: 22000 },
  { name: 'Mai', value: 28000 },
  { name: 'Jun', value: 25000 },
];

const clientsData = [
  { name: 'Jan', value: 50 },
  { name: 'Fev', value: 80 },
  { name: 'Mar', value: 120 },
  { name: 'Abr', value: 150 },
  { name: 'Mai', value: 200 },
  { name: 'Jun', value: 250 },
];

const recentActivities = [
  {
    id: 1,
    type: 'client',
    title: 'Novo Cliente',
    description: 'Empresa ABC LTDA foi adicionada',
    time: '2 horas atrás',
    icon: Building2,
  },
  {
    id: 2,
    type: 'message',
    title: 'Nova Mensagem',
    description: 'João respondeu ao ticket #1234',
    time: '3 horas atrás',
    icon: MessageSquare,
  },
  {
    id: 3,
    type: 'ticket',
    title: 'Ticket Resolvido',
    description: 'Ticket #1234 foi marcado como resolvido',
    time: '5 horas atrás',
    icon: TicketCheck,
  },
];

export function Dashboard() {
  return (
    <div className="space-y-8">
      {/* Métricas Principais */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <div className="flex justify-between items-start mb-4">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Users className="h-6 w-6 text-blue-600" />
            </div>
            <span className="px-2.5 py-0.5 text-sm font-medium text-green-700 bg-green-100 rounded-full">
              +12%
            </span>
          </div>
          <h3 className="text-2xl font-bold text-gray-900">2.350</h3>
          <p className="text-sm text-gray-500">Clientes Ativos</p>
          <div className="mt-2 flex items-center text-sm text-green-600">
            <ArrowUpRight className="h-4 w-4 mr-1" />
            <span>Aumento de 125 este mês</span>
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <div className="flex justify-between items-start mb-4">
            <div className="p-2 bg-green-100 rounded-lg">
              <CreditCard className="h-6 w-6 text-green-600" />
            </div>
            <span className="px-2.5 py-0.5 text-sm font-medium text-green-700 bg-green-100 rounded-full">
              +23%
            </span>
          </div>
          <h3 className="text-2xl font-bold text-gray-900">R$ 156.250</h3>
          <p className="text-sm text-gray-500">Receita Mensal</p>
          <div className="mt-2 flex items-center text-sm text-green-600">
            <ArrowUpRight className="h-4 w-4 mr-1" />
            <span>Aumento de R$ 12.350</span>
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <div className="flex justify-between items-start mb-4">
            <div className="p-2 bg-purple-100 rounded-lg">
              <Package className="h-6 w-6 text-purple-600" />
            </div>
            <span className="px-2.5 py-0.5 text-sm font-medium text-yellow-700 bg-yellow-100 rounded-full">
              +5%
            </span>
          </div>
          <h3 className="text-2xl font-bold text-gray-900">1.890</h3>
          <p className="text-sm text-gray-500">Licenças Ativas</p>
          <div className="mt-2 flex items-center text-sm text-yellow-600">
            <Activity className="h-4 w-4 mr-1" />
            <span>Crescimento estável</span>
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <div className="flex justify-between items-start mb-4">
            <div className="p-2 bg-red-100 rounded-lg">
              <TicketCheck className="h-6 w-6 text-red-600" />
            </div>
            <span className="px-2.5 py-0.5 text-sm font-medium text-red-700 bg-red-100 rounded-full">
              -8%
            </span>
          </div>
          <h3 className="text-2xl font-bold text-gray-900">95.5%</h3>
          <p className="text-sm text-gray-500">Taxa de Resolução</p>
          <div className="mt-2 flex items-center text-sm text-red-600">
            <ArrowDownRight className="h-4 w-4 mr-1" />
            <span>Queda de 2.3%</span>
          </div>
        </div>
      </div>

      {/* Gráficos */}
      <div className="grid gap-6 lg:grid-cols-2">
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <div className="flex justify-between items-center mb-6">
            <div>
              <h3 className="text-lg font-semibold text-gray-900">Receita Mensal</h3>
              <p className="text-sm text-gray-500">Últimos 6 meses</p>
            </div>
            <button className="p-2 hover:bg-gray-100 rounded-lg">
              <MoreVertical className="h-5 w-5 text-gray-500" />
            </button>
          </div>
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={revenueData}>
                <defs>
                  <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3B82F6" stopOpacity={0.1}/>
                    <stop offset="95%" stopColor="#3B82F6" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
                <XAxis dataKey="name" stroke="#6B7280" />
                <YAxis stroke="#6B7280" />
                <Tooltip />
                <Area
                  type="monotone"
                  dataKey="value"
                  stroke="#3B82F6"
                  fillOpacity={1}
                  fill="url(#colorRevenue)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <div className="flex justify-between items-center mb-6">
            <div>
              <h3 className="text-lg font-semibold text-gray-900">Crescimento de Clientes</h3>
              <p className="text-sm text-gray-500">Últimos 6 meses</p>
            </div>
            <button className="p-2 hover:bg-gray-100 rounded-lg">
              <MoreVertical className="h-5 w-5 text-gray-500" />
            </button>
          </div>
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={clientsData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
                <XAxis dataKey="name" stroke="#6B7280" />
                <YAxis stroke="#6B7280" />
                <Tooltip />
                <Line
                  type="monotone"
                  dataKey="value"
                  stroke="#10B981"
                  strokeWidth={2}
                  dot={{ r: 4, fill: "#10B981" }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Atividades Recentes */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100">
        <div className="p-6 border-b border-gray-100">
          <div className="flex justify-between items-center">
            <div>
              <h3 className="text-lg font-semibold text-gray-900">Atividades Recentes</h3>
              <p className="text-sm text-gray-500">Últimas 24 horas</p>
            </div>
            <Link
              to="/activities"
              className="text-sm font-medium text-blue-600 hover:text-blue-700"
            >
              Ver todas
            </Link>
          </div>
        </div>
        <div className="divide-y divide-gray-100">
          {recentActivities.map((activity) => (
            <div key={activity.id} className="p-6">
              <div className="flex items-start space-x-4">
                <div className={`p-2 rounded-lg ${
                  activity.type === 'client' ? 'bg-blue-100' :
                  activity.type === 'message' ? 'bg-purple-100' : 'bg-green-100'
                }`}>
                  <activity.icon className={`h-5 w-5 ${
                    activity.type === 'client' ? 'text-blue-600' :
                    activity.type === 'message' ? 'text-purple-600' : 'text-green-600'
                  }`} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-900">
                    {activity.title}
                  </p>
                  <p className="text-sm text-gray-500">
                    {activity.description}
                  </p>
                </div>
                <div className="flex items-center text-sm text-gray-500">
                  <Clock className="h-4 w-4 mr-1" />
                  {activity.time}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}