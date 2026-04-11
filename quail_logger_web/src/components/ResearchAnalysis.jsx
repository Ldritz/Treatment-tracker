import React, { useState, useEffect } from 'react';
import { supabase } from '../supabaseClient';
import { TREATMENT_MAP, FACTORS } from '../constants/researchDesign';
import { Beaker, Sun, Clock, Zap, Target, TrendingUp } from 'lucide-react';

const ResearchAnalysis = () => {
  const [prodLogs, setProdLogs] = useState([]);
  const [eggLogs, setEggLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeMetric, setActiveMetric] = useState('hdep'); // hdep, fcr, haugh

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [prodRes, eggRes] = await Promise.all([
        supabase.from('production_logs').select('*'),
        supabase.from('egg_logs').select('*')
      ]);

      setProdLogs(prodRes.data || []);
      setEggLogs(eggRes.data || []);
    } catch (error) {
      console.error('Error fetching research data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getAggregatedData = () => {
    const matrix = {};
    
    // Initialize matrix
    FACTORS.duration.forEach(dur => {
      matrix[dur] = {};
      FACTORS.intensity.forEach(int => {
        matrix[dur][int] = { hdep: [], fcr: [], haugh: [], count: 0 };
      });
    });

    // Process production logs for HDEP and FCR
    prodLogs.forEach(log => {
      const mapping = TREATMENT_MAP[log.treatment];
      if (mapping) {
        const cell = matrix[mapping.duration][mapping.intensity];
        if (log.hdep) cell.hdep.push(log.hdep);
        if (log.fcr) cell.fcr.push(log.fcr);
        cell.count += 1;
      }
    });

    // Process egg logs for Haugh Unit
    eggLogs.forEach(log => {
      const mapping = TREATMENT_MAP[log.treatment];
      if (mapping) {
        const cell = matrix[mapping.duration][mapping.intensity];
        if (log.haughunit) cell.haugh.push(log.haughunit);
      }
    });

    // Calculate averages
    const averages = {};
    Object.keys(matrix).forEach(dur => {
      averages[dur] = {};
      Object.keys(matrix[dur]).forEach(int => {
        const cell = matrix[dur][int];
        averages[dur][int] = {
          hdep: cell.hdep.length ? cell.hdep.reduce((a, b) => a + b, 0) / cell.hdep.length : 0,
          fcr: cell.fcr.length ? cell.fcr.reduce((a, b) => a + b, 0) / cell.fcr.length : 0,
          haugh: cell.haugh.length ? cell.haugh.reduce((a, b) => a + b, 0) / cell.haugh.length : 0
        };
      });
    });

    return averages;
  };

  const data = getAggregatedData();

  const getBestCombination = () => {
    let best = { dur: '', int: '', val: activeMetric === 'fcr' ? Infinity : -Infinity };
    Object.keys(data).forEach(dur => {
      Object.keys(data[dur]).forEach(int => {
        const val = data[dur][int][activeMetric];
        if (val === 0) return;
        if (activeMetric === 'fcr') {
           if (val < best.val) best = { dur, int, val };
        } else {
           if (val > best.val) best = { dur, int, val };
        }
      });
    });
    return best;
  };

  const best = getBestCombination();

  if (loading) return <div className="loading-state">Analyzing study interactions...</div>;

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Research Analysis & Interaction</h1>
          <p className="page-subtitle">Evaluation of Light Intensity x Duration interactions on Quail performance.</p>
        </div>
        <div className="header-actions">
           <div className="tab-group">
             <button 
                className={`tab-btn ${activeMetric === 'hdep' ? 'active' : ''}`}
                onClick={() => setActiveMetric('hdep')}
             >HDEP%</button>
             <button 
                className={`tab-btn ${activeMetric === 'fcr' ? 'active' : ''}`}
                onClick={() => setActiveMetric('fcr')}
             >FCR</button>
             <button 
                className={`tab-btn ${activeMetric === 'haugh' ? 'active' : ''}`}
                onClick={() => setActiveMetric('haugh')}
             >Haugh Unit</button>
           </div>
        </div>
      </div>

      <div className="stats-grid" style={{ marginBottom: '2rem' }}>
        <div className="stat-card">
          <div className="stat-header">
            <span>Optimal Combination</span>
            <Target size={20} className="text-emerald" />
          </div>
          <div className="stat-main">
            <div className="stat-value" style={{ fontSize: '1.5rem' }}>
              {best.dur && best.int ? `${best.dur} @ ${best.int}` : 'Insufficient Data'}
            </div>
            <label>Based on highest {activeMetric.toUpperCase()}</label>
          </div>
        </div>
        
        <div className="stat-card">
          <div className="stat-header">
             <span>Best Observed {activeMetric.toUpperCase()}</span>
             <TrendingUp size={20} className="text-blue" />
          </div>
          <div className="stat-main">
             <div className="stat-value">
               {best.val !== Infinity && best.val !== -Infinity ? best.val.toFixed(2) : '-'}
               <span style={{ fontSize: '1rem', marginLeft: '4px' }}>
                 {activeMetric === 'hdep' ? '%' : ''}
               </span>
             </div>
          </div>
        </div>
      </div>

      <div className="data-card">
        <h3 style={{ marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Zap size={20} className="text-yellow" />
          Interaction Matrix: {activeMetric.toUpperCase()}
        </h3>
        <div className="table-wrapper">
          <table className="data-table matrix-table">
            <thead>
              <tr>
                <th style={{ backgroundColor: 'transparent' }}></th>
                {FACTORS.intensity.map(int => (
                  <th key={int} style={{ textAlign: 'center' }}>
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                      <Sun size={16} style={{ marginBottom: '4px' }} />
                      {int}
                    </div>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {FACTORS.duration.map(dur => (
                <tr key={dur}>
                  <td style={{ fontWeight: '600', color: 'var(--text-primary)', borderRight: '1px solid var(--border)' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <Clock size={16} className="text-muted" />
                      {dur}
                    </div>
                  </td>
                  {FACTORS.intensity.map(int => {
                    const value = data[dur][int][activeMetric];
                    const isBest = (dur === best.dur && int === best.int);
                    return (
                      <td key={int} style={{ textAlign: 'center', padding: '1.5rem' }}>
                        <div className={`matrix-cell ${isBest ? 'best' : ''}`}>
                          {value ? value.toFixed(2) : '-'}
                        </div>
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="info-box" style={{ marginTop: '2rem' }}>
        <h4 style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '12px' }}>
          <Beaker size={18} />
          About this Analysis
        </h4>
        <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', lineHeight: '1.6' }}>
          This matrix presents the mean performance for each Factorial Combination (Factor A: Duration x Factor B: Intensity). 
          The "Optimal Combination" is automatically highlighted based on your selected metric. 
          Use this to determine significant trends and interactions for your study results section.
        </p>
      </div>
    </div>
  );
};

export default ResearchAnalysis;
