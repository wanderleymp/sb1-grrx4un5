import React from 'react';
import { useSaaSStore } from '../../store/saas';
import { Shield, Globe, Package, Calendar } from 'lucide-react';
import { Modal } from '../../components/ui/Modal';
import { LicenseForm } from './LicenseForm';
import { EditLicenseForm } from './EditLicenseForm';
import { License } from '../../services/api/licenses';

export function LicenseList() {
  const { licenses, isLoading, error, fetchLicenses } = useSaaSStore();
  const [isFormOpen, setIsFormOpen] = React.useState(false);
  const [editingLicense, setEditingLicense] = React.useState<License | null>(null);

  React.useEffect(() => {
    fetchLicenses();
  }, [fetchLicenses]);

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
        <h2 className="text-2xl font-bold text-gray-900">Licenças</h2>
        <button
          onClick={() => setIsFormOpen(true)}
          className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition-colors"
        >
          Nova Licença
        </button>
      </div>

      {licenses.length === 0 ? (
        <div className="bg-gray-50 border border-gray-200 rounded-lg p-8 text-center">
          <Package className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Nenhuma licença encontrada</h3>
          <p className="text-gray-600">Clique em "Nova Licença" para começar.</p>
        </div>
      ) : (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {licenses.map((license) => (
            <div key={license.id} className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center space-x-3">
                  <Shield className={`h-6 w-6 ${
                    license.status === 'active' ? 'text-green-500' : 
                    license.status === 'inactive' ? 'text-gray-400' : 'text-red-500'
                  }`} />
                  <h3 className="font-semibold text-lg text-gray-900">{license.name}</h3>
                </div>
                <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                  license.status === 'active' ? 'bg-green-100 text-green-700' :
                  license.status === 'inactive' ? 'bg-gray-100 text-gray-700' : 'bg-red-100 text-red-700'
                }`}>
                  {license.status === 'active' ? 'Ativo' : 
                   license.status === 'inactive' ? 'Inativo' : 'Suspenso'}
                </span>
              </div>

              <div className="space-y-3">
                <div className="flex items-center text-gray-600">
                  <Globe className="h-5 w-5 mr-2" />
                  <span className="text-sm">{license.domain}</span>
                </div>
                
                <div className="flex items-center text-gray-600">
                  <Package className="h-5 w-5 mr-2" />
                  <span className="text-sm">{license.modules.length} módulos ativos</span>
                </div>

                {license.expires_at && (
                  <div className="flex items-center text-gray-600">
                    <Calendar className="h-5 w-5 mr-2" />
                    <span className="text-sm">
                      Expira em {new Date(license.expires_at).toLocaleDateString('pt-BR')}
                    </span>
                  </div>
                )}
              </div>

              <div className="mt-4 pt-4 border-t border-gray-100 flex justify-between items-center">
                <button
                  onClick={() => setEditingLicense(license)}
                  className="text-blue-600 hover:text-blue-700 text-sm font-medium"
                >
                  Editar
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      <Modal isOpen={isFormOpen} onClose={() => setIsFormOpen(false)}>
        <LicenseForm onClose={() => setIsFormOpen(false)} />
      </Modal>
      
      <Modal
        isOpen={!!editingLicense}
        onClose={() => setEditingLicense(null)}
      >
        {editingLicense && (
          <EditLicenseForm
            license={editingLicense}
            onClose={() => setEditingLicense(null)}
          />
        )}
      </Modal>
    </div>
  );
}