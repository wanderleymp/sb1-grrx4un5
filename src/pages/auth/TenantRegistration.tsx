import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Building2, ChevronRight, ChevronLeft, AlertCircle, Search } from 'lucide-react';
import { tenantAPI } from '../../services/api/tenants';

type Step = 'tenant' | 'user';

interface FormData {
  // Dados do Tenant
  companyName: string;
  document: string;
  documentType: 'cpf' | 'cnpj';
  
  // Dados do Usuário
  adminName: string;
  adminEmail: string;
  adminPassword: string;
  adminConfirmPassword: string;
}

const INITIAL_FORM_DATA: FormData = {
  companyName: '',
  document: '',
  documentType: 'cnpj',
  adminName: '',
  adminEmail: '',
  adminPassword: '',
  adminConfirmPassword: ''
};

export function TenantRegistration() {
  const navigate = useNavigate();
  const [currentStep, setCurrentStep] = React.useState<Step>('tenant');
  const [formData, setFormData] = React.useState<FormData>(INITIAL_FORM_DATA);
  const [errors, setErrors] = React.useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = React.useState(false);
  const [isLoadingCNPJ, setIsLoadingCNPJ] = React.useState(false);
  const [submitError, setSubmitError] = React.useState<string | null>(null);

  const validateStep = (step: Step): boolean => {
    const newErrors: Record<string, string> = {};

    switch (step) {
      case 'tenant':
        if (!formData.companyName) newErrors.companyName = 'Nome da empresa é obrigatório';
        if (formData.document) {
          const numbers = formData.document.replace(/\D/g, '');
          if (formData.documentType === 'cpf' && numbers.length !== 11) {
            newErrors.document = 'CPF inválido';
          } else if (formData.documentType === 'cnpj' && numbers.length !== 14) {
            newErrors.document = 'CNPJ inválido';
          }
        }
        break;

      case 'user':
        if (!formData.adminName) newErrors.adminName = 'Nome é obrigatório';
        if (!formData.adminEmail) newErrors.adminEmail = 'Email é obrigatório';
        if (!formData.adminPassword) {
          newErrors.adminPassword = 'Senha é obrigatória';
        } else if (formData.adminPassword.length < 6) {
          newErrors.adminPassword = 'A senha deve ter pelo menos 6 caracteres';
        }
        if (formData.adminPassword !== formData.adminConfirmPassword) {
          newErrors.adminConfirmPassword = 'As senhas não coincidem';
        }
        break;
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleNext = () => {
    if (!validateStep(currentStep)) return;
    setCurrentStep('user');
  };

  const handleBack = () => {
    setCurrentStep('tenant');
  };

  const consultarCNPJ = async () => {
    if (!formData.document || formData.documentType !== 'cnpj') return;
    
    setIsLoadingCNPJ(true);
    try {
      const cnpj = formData.document.replace(/\D/g, '');
      const data = await tenantAPI.consultarCNPJ(cnpj);
      
      setFormData(prev => ({
        ...prev,
        companyName: data.razao_social || data.nome_fantasia
      }));
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Erro ao consultar CNPJ';
      setErrors(prev => ({ ...prev, document: message }));
    } finally {
      setIsLoadingCNPJ(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    setSubmitError(null);
    if (!validateStep(currentStep)) return;

    setIsLoading(true);
    try {
      const slug = formData.companyName
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/(^-|-$)/g, '');

      setSubmitError(null);
      await tenantAPI.createFull({
        tenant: {
          name: formData.companyName,
          slug,
          company_name: formData.companyName,
          company_document: formData.document,
          company_document_type: formData.documentType
        },
        license: {
          modules: ['financeiro'],
          features: {},
          limits: {
            users: 5
          }
        },
        admin: {
          name: formData.adminName,
          email: formData.adminEmail,
          password: formData.adminPassword
        }
      });

      navigate('/login');
    } catch (error) {
      let errorMessage = 'Erro ao criar tenant';
      
      if (error instanceof Error) {
        // Tentar extrair mensagem de erro do Supabase
        try {
          const data = JSON.parse(error.message);
          if (data.message) {
            errorMessage = data.message;
          }
        } catch {
          errorMessage = error.message;
        }

        // Tratar mensagens específicas
        if (errorMessage.includes('já está em uso')) {
          errorMessage = errorMessage;
        } else if (errorMessage.includes('Já existe um registro')) {
          errorMessage = 'Já existe um tenant com esses dados';
        }
      }
      
      setSubmitError(errorMessage);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md mb-8">
        <div className="mx-auto w-12 h-12 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-xl flex items-center justify-center">
          <Building2 className="w-8 h-8 text-white" />
        </div>
        <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
          Criar nova conta
        </h2>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-4xl">
        <div className="bg-white py-8 px-6 shadow rounded-lg sm:px-10">
          <div className="mb-8 flex justify-between items-center">
            <div className="flex items-center space-x-4">
              <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
                currentStep === 'tenant' ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-600'
              }`}>
                <Building2 className="w-6 h-6" />
              </div>
              <div className="h-1 w-12 bg-gray-200" />
              <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
                currentStep === 'user' ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-600'
              }`}>
                <Building2 className="w-6 h-6" />
              </div>
            </div>
            <div className="text-sm text-gray-500">
              Etapa {currentStep === 'tenant' ? '1' : '2'} de 2
            </div>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Etapa 1: Dados da Empresa */}
            {currentStep === 'tenant' && (
              <div className="space-y-6">
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
                        setFormData(prev => ({
                          ...prev,
                          companyName: e.target.value
                        }));
                      }}
                      className={`pl-10 w-full rounded-lg border ${
                        errors.companyName ? 'border-red-300 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
                      } focus:ring-2 focus:border-transparent py-2`}
                      placeholder="Nome da empresa"
                    />
                    {errors.companyName && (
                      <div className="mt-1 text-sm text-red-600 flex items-center">
                        <AlertCircle className="h-4 w-4 mr-1" />
                        {errors.companyName}
                      </div>
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* Etapa 2: Dados do Usuário */}
            {currentStep === 'user' && (
              <div className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Nome do Administrador
                  </label>
                  <div className="relative">
                    <Building2 className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
                    <input
                      type="text"
                      value={formData.adminName}
                      onChange={(e) => setFormData(prev => ({
                        ...prev,
                        adminName: e.target.value
                      }))}
                      className={`pl-10 w-full rounded-lg border ${
                        errors.adminName ? 'border-red-300' : 'border-gray-300'
                      } focus:ring-2 focus:ring-blue-500 focus:border-transparent py-2`}
                      placeholder="Nome completo"
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
                    Email
                  </label>
                  <div className="relative">
                    <Building2 className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
                    <input
                      type="email"
                      value={formData.adminEmail}
                      onChange={(e) => setFormData(prev => ({
                        ...prev,
                        adminEmail: e.target.value
                      }))}
                      className={`pl-10 w-full rounded-lg border ${
                        errors.adminEmail ? 'border-red-300' : 'border-gray-300'
                      } focus:ring-2 focus:ring-blue-500 focus:border-transparent py-2`}
                      placeholder="admin@exemplo.com"
                    />
                    {errors.adminEmail && (
                      <div className="mt-1 text-sm text-red-600 flex items-center">
                        <AlertCircle className="h-4 w-4 mr-1" />
                        {errors.adminEmail}
                      </div>
                    )}
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Senha
                  </label>
                  <div className="relative">
                    <Building2 className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
                    <input
                      type="password"
                      value={formData.adminPassword}
                      onChange={(e) => setFormData(prev => ({
                        ...prev,
                        adminPassword: e.target.value
                      }))}
                      className={`pl-10 w-full rounded-lg border ${
                        errors.adminPassword ? 'border-red-300' : 'border-gray-300'
                      } focus:ring-2 focus:ring-blue-500 focus:border-transparent py-2`}
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
                    <Building2 className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
                    <input
                      type="password"
                      value={formData.adminConfirmPassword}
                      onChange={(e) => setFormData(prev => ({
                        ...prev,
                        adminConfirmPassword: e.target.value
                      }))}
                      className={`pl-10 w-full rounded-lg border ${
                        errors.adminConfirmPassword ? 'border-red-300' : 'border-gray-300'
                      } focus:ring-2 focus:ring-blue-500 focus:border-transparent py-2`}
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
            )}

            {submitError && (
              <div className="rounded-md bg-red-50 p-4">
                <div className="flex">
                  <div className="flex-shrink-0">
                    <AlertCircle className="h-5 w-5 text-red-400" />
                  </div>
                  <div className="ml-3">
                    <h3 className="text-sm font-medium text-red-800">
                      Erro ao criar conta
                    </h3>
                    <div className="mt-2 text-sm text-red-700">
                      {submitError}
                    </div>
                  </div>
                </div>
              </div>
            )}

            <div className="flex justify-between pt-6">
              {currentStep !== 'tenant' && (
                <button
                  type="button"
                  onClick={handleBack}
                  className="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  <ChevronLeft className="h-5 w-5 mr-2" />
                  Voltar
                </button>
              )}

              {currentStep === 'user' ? (
                <button
                  type="submit"
                  disabled={isLoading}
                  className="ml-auto inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isLoading ? (
                    <>
                      <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2" />
                      Criando...
                    </>
                  ) : (
                    'Criar Conta'
                  )}
                </button>
              ) : (
                <button
                  type="button"
                  onClick={handleNext}
                  className="ml-auto inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  Próximo
                  <ChevronRight className="h-5 w-5 ml-2" />
                </button>
              )}
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}