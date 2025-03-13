import React from 'react';
import { Shield, Lock, Users, User, Check, X, ChevronRight, Search } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';

interface Resource {
  id: string;
  code: string;
  name: string;
  type: 'module' | 'feature' | 'action';
  description?: string;
  parent_id?: string;
  permissions?: Permission[];
}

interface Permission {
  id: string;
  resource_id: string;
  action: 'view' | 'create' | 'edit' | 'delete';
  name: string;
  description?: string;
}

interface RolePermission {
  role_id: string;
  permission_id: string;
  tenant_id: string;
  granted_by: string;
}

interface UserPermission {
  user_id: string;
  permission_id: string;
  tenant_id: string;
  override_type: 'allow' | 'deny';
  granted_by: string;
}

export function PermissionManagement() {
  const { user } = useAuth();
  const [resources, setResources] = React.useState<Resource[]>([]);
  const [selectedResource, setSelectedResource] = React.useState<Resource | null>(null);
  const [searchQuery, setSearchQuery] = React.useState('');
  const [isLoading, setIsLoading] = React.useState(true);

  // Buscar recursos e permissões
  React.useEffect(() => {
    const fetchData = async () => {
      try {
        // TODO: Implementar chamada à API
        setResources([
          {
            id: '1',
            code: 'financial',
            name: 'Financeiro',
            type: 'module',
            description: 'Módulo financeiro',
            permissions: []
          }
        ]);
      } catch (error) {
        console.error('Erro ao carregar recursos:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
  }, []);

  const filteredResources = React.useMemo(() => {
    if (!searchQuery) return resources;
    return resources.filter(resource =>
      resource.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      resource.code.toLowerCase().includes(searchQuery.toLowerCase())
    );
  }, [resources, searchQuery]);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-900">Permissões</h1>
      </div>

      <div className="grid gap-6 lg:grid-cols-12">
        {/* Lista de Recursos */}
        <div className="lg:col-span-4 bg-white rounded-lg shadow">
          <div className="p-4 border-b border-gray-200">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                type="text"
                placeholder="Buscar recursos..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>

          <div className="divide-y divide-gray-200">
            {filteredResources.map((resource) => (
              <button
                key={resource.id}
                onClick={() => setSelectedResource(resource)}
                className={`w-full p-4 text-left hover:bg-gray-50 flex items-center space-x-3 ${
                  selectedResource?.id === resource.id ? 'bg-blue-50' : ''
                }`}
              >
                <div className={`p-2 rounded-lg ${
                  resource.type === 'module' ? 'bg-purple-100' :
                  resource.type === 'feature' ? 'bg-blue-100' : 'bg-green-100'
                }`}>
                  {resource.type === 'module' ? (
                    <Shield className={`h-5 w-5 ${
                      resource.type === 'module' ? 'text-purple-600' :
                      resource.type === 'feature' ? 'text-blue-600' : 'text-green-600'
                    }`} />
                  ) : (
                    <Lock className={`h-5 w-5 ${
                      resource.type === 'module' ? 'text-purple-600' :
                      resource.type === 'feature' ? 'text-blue-600' : 'text-green-600'
                    }`} />
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-900 truncate">
                    {resource.name}
                  </p>
                  <p className="text-xs text-gray-500 truncate">
                    {resource.code}
                  </p>
                </div>
                <ChevronRight className="h-5 w-5 text-gray-400" />
              </button>
            ))}
          </div>
        </div>

        {/* Detalhes do Recurso */}
        <div className="lg:col-span-8">
          {selectedResource ? (
            <div className="bg-white rounded-lg shadow divide-y divide-gray-200">
              <div className="p-6">
                <div className="flex items-center space-x-3 mb-4">
                  <div className={`p-2 rounded-lg ${
                    selectedResource.type === 'module' ? 'bg-purple-100' :
                    selectedResource.type === 'feature' ? 'bg-blue-100' : 'bg-green-100'
                  }`}>
                    {selectedResource.type === 'module' ? (
                      <Shield className={`h-6 w-6 ${
                        selectedResource.type === 'module' ? 'text-purple-600' :
                        selectedResource.type === 'feature' ? 'text-blue-600' : 'text-green-600'
                      }`} />
                    ) : (
                      <Lock className={`h-6 w-6 ${
                        selectedResource.type === 'module' ? 'text-purple-600' :
                        selectedResource.type === 'feature' ? 'text-blue-600' : 'text-green-600'
                      }`} />
                    )}
                  </div>
                  <div>
                    <h2 className="text-xl font-bold text-gray-900">
                      {selectedResource.name}
                    </h2>
                    <p className="text-sm text-gray-500">
                      {selectedResource.code}
                    </p>
                  </div>
                </div>

                {selectedResource.description && (
                  <p className="text-gray-600 mb-6">
                    {selectedResource.description}
                  </p>
                )}

                <div className="space-y-6">
                  {/* Permissões do Recurso */}
                  <div>
                    <h3 className="text-lg font-medium text-gray-900 mb-4">
                      Permissões
                    </h3>
                    <div className="space-y-4">
                      {selectedResource.permissions?.map((permission) => (
                        <div
                          key={permission.id}
                          className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
                        >
                          <div className="flex items-center space-x-3">
                            <div className="p-2 bg-blue-100 rounded-lg">
                              <Lock className="h-5 w-5 text-blue-600" />
                            </div>
                            <div>
                              <p className="text-sm font-medium text-gray-900">
                                {permission.name}
                              </p>
                              {permission.description && (
                                <p className="text-xs text-gray-500">
                                  {permission.description}
                                </p>
                              )}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Usuários com Acesso */}
                  <div>
                    <h3 className="text-lg font-medium text-gray-900 mb-4">
                      Usuários com Acesso
                    </h3>
                    <div className="space-y-4">
                      <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                        <div className="flex items-center space-x-3">
                          <div className="p-2 bg-green-100 rounded-lg">
                            <User className="h-5 w-5 text-green-600" />
                          </div>
                          <div>
                            <p className="text-sm font-medium text-gray-900">
                              Administradores
                            </p>
                            <p className="text-xs text-gray-500">
                              Acesso total ao recurso
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Check className="h-5 w-5 text-green-500" />
                          <span className="text-sm text-green-600 font-medium">
                            Permitido
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div className="bg-white rounded-lg shadow p-6 text-center">
              <Shield className="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                Selecione um recurso
              </h3>
              <p className="text-gray-500">
                Escolha um recurso para ver suas permissões e configurações
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}