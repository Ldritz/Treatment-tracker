import React, { useState, useEffect } from 'react';
import { supabase } from '../supabaseClient';
import { Search, Filter, Download } from 'lucide-react';

const ProductionLogs = () => {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchLogs();
  }, []);

  const fetchLogs = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('production_logs')
        .select('*')
        .order('timestamp', { ascending: false });

      if (error) throw error;
      setLogs(data || []);
    } catch (error) {
      console.error('Error fetching logs:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredLogs = logs.filter(log => 
    `T${log.treatment}-B${log.block}`.toLowerCase().includes(searchTerm.toLowerCase()) ||
    log.recordedby?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Daily Production Logs</h1>
          <p className="page-subtitle">Historical records of egg counts, feed intake, and HDEP.</p>
        </div>
        <div className="header-actions">
           <div className="search-box">
             <Search size={18} />
             <input 
               type="text" 
               placeholder="Search treatment or researcher..." 
               value={searchTerm}
               onChange={(e) => setSearchTerm(e.target.value)}
             />
           </div>
        </div>
      </div>

      <div className="data-card">
        {loading ? (
          <div className="loading-state">Loading logs...</div>
        ) : (
          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Unit</th>
                  <th>Quails</th>
                  <th>Eggs</th>
                  <th>Egg Mass</th>
                  <th>Feed Given</th>
                  <th>FCR</th>
                  <th>HDEP%</th>
                  <th>Researcher</th>
                </tr>
              </thead>
              <tbody>
                {filteredLogs.map(log => (
                  <tr key={log.id}>
                    <td>{new Date(log.timestamp).toLocaleDateString()}</td>
                    <td><span className="badge">T{log.treatment}-B{log.block}</span></td>
                    <td>{log.quails}</td>
                    <td>{log.eggs}</td>
                    <td>{log.eggmass?.toFixed(1) || '-'}g</td>
                    <td>{log.feedgiven}g</td>
                    <td>{log.fcr?.toFixed(2) || '-'}</td>
                    <td><span className="badge-blue">{log.hdep?.toFixed(1) || 0}%</span></td>
                    <td>{log.recordedby || '-'}</td>
                  </tr>
                ))}
                {filteredLogs.length === 0 && (
                  <tr>
                    <td colSpan="9" style={{ textAlign: 'center', padding: '40px' }}>No logs found.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default ProductionLogs;
