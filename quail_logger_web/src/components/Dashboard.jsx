import React, { useEffect, useState } from 'react';
import { supabase } from '../supabaseClient';
import { Loader2, TrendingUp, Egg, Activity, Smartphone, X, ChartLine } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';
import TrendChart from './TrendChart.jsx';

export default function Dashboard() {
  const [loading, setLoading] = useState(true);
  const [showPairing, setShowPairing] = useState(false);
  const [productionLogs, setProductionLogs] = useState([]);
  const [eggLogs, setEggLogs] = useState([]);
  const [stats, setStats] = useState({ totalEggs: 0, avgHdep: 0, avgHaugh: 0 });

  // Get Supabase config for pairing
  const sUrl = import.meta.env.VITE_SUPABASE_URL;
  const sKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
  const baseUrl = window.location.origin;
  const pairingLink = `${baseUrl}/connect?u=${sUrl}&k=${sKey}`;

  useEffect(() => {
    fetchData();
  }, []);

  async function fetchData() {
    try {
      setLoading(true);
      
      const { data: prodData, error: prodErr } = await supabase
        .from('production_logs')
        .select('*')
        .order('timestamp', { ascending: false });
        
      if (prodErr) throw prodErr;
      
      const { data: eggData, error: eggErr } = await supabase
        .from('egg_logs')
        .select('*')
        .order('timestamp', { ascending: false });
        
      if (eggErr) throw eggErr;

      setProductionLogs(prodData || []);
      setEggLogs(eggData || []);
      
      // Calculate basic stats
      let total = 0;
      let hdepSum = 0;
      let prodCount = 0;
      
      (prodData || []).forEach(log => {
        total += log.eggs || 0;
        if (log.hdep) {
          hdepSum += log.hdep;
          prodCount++;
        }
      });
      
      let haughSum = 0;
      let eggCount = 0;
      (eggData || []).forEach(log => {
        if (log.haughunit) {
          haughSum += log.haughunit;
          eggCount++;
        }
      });

      setStats({
        totalEggs: total,
        avgHdep: prodCount > 0 ? (hdepSum / prodCount).toFixed(1) : 0,
        avgHaugh: eggCount > 0 ? (haughSum / eggCount).toFixed(1) : 0
      });
      
    } catch (error) {
      console.error("Error fetching data:", error);
    } finally {
      setLoading(false);
    }
  }

  // Process data for charts (last 7 logs)
  const chartData = [...productionLogs]
    .slice(0, 7)
    .reverse()
    .map(log => ({
      date: new Date(log.timestamp).toLocaleDateString([], { month: 'short', day: 'numeric' }),
      hdep: log.hdep || 0,
      vfi: log.vfi || 0
    }));

  if (loading) {
    return (
      <div className="loading">
        <Loader2 size={48} className="spinner" />
      </div>
    );
  }

  return (
    <div className="fade-in">
      <div className="page-header">
        <div>
          <h2>Overview</h2>
          <p style={{ color: 'var(--text-muted)', marginTop: '0.5rem' }}>Synched from your device via Supabase</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <button className="btn-secondary" onClick={() => setShowPairing(true)}>
            <Smartphone size={18} />
            Connect Mobile App
          </button>
          <button className="premium" onClick={fetchData}>
            Refresh Data
          </button>
        </div>
      </div>

      <div className="stat-grid">
        <div className="stat-card fade-in delay-1">
          <div className="stat-icon"><Egg size={24} /></div>
          <div>
            <div className="stat-title">Total Eggs Logged</div>
            <div className="stat-value">{stats.totalEggs}</div>
          </div>
        </div>
        
        <div className="stat-card fade-in delay-2">
          <div className="stat-icon"><TrendingUp size={24} /></div>
          <div>
            <div className="stat-title">Avg HDEP %</div>
            <div className="stat-value">{stats.avgHdep}%</div>
          </div>
        </div>
        
        <div className="stat-card fade-in delay-3">
          <div className="stat-icon"><Activity size={24} /></div>
          <div>
            <div className="stat-title">Avg Haugh Unit</div>
            <div className="stat-value">{stats.avgHaugh}</div>
          </div>
        </div>
      </div>

      <div className="section-header">
        <h3>Performance Trends (Last 7 Days)</h3>
        <p>Scientific stability tracking across all experimental units</p>
      </div>

      <div className="charts-container fade-in delay-2">
        <TrendChart 
          title="HDEP Trend" 
          data={chartData} 
          color="#10B981" 
          dataKey="hdep" 
          maxY={100} 
          unit="%" 
        />
        <TrendChart 
          title="VFI Trend" 
          data={chartData} 
          color="#F59E0B" 
          dataKey="vfi" 
          maxY={45} 
          unit="g" 
        />
      </div>

      <h3 style={{ marginBottom: '1.5rem', marginTop: '3rem' }}>Recent Production Logs</h3>
      <div className="table-container fade-in delay-2" style={{ marginBottom: '3rem' }}>
        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Date</th>
                <th>Grid/Pen</th>
                <th>Hen Count</th>
                <th>Eggs</th>
                <th>Feed Intake</th>
                <th>HDEP</th>
                <th>Researcher</th>
              </tr>
            </thead>
            <tbody>
              {productionLogs.slice(0, 10).map(log => (
                 <tr key={log.id}>
                   <td>{new Date(log.timestamp).toLocaleDateString()}</td>
                   <td><span className="badge">T{log.treatment}-B{log.block}</span></td>
                   <td>{log.quails}</td>
                   <td>{log.eggs}</td>
                   <td>{log.feedgiven}g</td>
                   <td><span className="badge" style={{ backgroundColor: 'rgba(59, 130, 246, 0.1)', color: '#3b82f6' }}>{log.hdep ? log.hdep.toFixed(1) : 0}%</span></td>
                   <td>{log.recordedby || '-'}</td>
                 </tr>
              ))}
              {productionLogs.length === 0 && (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                    No production logs synced yet.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
      
      <h3 style={{ marginBottom: '1.5rem' }}>Recent Egg Lab Logs</h3>
      <div className="table-container fade-in delay-3">
        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Date</th>
                <th>Grid/Pen</th>
                <th>Egg Weight</th>
                <th>Albumen Ht.</th>
                <th>Haugh Unit</th>
                <th>Researcher</th>
              </tr>
            </thead>
            <tbody>
              {eggLogs.slice(0, 10).map(log => (
                 <tr key={log.id}>
                   <td>{new Date(log.timestamp).toLocaleDateString()}</td>
                   <td><span className="badge" style={{ backgroundColor: 'rgba(139, 92, 246, 0.1)', color: '#8b5cf6' }}>T{log.treatment}-B{log.block}</span></td>
                   <td>{log.weight}g</td>
                   <td>{log.albumenheight}mm</td>
                   <td><span className="badge" style={{ backgroundColor: 'rgba(52, 211, 153, 0.1)', color: '#34d399' }}>{log.haughunit ? log.haughunit.toFixed(1) : 0}</span></td>
                   <td>{log.recordedby || '-'}</td>
                 </tr>
              ))}
              {eggLogs.length === 0 && (
                <tr>
                  <td colSpan="6" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                    No egg lab logs synced yet.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {showPairing && (
        <div className="modal-overlay" onClick={() => setShowPairing(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()} role="dialog" aria-modal="true" aria-labelledby="modal-title">
            <button className="modal-close" aria-label="Close modal" onClick={() => setShowPairing(false)}>
              <X size={24} />
            </button>
            <h2 id="modal-title" style={{ marginBottom: '1rem' }}>Connect Mobile App</h2>
            <p style={{ color: 'var(--text-muted)', marginBottom: '1.5rem' }}>
              Scan this QR code with the Quail Logger mobile app to link your devices and enable cloud sync.
            </p>
            
            <div className="qr-container">
              <QRCodeSVG 
                value={pairingLink} 
                size={220}
                level="H"
                includeMargin={true}
              />
            </div>

            <div className="qr-instructions">
              <h4 style={{ marginBottom: '0.75rem' }}>How to link:</h4>
              <ol>
                <li>Open <strong>Quail Logger</strong> on your phone</li>
                <li>Go to <strong>Settings</strong></li>
                <li>Tap <strong>Connect</strong> in the Cloud Sync section</li>
                <li>Point your camera at this screen</li>
              </ol>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
