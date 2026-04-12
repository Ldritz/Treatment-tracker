import React, { useState, useEffect } from 'react';
import { supabase } from '../supabaseClient';
import { Search, FlaskConical, Trash2, Loader2 } from 'lucide-react';

const EggLabLogs = () => {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [deletingId, setDeletingId] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchLogs();
  }, []);

  const fetchLogs = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('egg_logs')
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

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this lab entry?')) return;
    
    try {
      setDeletingId(id);
      const { error } = await supabase
        .from('egg_logs')
        .delete()
        .eq('id', id);

      if (error) throw error;
      setLogs(logs.filter(log => log.id !== id));
    } catch (error) {
      console.error('Delete failed:', error);
      alert('Delete failed. Ensure you have permissions to delete records.');
    } finally {
      setDeletingId(null);
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
          <h1 className="page-title">Egg Lab Quality Data</h1>
          <p className="page-subtitle">Detailed metrics for egg mass, shell quality, and internal height.</p>
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
          <div className="loading-state">Loading egg lab data...</div>
        ) : (
          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Unit</th>
                  <th>Weight</th>
                  <th>Length</th>
                  <th>Width</th>
                  <th>Shape Index</th>
                  <th>Albumen Ht</th>
                  <th>Shell Wt</th>
                  <th>Yolk Wt</th>
                  <th>Haugh Unit</th>
                  <th>Researcher</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredLogs.map(log => (
                  <tr key={log.id}>
                    <td>{new Date(log.timestamp).toLocaleDateString()}</td>
                    <td><span className="badge-purple">T{log.treatment}-B{log.block}</span></td>
                    <td>{log.weight?.toFixed(2)}g</td>
                    <td>{log.length?.toFixed(2)}mm</td>
                    <td>{log.width?.toFixed(2)}mm</td>
                    <td><span className="badge-blue">{log.shapeindex?.toFixed(1) || '-'}</span></td>
                    <td>{log.albumenheight?.toFixed(2)}mm</td>
                    <td>{log.shellweight?.toFixed(2)}g</td>
                    <td>{log.yolkweight?.toFixed(2)}g</td>
                    <td><span className="badge-green">{log.haughunit?.toFixed(1) || 0}</span></td>
                    <td>{log.recordedby || '-'}</td>
                    <td style={{ textAlign: 'right' }}>
                      <button 
                         className="btn-icon-danger" 
                         aria-label="Delete lab entry"
                         onClick={() => handleDelete(log.id)}
                         disabled={deletingId === log.id}
                      >
                        {deletingId === log.id ? <Loader2 size={16} className="spinner" /> : <Trash2 size={16} />}
                      </button>
                    </td>
                  </tr>
                ))}
                {filteredLogs.length === 0 && (
                  <tr>
                    <td colSpan="12" style={{ textAlign: 'center', padding: '40px' }}>No egg lab data found.</td>
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

export default EggLabLogs;
