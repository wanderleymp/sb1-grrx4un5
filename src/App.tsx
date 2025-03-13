import React from 'react';
import { BrowserRouter as Router, Routes, Route, useNavigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { Header } from './components/layout/Header';
import { TenantRegistration } from './pages/auth/TenantRegistration';
import { SaaSManagement } from './pages/saas/SaaSManagement';
import { Chat } from './pages/Chat';
import { UserManagement } from './pages/users/UserManagement';
import { PermissionManagement } from './pages/saas/PermissionManagement';
import { Dashboard } from './pages/Dashboard';
import { Login } from './pages/auth/Login';
import { Register } from './pages/auth/Register';
import { PrivateRoute } from './components/auth/PrivateRoute';
import { Briefcase, MessageSquare, Users, TicketCheck, LineChart } from 'lucide-react';

function App() {
  return (
    <Router>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/register/tenant" element={<TenantRegistration />} />
          <Route
            path="/*"
            element={
              <PrivateRoute>
                <div className="min-h-screen bg-gradient-to-b from-gray-50 to-gray-100">
                  <Header />
                  <main className="container mx-auto px-4 py-8">
                    <Routes>
                      <Route path="/" element={<Dashboard />} />
                      <Route path="/saas" element={<SaaSManagement />} />
                      <Route path="/chat" element={<Chat />} />
                      <Route path="/permissions" element={<PermissionManagement />} />
                      <Route path="/users" element={<UserManagement />} />
                      <Route path="/dashboard" element={<Dashboard />} />
                    </Routes>
                  </main>
                </div>
              </PrivateRoute>
            }
          />
        </Routes>
      </AuthProvider>
    </Router>
  );
}

export default App;