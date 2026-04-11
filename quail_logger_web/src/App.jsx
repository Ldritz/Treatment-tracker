import React from 'react';
import { BrowserRouter as Router, Routes, Route, NavLink } from 'react-router-dom';
import Dashboard from './components/Dashboard';
import ProductionLogs from './components/ProductionLogs';
import EggLabLogs from './components/EggLabLogs';
import Economics from './components/Economics';
import Export from './components/Export';
import ResearchAnalysis from './components/ResearchAnalysis';
import { LayoutDashboard, ClipboardList, FlaskConical, Coins, Download, Beaker } from 'lucide-react';

function App() {
  return (
    <Router>
      <div className="layout">
        <aside className="sidebar">
          <div className="sidebar-header">
            <h1 className="app-title">CoturniSync Web</h1>
          </div>
          <nav className="nav-links">
            <NavLink to="/" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
              <LayoutDashboard size={20} />
              Dashboard
            </NavLink>
            <NavLink to="/production" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
              <ClipboardList size={20} />
              Daily Logs
            </NavLink>
            <NavLink to="/egg-lab" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
              <FlaskConical size={20} />
              Egg Lab
            </NavLink>
            <NavLink to="/analysis" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
              <Beaker size={20} />
              Research Analysis
            </NavLink>
            <NavLink to="/economics" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
              <Coins size={20} />
              Economics
            </NavLink>
            <NavLink to="/export" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
              <Download size={20} />
              Export
            </NavLink>
          </nav>
        </aside>
        
        <main className="main-content">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/production" element={<ProductionLogs />} />
            <Route path="/egg-lab" element={<EggLabLogs />} />
            <Route path="/analysis" element={<ResearchAnalysis />} />
            <Route path="/economics" element={<Economics />} />
            <Route path="/export" element={<Export />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;
