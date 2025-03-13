import React from 'react';
import { Building2, Globe, Mail, Lock, User, AlertCircle, Search } from 'lucide-react';
import { tenantAPI } from '../../services/api/tenants';
import { licenseAPI } from '../../services/api/licenses';

interface NewTenantFormProps {
  onClose: () => void;
  onSuccess?: () => void;
}

export function NewTenantForm({ onClose, onSuccess }: NewTenantFormProps) {
  const [isSubmitting, setIsSubmitting] = React.useState(false);
  const [currentStep, setCurrentStep] = React.useState(1);
  const [isLoadingCNPJ, setIsLoadingCNPJ] = React.useState(false);
  const [formData, setFormData] = React.useState({
    // Dados do Tenant
    name: '',
    slug: '',
    // Dados da Empresa
    companyName: '',
    document: '',
    documentType: 'cnpj' as 'cpf' | 'cnpj',
    companyEmail: '',
    companyPhone: '',
    companyAddress: {
      street: '',
      number: '',
      complement: '',
      neighborhood: '',
      city: '',
      state: '',
      zipCode: ''
    },
    // Configuração da Licença
    modules: [] as string[],
    expiresAt: '',
    primaryColor: '#2563eb',
    // Dados do Admin
    adminName: '',
    adminEmail: '',
    adminPassword: '',
    adminConfirmPassword: ''
  });

  const [errors, setErrors] = React.useState<Record<string, string>>({});

  const consultarCNPJ = async () => {
    if (!formData.document || formData.documentType !== 'cnpj') return;
    
    setIsLoadingCNPJ(true);
    try {
      const cnpj = formData.document.replace(/\D/g, '');
      const data = await licenseAPI.consultarCNPJ(cnpj);
      
      setFormData(prev => ({
        ...prev,
        name: data.razao_social || data.nome_fantasia,
        companyName: data.razao_social || data.nome_fantasia,
        companyEmail: data.email || prev.companyEmail,
        companyPhone: data.telefone || prev.companyPhone,
        companyAddress: {
          street: data.logradouro || '',
          number: data.numero || '',
          complement: data.complemento || '',
          neighborhood: data.bairro || '',
          city: data.municipio || '',
          state: data.uf || '',
          zipCode: data.cep || ''
        }
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

  const generateSlug = (name: string) => {
    return name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');
  };

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    // Validar dados do tenant
    if (!formData.name.trim()) {
      newErrors.name = 'Nome é obrigatório';
    }

    if (!formData.companyName.trim()) {
      newErrors.companyName = 'Nome da empresa é obrigatório';
    }

    if (!formData.companyEmail.trim()) {
      newErrors.companyEmail = 'Email da empresa é obrigatório';
    }
    
    // Validar documento
    if (formData.document) {
      const numbers = formData.document.replace(/\D/g, '');
      if (formData.documentType === 'cpf' && numbers.length !== 11) {
        newErrors.document = 'CPF inválido';
      } else if (formData.documentType === 'cnpj' && numbers.length !== 14) {
        newErrors.document = 'CNPJ inválido';
      }
    }

    // Validar dados do admin
    if (!formData.adminName.trim()) {
      newErrors.adminName = 'Nome do administrador é obrigatório';
    }

    if (!formData.adminEmail.trim()) {
      newErrors.adminEmail = 'Email do administrador é obrigatório';
    }

    if (!formData.adminPassword) {
      newErrors.adminPassword = 'Senha é obrigatória';
    } else if (formData.adminPassword.length < 6) {
      newErrors.adminPassword = 'A senha deve ter pelo menos 6 caracteres';
    }

    if (formData.adminPassword !== formData.adminConfirmPassword) {
      newErrors.adminConfirmPassword = 'As senhas não coincidem';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm() || !formData.name || !formData.companyEmail) {
      setErrors(prev => ({
        ...prev,
        submit: 'Preencha todos os campos obrigatórios'
      }));
      return;
    }

    setIsSubmitting(true);
    try {
      // Gerar slug se não existir
      const slug = formData.slug || generateSlug(formData.name);

      await tenantAPI.createFull({
        tenant: {
          name: formData.name,
          slug,
          company_name: formData.companyName,
          company_document: formData.document,
          company_document_type: formData.documentType,
          company_email: formData.companyEmail,
          company_phone: formData.companyPhone,
          company_address: formData.companyAddress
        },
        license: {
          modules: formData.modules.length > 0 ? formData.modules : ['saas'], // Módulo padrão
          expires_at: formData.expiresAt || undefined,
          features: {
            chat: true,
            crm: true,
            financeiro: true
          },
          limits: {
            users: 5,
            storage: 1024 // 1GB
          }
        },
        admin: {
          name: formData.adminName || formData.name,
          email: formData.adminEmail || formData.companyEmail,
          password: formData.adminPassword
        }
      });
      
      onSuccess?.();
      onClose();
    } catch (error) {
      console.error('Erro ao criar tenant:', error);
      const message = error instanceof Error ? error.message : 'Erro ao criar tenant';
      setErrors(prev => ({
        ...prev,
        submit: message
      }));
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <div className="flex items-center justify-between mb-8">
        <h2 className="text-2xl font-bold text-gray-900">Novo Tenant</h2>
        <div className="flex items-center space-x-2 text-sm text-gray-500">
          <span className={`w-8 h-8 rounded-full flex items-center justify-center ${
            currentStep >= 1 ? 'bg-blue-100 text-blue-600' : 'bg-gray-100'
          }`}>1</span>
          <span className={`w-8 h-1 ${currentStep >= 2 ? 'bg-blue-100' : 'bg-gray-100'}`} />
          <span className={`w-8 h-8 rounded-full flex items-center justify-center ${
            currentStep >= 2 ? 'bg-blue-100 text-blue-600' : 'bg-gray-100'
          }`}>2</span>
          <span className={`w-8 h-1 ${currentStep >= 3 ? 'bg-blue-100' : 'bg-gray-100'}`} />
          <span className={`w-8 h-8 rounded-full flex items-center justify-center ${
            currentStep >= 3 ? 'bg-blue-100 text-blue-600' : 'bg-gray-100'
          }`}>3</span>
        </div>
      </div>
      
      <form onSubmit={handleSubmit} className="space-y-8">
        {/* Etapa 1: Dados da Empresa */}
        {currentStep === 1 && (
        <div className="space-y-6">
          <h3 className="text-lg font-medium text-gray-900">
            Dados da Empresa
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Nome da Empresa
              </label>
              <div className="relative">
                <Building2 className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => {
                    const name = e.target.value;
                    setFormData(prev => ({
                      ...prev,
                      name,
                      slug: generateSlug(name)
                    }));
                  }}
                  className={`pl-10 w-full rounded-lg border ${
                    errors.name ? 'border-red-300 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
                  } focus:ring-2 focus:border-transparent py-2`}
                  placeholder="Nome da empresa"
                />
                {errors.name && (
                  <div className="mt-1 text-sm text-red-600 flex items-center">
                    <AlertCircle className="h-4 w-4 mr-1" />
                    {errors.name}
                  </div>
                )}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Email
              </label>
              <div className="relative">
                <Mail className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
                <input
                  type="email"
                  value={formData.companyEmail}
                  onChange={(e) => {
                    setFormData(prev => ({
                      ...prev,
                      companyEmail: e.target.value
                    }));
                  }}
                  className={`pl-10 w-full rounded-lg border ${
                    errors.companyEmail ? 'border-red-300 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
                  } focus:ring-2 focus:border-transparent py-2`}
                  placeholder="empresa@exemplo.com"
                />
                {errors.companyEmail && (
                  <div className="mt-1 text-sm text-red-600 flex items-center">
                    <AlertCircle className="h-4 w-4 mr-1" />
                    {errors.companyEmail}
                  </div>
                )}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                CNPJ/CPF
              </label>
              <div className="flex space-x-2">
                <select
                  value={formData.documentType}
                  onChange={(e) => {
                    setFormData(prev => ({
                      ...prev,
                      documentType: e.target.value as 'cpf' | 'cnpj',
                      document: ''
                    }));
                  }}
                  className="w-28 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent py-2"
                >
                  <option value="cnpj">CNPJ</option>
                  <option value="cpf">CPF</option>
                </select>
                <div className="relative flex-1 min-w-[280px]">
                  <input
                    type="text"
                    value={formData.document}
                    onChange={(e) => {
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
                    }}
                    className={`w-full rounded-lg border ${
                      errors.document ? 'border-red-300 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
                    } focus:ring-2 focus:border-transparent py-2 px-3`}
                    placeholder={formData.documentType === 'cpf' ? '000.000.000-00' : '00.000.000/0000-00'}
                  />
                  {errors.document && (
                    <div className="mt-1 text-sm text-red-600 flex items-center">
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
                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-2 w-32 justify-center whitespace-nowrap"
                  >
                    {isLoadingCNPJ ? (
                      <>
                        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />
                        <span>Consultando...</span>
                      </>
                    ) : (
                      <>
                        <Search className="h-4 w-4" />
                        <span>Consultar</span>
                      </>
                    )}
                  </button>
                )}
              </div>
            </div>
          </div>

          <div className="flex justify-end pt-6">
            <button
              type="button"
              onClick={() => setCurrentStep(2)}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Próximo
            </button>
          </div>
        </div>
        )}

        {/* Etapa 2: Configuração da Licença */}
        {currentStep === 2 && (
        <div className="space-y-6">
          <h3 className="text-lg font-medium text-gray-900">
            Configuração da Licença
          </h3>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-3">
              Módulos
            </label>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {[
                { id: 'saas', name: 'Gerenciamento SaaS', description: 'Gerenciamento de licenças e configurações' },
                { id: 'crm', name: 'CRM', description: 'Gestão de relacionamento com clientes' },
                { id: 'chat', name: 'Chat', description: 'Comunicação integrada' },
                { id: 'tickets', name: 'Tickets', description: 'Sistema de suporte' },
                { id: 'financeiro', name: 'Financeiro', description: 'Controle financeiro' },
                { id: 'documentos', name: 'Documentos', description: 'Gestão de documentos' }
              ].map((module) => (
                <label
                  key={module.id}
                  className={`flex items-center p-4 rounded-lg border cursor-pointer transition-colors ${
                    formData.modules.includes(module.id)
                      ? 'bg-blue-50 border-blue-500 text-blue-700'
                      : 'border-gray-200 hover:border-blue-200'
                  }`}
                >
                  <input
                    type="checkbox"
                    checked={formData.modules.includes(module.id)}
                    onChange={(e) => {
                      const newModules = e.target.checked
                        ? [...formData.modules, module.id]
                        : formData.modules.filter(id => id !== module.id);
                      setFormData(prev => ({
                        ...prev,
                        modules: newModules
                      }));
                    }}
                    className="sr-only"
                  />
                  <div>
                    <span className="text-sm font-medium block">{module.name}</span>
                    <span className="text-xs text-gray-500">{module.description}</span>
                  </div>
                </label>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Data de Expiração
            </label>
            <input
              type="date"
              value={formData.expiresAt}
              onChange={(e) => {
                setFormData(prev => ({
                  ...prev,
                  expiresAt: e.target.value
                }));
              }}
              className="w-full rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent py-2 px-3"
              min={new Date().toISOString().split('T')[0]}
            />
          </div>

          <div className="flex justify-between pt-6">
            <button
              type="button"
              onClick={() => setCurrentStep(1)}
              className="px-4 py-2 text-gray-600 hover:text-gray-800"
            >
              Voltar
            </button>
            <button
              type="button"
              onClick={() => setCurrentStep(3)}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Próximo
            </button>
          </div>
        </div>
        )}

        {/* Etapa 3: Dados do Administrador */}
        {currentStep === 3 && (
        <div className="space-y-6">
          <h3 className="text-lg font-medium text-gray-900">
            Dados do Administrador
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Nome
              </label>
              <div className="relative">
                <User className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
                <input
                  type="text"
                  value={formData.adminName}
                  onChange={(e) => {
                    setFormData(prev => ({
                      ...prev,
                      adminName: e.target.value
                    }));
                  }}
                  className={`pl-10 w-full rounded-lg border ${
                    errors.adminName ? 'border-red-300 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
                  } focus:ring-2 focus:border-transparent py-2`}
                  placeholder="Nome do administrador"
                />
                {errors.adminName && (
                  <div className="mt-1 text-sm text-red-600 flex items-center">
                    <AlertCircle className="h-4 w-4 mr-1" />
                    {errors.adminName}
                  </div>
                )}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Senha
              </label>
              <div className="relative">
                <Lock className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
                <input
                  type="password"
                  value={formData.adminPassword}
                  onChange={(e) => {
                    setFormData(prev => ({
                      ...prev,
                      adminPassword: e.target.value
                    }));
                  }}
                  className={`pl-10 w-full rounded-lg border ${
                    errors.adminPassword ? 'border-red-300 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
                  } focus:ring-2 focus:border-transparent py-2`}
                  placeholder="••••••"
                />
                {errors.adminPassword && (
                  <div className="mt-1 text-sm text-red-600 flex items-center">
                    <AlertCircle className="h-4 w-4 mr-1" />
                    {errors.adminPassword}
                  </div>
                )}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Confirmar Senha
              </label>
              <div className="relative">
                <Lock className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
                <input
                  type="password"
                  value={formData.adminConfirmPassword}
                  onChange={(e) => {
                    setFormData(prev => ({
                      ...prev,
                      adminConfirmPassword: e.target.value
                    }));
                  }}
                  className={`pl-10 w-full rounded-lg border ${
                    errors.adminConfirmPassword ? 'border-red-300 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
                  } focus:ring-2 focus:border-transparent py-2`}
                  placeholder="••••••"
                />
                {errors.adminConfirmPassword && (
                  <div className="mt-1 text-sm text-red-600 flex items-center">
                    <AlertCircle className="h-4 w-4 mr-1" />
                    {errors.adminConfirmPassword}
                  </div>
                )}
              </div>
            </div>
          </div>

          {errors.submit && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-600">
              {errors.submit}
            </div>
          )}

          <div className="flex justify-between pt-6 border-t">
            <button
              type="button"
              onClick={() => setCurrentStep(2)}
              className="px-4 py-2 text-gray-600 hover:text-gray-800"
            >
              Voltar
            </button>
            <div className="flex space-x-3">
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
                className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed inline-flex items-center font-medium"
              >
                {isSubmitting ? (
                  <>
                    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-3" />
                    Criando...
                  </>
                ) : (
                  <>
                    <Building2 className="h-5 w-5 mr-2" />
                    Criar Tenant
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
        )}
      </form>
    </div>
  );
}