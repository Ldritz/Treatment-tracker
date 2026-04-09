"use client";

import React, { useState, useEffect } from 'react';
import { format } from 'date-fns';
import { Header } from '@/components/Header';
import { Navigation } from '@/components/Navigation';
import { InteractiveEggDiagram } from '@/components/InteractiveEggDiagram';
import { QualityLabForm, QualityFormData } from '@/components/QualityLabForm';
import { Download, WifiOff, Wifi, Clock, ChevronRight } from 'lucide-react';

export default function QualityLab() {
  const [selectedDate, setSelectedDate] = useState(format(new Date(), 'yyyy-MM-dd'));
  const [logs, setLogs] = useState<QualityFormData[]>([]);
  const [activeDraft, setActiveDraft] = useState<QualityFormData | null>(null);
  const [scrollToRegion, setScrollToRegion] = useState<string | undefined>();

  const [isOnline, setIsOnline] = useState(true);
  const [unsyncedCount, setUnsyncedCount] = useState(0);

  // Load existing data when date changes
  useEffect(() => {
    const loadData = async () => {
      try {
        const response = await fetch(`/api/quality-logs?date=${selectedDate}`);
        if (response.ok) {
          const data = await response.json();
          // Convert numeric nulls back to empty strings for the form
          const formattedLogs = data.logs.map((log: Record<string, string | number | null>) => {
            const out: Record<string, string | number | null> = { ...log };
            ['l1','l2','l3','w1','w2','w3','intactEggWeight','albumenHeight','yolkWeight','dryShellWeight'].forEach(key => {
              out[key] = log[key] !== null ? String(log[key]) : '';
            });
            return out;
          });
          setLogs(formattedLogs);
        }
      } catch (error) {
        console.error("Failed to load logs. Loading from local storage.");
        const localKey = `quality_logs_${selectedDate}`;
        const localDataStr = localStorage.getItem(localKey);
        if (localDataStr) {
          setLogs(JSON.parse(localDataStr));
        } else {
          setLogs([]);
        }
      }
    };
    loadData();
    setActiveDraft(null);
  }, [selectedDate]);

  // Offline status tracking (reused from daily rounds)
  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    setIsOnline(navigator.onLine);

    const queueStr = localStorage.getItem('quality_sync_queue');
    if (queueStr) setUnsyncedCount(JSON.parse(queueStr).length);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  // Attempt sync when coming back online
  useEffect(() => {
    if (isOnline && unsyncedCount > 0) syncOfflineData();
  }, [isOnline, unsyncedCount]);

  const syncOfflineData = async () => {
    const queueStr = localStorage.getItem('quality_sync_queue');
    if (!queueStr) return;

    const queue = JSON.parse(queueStr);
    const remainingQueue = [];

    for (const item of queue) {
      try {
        const response = await fetch('/api/quality-logs', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(item),
        });
        if (!response.ok) remainingQueue.push(item);
      } catch (error) {
        remainingQueue.push(item);
      }
    }

    if (remainingQueue.length > 0) {
      localStorage.setItem('quality_sync_queue', JSON.stringify(remainingQueue));
      setUnsyncedCount(remainingQueue.length);
    } else {
      localStorage.removeItem('quality_sync_queue');
      setUnsyncedCount(0);
    }
  };

  const handleSaveData = async (data: QualityFormData) => {
    // Convert empty strings to null for DB
    const payload: Record<string, string | number | null> = { date: selectedDate, ...data };
    ['l1','l2','l3','w1','w2','w3','intactEggWeight','albumenHeight','yolkWeight','dryShellWeight'].forEach(key => {
      const val = payload[key];
      payload[key] = val === '' || val === null ? null : parseFloat(String(val));
    });

    // Update local state
    const updatedLogs = [...logs];
    const existingIdx = updatedLogs.findIndex(l => l.id === data.id);
    if (existingIdx >= 0) {
      updatedLogs[existingIdx] = data;
    } else {
      updatedLogs.unshift(data);
    }
    setLogs(updatedLogs);
    localStorage.setItem(`quality_logs_${selectedDate}`, JSON.stringify(updatedLogs));

    // Clear active draft if we just completed it
    if (data.status === 'completed') {
      setActiveDraft(null);
    }

    // Save to server or queue
    try {
      if (!isOnline) throw new Error('Offline');
      const response = await fetch('/api/quality-logs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      if (!response.ok) throw new Error('Failed to save to server');
    } catch (error) {
      const queueStr = localStorage.getItem('quality_sync_queue');
      const queue = queueStr ? JSON.parse(queueStr) : [];
      queue.push(payload);
      localStorage.setItem('quality_sync_queue', JSON.stringify(queue));
      setUnsyncedCount(queue.length);
    }
  };

  const handleExport = () => {
    window.location.href = '/api/quality-export';
  };

  const drafts = logs.filter(l => l.status === 'draft');

  return (
    <main>
      <Navigation />

      <div className="flex justify-between items-center mb-2 px-1">
        <div className="flex items-center gap-2 text-sm font-bold">
          {isOnline ? (
            <span className="flex items-center gap-1 text-green-600 bg-green-100 px-2 py-1 rounded-md"><Wifi size={16} /> Online</span>
          ) : (
            <span className="flex items-center gap-1 text-red-600 bg-red-100 px-2 py-1 rounded-md"><WifiOff size={16} /> Offline</span>
          )}
          {unsyncedCount > 0 && (
            <span className="text-orange-600 bg-orange-100 px-2 py-1 rounded-md flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-orange-500 animate-pulse"></span>
              {unsyncedCount} unsynced
            </span>
          )}
        </div>
        <button onClick={handleExport} className="flex items-center gap-2 bg-stitch-blue hover:bg-blue-900 text-white px-3 py-1.5 rounded-lg text-sm font-bold transition-colors">
          <Download size={16} /> Export CSV
        </button>
      </div>

      <Header selectedDate={selectedDate} setSelectedDate={setSelectedDate} />

      {/* Pending Drafts Panel */}
      {drafts.length > 0 && (
        <div className="bg-yellow-50 border-2 border-yellow-300 rounded-xl p-4 mb-6 shadow-sm">
          <h3 className="font-bold text-yellow-800 flex items-center gap-2 mb-3">
            <Clock size={20} />
            Pending Drafts (Awaiting 24hr Shell Dry)
          </h3>
          <div className="flex gap-3 overflow-x-auto pb-2">
            {drafts.map(draft => (
              <button
                key={draft.id}
                onClick={() => setActiveDraft(draft)}
                className={`flex items-center justify-between min-w-[200px] p-3 rounded-lg border-2 text-left transition-all ${activeDraft?.id === draft.id ? 'bg-yellow-200 border-yellow-500 shadow-md scale-105' : 'bg-white border-yellow-200 hover:border-yellow-400'}`}
              >
                <div>
                  <div className="text-xs text-yellow-600 font-bold uppercase">Block {draft.block}</div>
                  <div className="font-black text-gray-800 text-lg">{draft.treatment}</div>
                </div>
                <ChevronRight className={activeDraft?.id === draft.id ? 'text-yellow-600' : 'text-gray-300'} />
              </button>
            ))}
          </div>
        </div>
      )}

      <InteractiveEggDiagram onSelectRegion={(region) => {
        setScrollToRegion(region);
        // Reset state slightly after so it can trigger again if needed
        setTimeout(() => setScrollToRegion(undefined), 100);
      }} />

      <QualityLabForm
        initialData={activeDraft}
        onSave={handleSaveData}
        scrollToRegion={scrollToRegion}
      />

    </main>
  );
}
