import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Building2, Users, Package, Calendar, MoreVertical } from 'lucide-react';
import { tenantAPI, Tenant } from '../../services/api/tenants';

export function TenantList() {
  const navigate = useNavigate();
  const [tenants, setTenants] = React.useState<Tenant[]>([]);
  const [isLoading, setIsLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);
  const [editingTenant, setEditingTenant] = React.useState<Tenant | null>(null);

  const fetchTenants = React.useCallback(async () => {
    try {
      const data = await tenantAPI.findAll();
      setTenants(data);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Erro ao carregar tenants';
      setError(message);
    } finally {
      setIsLoading(false);
    }
  }, []);

  React.useEffect(() => {
    fetchTenants();
  }, [fetchTenants]);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-600">
        {error}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold text-gray-900">Tenants</h2>
        <button
          onClick={() => navigate('/register/tenant')}
          className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition-colors"
        >
          Novo Tenant
        </button>
      </div>

      {tenants.length === 0 ? (
        <div className="bg-gray-50 border border-gray-200 rounded-lg p-8 text-center">
          <Building2 className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Nenhum tenant encontrado</h3>
          <p className="text-gray-600">Clique em "Novo Tenant" para começar.</p>
        </div>
      ) : (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {tenants.map((tenant) => (
            <div key={tenant.id} className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center space-x-3">
                  <Building2 className={`h-6 w-6 ${
                    tenant.status === 'active' ? 'text-green-500' : 
                    tenant.status === 'inactive' ? 'text-gray-400' : 'text-red-500'
                  }`} />
                  <h3 className="font-semibold text-lg text-gray-900">{tenant.name}</h3>
                </div>
                <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                  tenant.status === 'active' ? 'bg-green-100 text-green-700' :
                  tenant.status === 'inactive' ? 'bg-gray-100 text-gray-700' : 'bg-red-100 text-red-700'
                }`}>
                  {tenant.status === 'active' ? 'Ativo' : 
                   tenant.status === 'inactive' ? 'Inativo' : 'Suspenso'}
                </span>
              </div>

              <div className="space-y-3">
                <div className="flex items-center text-gray-600">
                  <Package className="h-5 w-5 mr-2" />
                  <span className="text-sm">Identificador: {tenant.slug}</span>
                </div>
                
                <div className="flex items-center text-gray-600">
                  <Calendar className="h-5 w-5 mr-2" />
                  <span className="text-sm">
                    Criado em {new Date(tenant.created_at).toLocaleDateString('pt-BR')}
                  </span>
                </div>
              </div>

              <div className="mt-4 pt-4 border-t border-gray-100">
                <button
                  onClick={() => setEditingTenant(tenant)}
                  className="text-blue-600 hover:text-blue-700 text-sm font-medium"
                >
                  Gerenciar
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}