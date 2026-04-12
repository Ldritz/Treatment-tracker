import React from 'react';
import { 
  LineChart, 
  Line, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer, 
  Area, 
  AreaChart 
} from 'recharts';

export default function TrendChart({ title, data, color, dataKey, maxY, unit = '' }) {
  const gradientId = `color-${dataKey}`;

  return (
    <div className="trend-card">
      <div className="trend-header">
        <h4 className="trend-title">{title}</h4>
      </div>
      <div className="trend-content" style={{ width: '100%', height: 200, marginTop: '1rem' }}>
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={data}>
            <defs>
              <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor={color} stopOpacity={0.3}/>
                <stop offset="95%" stopColor={color} stopOpacity={0}/>
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(255,255,255,0.05)" />
            <XAxis 
              dataKey="date" 
              axisLine={false} 
              tickLine={false} 
              tick={{ fill: 'rgba(255,255,255,0.5)', fontSize: 10 }}
              dy={10}
            />
            <YAxis 
              hide={true} 
              domain={[0, maxY || 'auto']} 
            />
            <Tooltip 
              contentStyle={{ 
                backgroundColor: '#1e293b', 
                border: 'none', 
                borderRadius: '8px', 
                boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.3)',
                fontSize: '12px',
                color: '#f8fafc'
              }}
              itemStyle={{ color: color }}
              formatter={(value) => [`${value}${unit}`, title]}
              labelStyle={{ marginBottom: '4px', opacity: 0.7 }}
            />
            <Area 
              type="monotone" 
              dataKey={dataKey} 
              stroke={color} 
              strokeWidth={3}
              fillOpacity={1} 
              fill={`url(#${gradientId})`} 
              animationDuration={1500}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
