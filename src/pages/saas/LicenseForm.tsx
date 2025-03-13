import React from 'react';
import { useSaaSStore } from '../../store/saas';
import { Globe, Package, Calendar, Building2, Palette, FileText, Shield, Search, AlertCircle } from 'lucide-react';
import { useMask } from '@react-input/mask';
import { licenseAPI } from '../../services/api/licenses';
import { personAPI } from '../../services/api/person';

interface LicenseFormProps {
  onClose: () => void;
}

export function LicenseForm({ onClose }: LicenseFormProps) {
  const { addLicense } = useSaaSStore();
  const [isSubmitting, setIsSubmitting] = React.useState(false);
  const [formData, setFormData] = React.useState({
    name: '',
    domain: '',
    companyName: '',
    document: '',
    documentType: 'cnpj',
    modules: [] as string[],
    expiresAt: '',
    primaryColor: '#2563eb',
  });

  const [errors, setErrors] = React.useState<Record<string, string>>({});
  const [isLoadingCNPJ, setIsLoadingCNPJ] = React.useState(false);

  const handleDocumentChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    const numbers = value.replace(/\D/g, '');
    
    if (formData.documentType === 'cpf') {
      if (numbers.length <= 11) {
        const masked = numbers
          .replace(/(\d{3})(\d)/, '$1.$2')
          .replace(/(\d{3})(\d)/, '$1.$2')
          .replace(/(\d{3})(\d{1,2})$/, '$1-$2');
        setFormData(prev => ({ ...prev, document: masked }));
      }
    } else {
      if (numbers.length <= 14) {
        const masked = numbers
          .replace(/(\d{2})(\d)/, '$1.$2')
          .replace(/(\d{3})(\d)/, '$1.$2')
          .replace(/(\d{3})(\d)/, '$1/$2')
          .replace(/(\d{4})(\d{1,2})$/, '$1-$2');
        setFormData(prev => ({ ...prev, document: masked }));
      }
    }
  };

  const availableModules = [
    { id: 'saas', name: 'Gerenciamento SaaS', description: 'Gerenciamento de licenças e configurações' },
    { id: 'crm', name: 'CRM', description: 'Gestão de relacionamento com clientes' },
    { id: 'chat', name: 'Chat', description: 'Comunicação integrada' },
    { id: 'tickets', name: 'Tickets', description: 'Sistema de suporte' },
    { id: 'financeiro', name: 'Financeiro', description: 'Controle financeiro' },
    { id: 'documentos', name: 'Documentos Fiscais', description: 'Gestão de documentos fiscais' },
  ];

  const validateDocument = (doc: string, type: 'cpf' | 'cnpj'): boolean => {
    if (!doc) return true;
    const numbers = doc.replace(/\D/g, '');
    
    if (type === 'cpf' && numbers.length !== 11) return false;
    if (type === 'cnpj' && numbers.length !== 14) return false;
    
    return true;
  };

  const validateDomain = (domain: string): boolean => {
    const domainRegex = /^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$/;
    return domainRegex.test(domain);
  };

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.name.trim()) {
      newErrors.name = 'Nome da licença é obrigatório';
    }

    if (!formData.domain.trim()) {
      newErrors.domain = 'Domínio é obrigatório';
    } else if (!validateDomain(formData.domain)) {
      newErrors.domain = 'Domínio inválido';
    }

    if (!formData.companyName.trim()) {
      newErrors.companyName = 'Nome da empresa é obrigatório';
    }

    if (formData.modules.length === 0) {
      newErrors.modules = 'Selecione pelo menos um módulo';
    }
    
    setErrors(newErrors);
    
    // Exibe os erros na interface
    Object.entries(newErrors).forEach(([field, message]) => {
      const element = document.querySelector(`[name="${field}"]`);
      if (element) {
        element.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }
    });

    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    setIsSubmitting(true);
    try {
      const cleanedData = {
        name: formData.name.trim(),
        domain: formData.domain.trim(),
        companyName: formData.companyName.trim(),
        document: formData.document ? formData.document.replace(/\D/g, '') : undefined,
        documentType: formData.document ? formData.documentType as 'cpf' | 'cnpj' : undefined,
        modules: formData.modules,
        expiresAt: formData.expiresAt || undefined,
        primaryColor: formData.primaryColor,
      };

      const license = await licenseAPI.create(cleanedData);
      addLicense(license);
      onClose();
    } catch (error) {
      console.error('Erro ao criar licença:', error);
      setErrors(prev => ({
        ...prev,
        submit: 'Erro ao criar licença. Verifique os dados e tente novamente.'
      }));
    } finally {
      setIsSubmitting(false);
    }
  };

  const consultarCNPJ = async () => {
    if (!formData.document || formData.documentType !== 'cnpj') return;

    setIsLoadingCNPJ(true);
    try {
      const cnpj = formData.document.replace(/\D/g, '');
      const data = await personAPI.consultarCNPJ(cnpj);
      
      setFormData(prev => ({
        ...prev,
        name: (data.razao_social || data.nome_fantasia).split(' ')[0],
        companyName: data.razao_social || data.nome_fantasia,
      }));
    } catch (error) {
      console.error('Erro ao consultar CNPJ:', error);
      setErrors(prev => ({
        ...prev,
        document: 'Erro ao consultar CNPJ'
      }));
    } finally {
      setIsLoadingCNPJ(false);
    }
  };

  return (
    <div className="bg-white rounded-xl p-6 max-w-2xl mx-auto">
      <div className="flex items-center space-x-3 mb-6">
        <div className="p-2 bg-blue-100 rounded-lg">
          <Shield className="h-6 w-6 text-blue-600" />
        </div>
        <h2 className="text-2xl font-bold text-gray-900">Nova Licença</h2>
      </div>
      
      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Documento (CPF/CNPJ) */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Documento (Opcional)
          </label>
          <div className="flex space-x-2">
            <select
              value={formData.documentType}
              onChange={(e) => {
                setFormData(prev => ({ 
                  ...prev, 
                  documentType: e.target.value,
                  document: ''
                }));
                setErrors(prev => ({ ...prev, document: '' }));
              }}
              className="w-24 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent py-2"
            >
              <option value="cnpj">CNPJ</option>
              <option value="cpf">CPF</option>
            </select>
            <div className="relative flex-1">
              <FileText className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
              <input
                type="text"
                value={formData.document}
                onChange={handleDocumentChange}
                className={`pl-10 w-full rounded-lg border ${
                  errors.document ? 'border-red-300 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
                } focus:ring-2 focus:border-transparent py-2`}
                placeholder={formData.documentType === 'cpf' ? '000.000.000-00' : '00.000.000/0000-00'}
                maxLength={formData.documentType === 'cpf' ? 14 : 18}
              />
              {errors.document && (
                <div className="flex items-center mt-1 text-red-600 text-sm">
                  <AlertCircle className="h-4 w-4 mr-1" />
                  {errors.document}
                </div>
              )}
            </div>
            {formData.documentType === 'cnpj' && (
              <button
                type="button"
                onClick={consultarCNPJ}
                disabled={isLoadingCNPJ || !formData.document}
                className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
              >
                {isLoadingCNPJ ? (
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-gray-700" />
                ) : (
                  <>
                    <Search className="h-5 w-5 mr-2" />
                    Consultar
                  </>
                )}
              </button>
            )}
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Nome da Licença
            </label>
            <div className="relative">
              <Building2 className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
              <input
                type="text"
                value={formData.name}
                onChange={(e) => {
                  const value = e.target.value;
                  setFormData(prev => ({ ...prev, name: e.target.value }));
                  if (errors.name) {
                    setErrors(prev => ({ ...prev, name: '' }));
                  }
                }}
                name="name"
                className={`pl-10 w-full rounded-lg border ${
                  errors.name ? 'border-red-300 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
                } focus:ring-2 focus:border-transparent py-2`}
                placeholder="Ex: Empresa ABC"
              />
              {errors.name && (
                <div className="flex items-center mt-1 text-red-600 text-sm">
                  <AlertCircle className="h-4 w-4 mr-1" />
                  {errors.name}
                </div>
              )}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Domínio
            </label>
            <div className="relative">
              <Globe className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
              <input
                type="text"
                value={formData.domain}
                onChange={(e) => {
                  const value = e.target.value;
                  setFormData(prev => ({ ...prev, domain: e.target.value }));
                  if (errors.domain) {
                    setErrors(prev => ({ ...prev, domain: '' }));
                  }
                }}
                name="domain"
                className={`pl-10 w-full rounded-lg border ${
                  errors.domain ? 'border-red-300 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
                } focus:ring-2 focus:border-transparent py-2`}
                placeholder="Ex: empresa.com.br"
              />
              {errors.domain && (
                <div className="flex items-center mt-1 text-red-600 text-sm">
                  <AlertCircle className="h-4 w-4 mr-1" />
                  {errors.domain}
                </div>
              )}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Nome da Empresa
            </label>
            <div className="relative">
              <Building2 className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
              <input
                type="text"
                value={formData.companyName}
                onChange={(e) => {
                  const value = e.target.value;
                  setFormData(prev => ({ ...prev, companyName: e.target.value }));
                  if (errors.companyName) {
                    setErrors(prev => ({ ...prev, companyName: '' }));
                  }
                }}
                name="companyName"
                className={`pl-10 w-full rounded-lg border ${
                  errors.companyName ? 'border-red-300 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
                } focus:ring-2 focus:border-transparent py-2`}
                placeholder="Ex: Empresa ABC LTDA"
              />
              {errors.companyName && (
                <div className="flex items-center mt-1 text-red-600 text-sm">
                  <AlertCircle className="h-4 w-4 mr-1" />
                  {errors.companyName}
                </div>
              )}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Data de Expiração
            </label>
            <div className="relative">
              <Calendar className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
              <input
                type="date"
                value={formData.expiresAt}
                onChange={(e) => {
                  setFormData(prev => ({ ...prev, expiresAt: e.target.value }));
                  if (errors.expiresAt) {
                    setErrors(prev => ({ ...prev, expiresAt: '' }));
                  }
                }}
                className={`pl-10 w-full rounded-lg border ${
                  errors.expiresAt ? 'border-red-300 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
                } focus:ring-2 focus:border-transparent py-2`}
                min={new Date().toISOString().split('T')[0]}
              />
              {errors.expiresAt && (
                <div className="flex items-center mt-1 text-red-600 text-sm">
                  <AlertCircle className="h-4 w-4 mr-1" />
                  {errors.expiresAt}
                </div>
              )}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Cor Primária
            </label>
            <div className="relative">
              <Palette className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
              <input
                type="color"
                value={formData.primaryColor}
                onChange={(e) => setFormData(prev => ({ ...prev, primaryColor: e.target.value }))}
                className="pl-10 w-full h-10 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-3">
            Módulos
          </label>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {availableModules.map((module) => (
              <label
                key={module.id}
                className={`flex items-center p-4 rounded-lg border cursor-pointer transition-colors ${
                  formData.modules.includes(module.id)
                    ? 'bg-blue-50 border-blue-500 text-blue-700'
                    : 'border-gray-200 hover:border-blue-200'
                } ${errors.modules ? 'border-red-300' : ''}`}
              >
                <input
                  type="checkbox"
                  checked={formData.modules.includes(module.id)}
                  onChange={() => {
                    const newModules = formData.modules.includes(module.id)
                      ? formData.modules.filter(id => id !== module.id)
                      : [...formData.modules, module.id];
                    setFormData(prev => ({
                      ...prev,
                      modules: newModules
                    }));
                    if (errors.modules) {
                      setErrors(prev => ({ ...prev, modules: '' }));
                    }
                  }}
                  name="modules"
                  className="sr-only"
                />
                <Package className={`h-5 w-5 mr-3 flex-shrink-0 ${
                  formData.modules.includes(module.id) ? 'text-blue-500' : 'text-gray-400'
                }`} />
                <div>
                  <span className="text-sm font-medium block">{module.name}</span>
                  <span className="text-xs text-gray-500">{module.description}</span>
                </div>
              </label>
            ))}
          </div>
          {errors.modules && (
            <div className="flex items-center mt-2 text-red-600 text-sm">
              <AlertCircle className="h-4 w-4 mr-1" />
              {errors.modules}
            </div>
          )}
        </div>

        {errors.submit && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-600">
            {errors.submit}
          </div>
        )}

        <div className="flex justify-end space-x-3 pt-6 border-t">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-800 transition-colors"
            disabled={isSubmitting}
          >
            Cancelar
          </button>
          <button
            type="submit"
            disabled={isSubmitting}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed inline-flex items-center"
          >
            {isSubmitting ? (
              <>
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                Criando...
              </>
            ) : (
              'Criar Licença'
            )}
          </button>
        </div>
      </form>
    </div>
  );
}