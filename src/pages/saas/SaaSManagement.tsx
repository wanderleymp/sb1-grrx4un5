import React from 'react';
import { useNavigate } from 'react-router-dom';
import { LicenseList } from './LicenseList';
import { TenantList } from './TenantList';
import { Users, Package, Settings, Activity } from 'lucide-react';
import * as Tabs from '@radix-ui/react-tabs';

export function SaaSManagement() {
  const navigate = useNavigate();

  return (
    <div className="space-y-8">
      <Tabs.Root defaultValue="licenses" className="space-y-6">
        <Tabs.List className="flex space-x-1 border-b border-gray-200">
          <Tabs.Trigger
            value="licenses"
            className="px-4 py-2 text-sm font-medium text-gray-500 hover:text-gray-700 border-b-2 border-transparent data-[state=active]:border-blue-500 data-[state=active]:text-blue-600"
          >
            Licenças
          </Tabs.Trigger>
          <Tabs.Trigger
            value="tenants"
            className="px-4 py-2 text-sm font-medium text-gray-500 hover:text-gray-700 border-b-2 border-transparent data-[state=active]:border-blue-500 data-[state=active]:text-blue-600"
          >
            Tenants
          </Tabs.Trigger>
        </Tabs.List>

        <Tabs.Content value="licenses">
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <div className="flex items-center space-x-3">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Users className="h-6 w-6 text-blue-600" />
            </div>
            <div>
              <p className="text-sm text-gray-600">Total de Clientes</p>
              <p className="text-2xl font-bold text-gray-900">1,234</p>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <div className="flex items-center space-x-3">
            <div className="p-2 bg-green-100 rounded-lg">
              <Package className="h-6 w-6 text-green-600" />
            </div>
            <div>
              <p className="text-sm text-gray-600">Licenças Ativas</p>
              <p className="text-2xl font-bold text-gray-900">856</p>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <div className="flex items-center space-x-3">
            <div className="p-2 bg-purple-100 rounded-lg">
              <Settings className="h-6 w-6 text-purple-600" />
            </div>
            <div>
              <p className="text-sm text-gray-600">Módulos Ativos</p>
              <p className="text-2xl font-bold text-gray-900">5,678</p>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <div className="flex items-center space-x-3">
            <div className="p-2 bg-orange-100 rounded-lg">
              <Activity className="h-6 w-6 text-orange-600" />
            </div>
            <div>
              <p className="text-sm text-gray-600">Taxa de Uso</p>
              <p className="text-2xl font-bold text-gray-900">92%</p>
            </div>
          </div>
        </div>
      </div>

          <div className="mt-8">
            <LicenseList />
          </div>
          <div className="mt-4 text-center">
            <button
              onClick={() => navigate('/register/tenant')}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
            >
              Criar Novo Tenant
            </button>
          </div>
        </Tabs.Content>

        <Tabs.Content value="tenants">
          <TenantList />
        </Tabs.Content>
      </Tabs.Root>
    </div>
  );
}