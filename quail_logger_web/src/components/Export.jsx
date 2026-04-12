import React, { useState } from 'react';
import { supabase } from '../supabaseClient';
import { Download, FileSpreadsheet, Loader2 } from 'lucide-react';

const Export = () => {
  const [downloading, setDownloading] = useState(false);

  const exportAllData = async () => {
    try {
      setDownloading(true);
      
      // Fetch both tables
      const { data: prodLogs } = await supabase.from('production_logs').select('*').order('timestamp');
      const { data: eggLogs } = await supabase.from('egg_logs').select('*').order('timestamp');

      const rows = [];
      rows.push('SECTION: DAILY PRODUCTION DATA');
      rows.push('ID,Date,Treatment,Block,Quails,Eggs,EggMass(g),FeedGiven(g),FCR,HDEP(%),RecordedBy');
      
      prodLogs?.forEach(log => {
        rows.push(`${log.id},${log.timestamp},${log.treatment},${log.block},${log.quails},${log.eggs},${log.eggmass},${log.feedgiven},${log.fcr},${log.hdep},"${log.recordedby || ''}"`);
      });

      rows.push('\n\nSECTION: EGG QUALITY DATA');
      rows.push('ID,Date,Treatment,Block,Weight(g),Length(mm),Width(mm),AlbumenHt(mm),ShellWt(g),YolkWt(g),HaughUnit,RecordedBy');

      eggLogs?.forEach(log => {
        rows.push(`${log.id},${log.timestamp},${log.treatment},${log.block},${log.weight},${log.length},${log.width},${log.albumenheight},${log.shellweight},${log.yolkweight},${log.haughunit},"${log.recordedby || ''}"`);
      });

      const csvContent = rows.join('\n');

      // Create download link
      const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.setAttribute('href', url);
      link.setAttribute('download', `CoturniSync_Export_${new Date().toISOString().split('T')[0]}.csv`);
      link.style.visibility = 'hidden';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
    } catch (error) {
      console.error('Export failed:', error);
      alert('Failed to generate export file. Please check your connection.');
    } finally {
      setDownloading(false);
    }
  };

  return (
    <div className="page-container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Data Export</h1>
          <p className="page-subtitle">Download your complete research data for analysis in JASP, SPSS, or Excel.</p>
        </div>
      </div>

      <div className="export-card">
        <div className="export-icon-container">
          <FileSpreadsheet size={64} className="text-emerald" />
        </div>
        <h2>Consolidated CSV Export</h2>
        <p>This will generate a single CSV file containing all daily production logs and egg quality assessments synced from your mobile devices.</p>
        
        <button 
          className="btn-primary" 
          onClick={exportAllData} 
          disabled={downloading}
          style={{ width: '100%', marginTop: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}
        >
          {downloading ? (
            <>
              <Loader2 className="animate-spin" size={20} />
              Generating File...
            </>
          ) : (
            <>
              <Download size={20} />
              Download Research CSV
            </>
          )}
        </button>
      </div>

      <style dangerouslySetInnerHTML={{ __html: `
        .export-card {
          max-width: 500px;
          margin: 40px auto;
          background: rgba(255, 255, 255, 0.05);
          backdrop-filter: blur(10px);
          border: 1px solid rgba(255, 255, 255, 0.1);
          border-radius: 24px;
          padding: 40px;
          text-align: center;
        }
        .export-icon-container {
          background: rgba(16, 185, 129, 0.1);
          width: 100px;
          height: 100px;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          margin: 0 auto 24px;
        }
        .text-emerald { color: #10b981; }
        .animate-spin { animation: spin 1s linear infinite; }
        @keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
      `}} />
    </div>
  );
};

export default Export;
