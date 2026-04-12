import React, { useState, useEffect, useMemo } from 'react';
import { supabase } from '../supabaseClient';
import { Coins, TrendingUp } from 'lucide-react';

const Economics = () => {
  const [logs, setLogs] = useState([]);
  const [feedPrice, setFeedPrice] = useState(35); // Default 35 PHP
  const [eggPrice, setEggPrice] = useState(5);   // Default 5 PHP
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchLogs();
  }, []);

  const fetchLogs = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('production_logs')
        .select('*');
      if (error) throw error;
      setLogs(data || []);
    } catch (error) {
      console.error('Error fetching logs:', error);
    } finally {
      setLoading(false);
    }
  };

  // Group and calculate
  const groupedData = useMemo(() => {
    const acc = {};
    const len = logs.length;
    for (let i = 0; i < len; i++) {
      const log = logs[i];
      if (!acc[log.treatment]) acc[log.treatment] = { eggs: 0, feed: 0, count: 0 };
      acc[log.treatment].eggs += log.eggs || 0;
      acc[log.treatment].feed += (log.feedgiven || 0) / 1000; // Convert to kg
      acc[log.treatment].count += 1;
    }
    return acc;
  }, [logs]);

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Economic Efficiency</h1>
          <p className="page-subtitle">Analyze profitability based on feed intake vs output value.</p>
        </div>
      </div>

      <div className="filters-row" style={{ marginBottom: '24px', display: 'flex', gap: '16px', flexWrap: 'wrap' }}>
        <div className="input-group">
          <label>Feed Price / kg (₱)</label>
          <input 
            type="number" 
            value={feedPrice} 
            onChange={(e) => setFeedPrice(Number(e.target.value))} 
            className="styled-input"
          />
        </div>
        <div className="input-group">
          <label>Egg Price / Piece (₱)</label>
          <input 
            type="number" 
            value={eggPrice} 
            onChange={(e) => setEggPrice(Number(e.target.value))} 
            className="styled-input"
          />
        </div>
      </div>

      <div className="stats-grid">
         {Object.entries(groupedData).map(([treatment, data]) => {
           const revenue = data.eggs * eggPrice;
           const cost = data.feed * feedPrice;
           const profit = revenue - cost;
           const roi = cost > 0 ? (profit / cost) * 100 : 0;

           return (
             <div className="stat-card" key={treatment}>
               <div className="stat-header">
                 <span className="badge">Treatment {treatment}</span>
                 <Coins size={20} className="text-muted" />
               </div>
               <div className="stat-main">
                 <div className="stat-group">
                   <label>Total Revenue</label>
                   <div className="stat-value">₱{revenue.toLocaleString()}</div>
                 </div>
                 <div className="stat-group">
                   <label>Feed Cost</label>
                   <div className="stat-value text-red">₱{cost.toLocaleString(undefined, {maximumFractionDigits: 2})}</div>
                 </div>
                 <div className="stat-group highlighted">
                   <label>Estimated Profit</label>
                   <div className="stat-value text-emerald">₱{profit.toLocaleString(undefined, {maximumFractionDigits: 2})}</div>
                 </div>
               </div>
               <div className="stat-footer">
                  <TrendingUp size={16} />
                  <span>ROI: {roi.toFixed(1)}%</span>
               </div>
             </div>
           );
         })}
         {Object.keys(groupedData).length === 0 && !loading && (
           <div className="empty-state">No production data available for analysis.</div>
         )}
      </div>
    </div>
  );
};

export default Economics;
