import React, { useState, useEffect } from 'react';
import { supabase } from '../supabaseClient';
import { Search, Filter, Download, Trash2, Loader2 } from 'lucide-react';

const ProductionLogs = () => {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [deletingId, setDeletingId] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchLogs();

    const channel = supabase
      .channel('production_logs_realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'production_logs' }, payload => {
        if (payload.eventType === 'INSERT') {
          setLogs(prev => [payload.new, ...prev].sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp)));
        } else if (payload.eventType === 'UPDATE') {
          setLogs(prev => prev.map(log => log.id === payload.new.id ? payload.new : log));
        } else if (payload.eventType === 'DELETE') {
          setLogs(prev => prev.filter(log => log.id !== payload.old.id));
        }
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
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

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this log? This cannot be undone.')) return;
    
    try {
      setDeletingId(id);
      const { error } = await supabase
        .from('production_logs')
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
                  <th style={{ textAlign: 'right' }}>Actions</th>
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
                    <td style={{ textAlign: 'right' }}>
                      <button 
                         className="btn-icon-danger" 
                         aria-label="Delete log"
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
                    <td colSpan="10" style={{ textAlign: 'center', padding: '40px' }}>No logs found.</td>
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
