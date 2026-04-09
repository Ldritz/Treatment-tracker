"use client";

import React, { useState, useEffect } from 'react';
import { format } from 'date-fns';
import { Header } from '@/components/Header';
import { CageGrid } from '@/components/CageGrid';
import { DataEntryForm } from '@/components/DataEntryForm';
import { CageData } from '@/lib/constants';
import { Download, WifiOff, Wifi } from 'lucide-react';

export default function Home() {
  const [selectedDate, setSelectedDate] = useState(format(new Date(), 'yyyy-MM-dd'));
  const [selectedCage, setSelectedCage] = useState<CageData | null>(null);
  const [completedCages, setCompletedCages] = useState<Set<string>>(new Set());
  const [savedDataMap, setSavedDataMap] = useState<Record<string, Record<string, string | number | null>>>({});

  const [isOnline, setIsOnline] = useState(true);
  const [unsyncedCount, setUnsyncedCount] = useState(0);

  // Load existing data when date changes
  useEffect(() => {
    const loadData = async () => {
      try {
        const response = await fetch(`/api/logs?date=${selectedDate}`);
        if (response.ok) {
          const { logs } = await response.json();
          const newCompleted = new Set<string>();
          const newDataMap: Record<string, Record<string, string | number | null>> = {};

          logs.forEach((log: Record<string, string | number | null>) => {
            const key = `${log.block}-${log.treatment}`;
            newCompleted.add(key);
            // Convert to string format expected by form, handle nulls
            newDataMap[key] = {
              liveQuails: String(log.liveQuails),
              eggsLaid: String(log.eggsLaid),
              eggMass: log.eggMass !== null ? String(log.eggMass) : '',
              feedIntake: String(log.feedIntake),
              feedRefused: String(log.feedRefused)
            };
          });

          setCompletedCages(newCompleted);
          setSavedDataMap(newDataMap);
        }
      } catch (error) {
        console.error("Failed to load logs from server. Loading from local storage if available.");
        // Basic fallback to local storage
        const localKey = `quail_logs_${selectedDate}`;
        const localDataStr = localStorage.getItem(localKey);
        if (localDataStr) {
          const localData = JSON.parse(localDataStr);
          const newCompleted = new Set<string>();
          Object.keys(localData).forEach(k => newCompleted.add(k));
          setCompletedCages(newCompleted);
          setSavedDataMap(localData);
        } else {
          setCompletedCages(new Set());
          setSavedDataMap({});
        }
      }
      setSelectedCage(null);
    };

    loadData();
  }, [selectedDate]);

  // Offline status tracking
  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    setIsOnline(navigator.onLine);

    // Initial check for unsynced queue
    const queueStr = localStorage.getItem('quail_sync_queue');
    if (queueStr) {
      const queue = JSON.parse(queueStr);
      setUnsyncedCount(queue.length);
    }

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  // Attempt sync when coming back online
  useEffect(() => {
    if (isOnline && unsyncedCount > 0) {
      syncOfflineData();
    }
  }, [isOnline, unsyncedCount]);

  const syncOfflineData = async () => {
    const queueStr = localStorage.getItem('quail_sync_queue');
    if (!queueStr) return;

    const queue = JSON.parse(queueStr);
    const remainingQueue = [];

    for (const item of queue) {
      try {
        const response = await fetch('/api/logs', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(item),
        });

        if (!response.ok) {
          remainingQueue.push(item);
        }
      } catch (error) {
        remainingQueue.push(item);
      }
    }

    if (remainingQueue.length > 0) {
      localStorage.setItem('quail_sync_queue', JSON.stringify(remainingQueue));
      setUnsyncedCount(remainingQueue.length);
    } else {
      localStorage.removeItem('quail_sync_queue');
      setUnsyncedCount(0);
    }
  };

  const handleSaveData = async (data: Record<string, string | number | null>) => {
    const payload = {
      date: selectedDate,
      ...data
    };

    const key = `${data.block}-${data.treatment}`;

    // Save to local storage for quick access/offline
    const currentLocalDataStr = localStorage.getItem(`quail_logs_${selectedDate}`);
    const currentLocalData = currentLocalDataStr ? JSON.parse(currentLocalDataStr) : {};
    currentLocalData[key] = {
      liveQuails: String(data.liveQuails),
      eggsLaid: String(data.eggsLaid),
      eggMass: data.eggMass !== null ? String(data.eggMass) : '',
      feedIntake: String(data.feedIntake),
      feedRefused: String(data.feedRefused)
    };
    localStorage.setItem(`quail_logs_${selectedDate}`, JSON.stringify(currentLocalData));

    // Update UI state immediately
    setCompletedCages(prev => new Set(prev).add(key));
    setSavedDataMap(prev => ({ ...prev, [key]: currentLocalData[key] }));

    try {
      if (!isOnline) {
        throw new Error('Offline');
      }

      const response = await fetch('/api/logs', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        throw new Error('Failed to save to server');
      }
    } catch (error) {
      // Add to sync queue if offline or server error
      const queueStr = localStorage.getItem('quail_sync_queue');
      const queue = queueStr ? JSON.parse(queueStr) : [];
      queue.push(payload);
      localStorage.setItem('quail_sync_queue', JSON.stringify(queue));
      setUnsyncedCount(queue.length);
    }

    // Deselect cage
    setSelectedCage(null);
  };

  const handleExport = () => {
    window.location.href = '/api/export';
  };

  return (
    <main>
      <div className="flex justify-between items-center mb-2 px-1">
        {/* Connection Status Indicator */}
        <div className="flex items-center gap-2 text-sm font-bold">
          {isOnline ? (
            <span className="flex items-center gap-1 text-green-600 bg-green-100 px-2 py-1 rounded-md">
              <Wifi size={16} /> Online
            </span>
          ) : (
            <span className="flex items-center gap-1 text-red-600 bg-red-100 px-2 py-1 rounded-md">
              <WifiOff size={16} /> Offline
            </span>
          )}
          {unsyncedCount > 0 && (
            <span className="text-orange-600 bg-orange-100 px-2 py-1 rounded-md flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-orange-500 animate-pulse"></span>
              {unsyncedCount} unsynced
            </span>
          )}
        </div>

        <button
          onClick={handleExport}
          className="flex items-center gap-2 bg-stitch-blue hover:bg-blue-900 text-white px-3 py-1.5 rounded-lg text-sm font-bold transition-colors"
        >
          <Download size={16} />
          Export CSV
        </button>
      </div>

      <Header
        selectedDate={selectedDate}
        setSelectedDate={setSelectedDate}
      />

      <CageGrid
        selectedCage={selectedCage}
        onSelectCage={setSelectedCage}
        completedCages={completedCages}
      />

      {selectedCage ? (
        <div className="animate-in fade-in slide-in-from-bottom-4 duration-300">
          <DataEntryForm
            selectedCage={selectedCage}
            onSave={handleSaveData}
            onCancel={() => setSelectedCage(null)}
            initialData={savedDataMap[`${selectedCage.block}-${selectedCage.treatment}`]}
          />
        </div>
      ) : (
        <div className="bg-white border-2 border-dashed border-gray-300 rounded-xl p-8 text-center text-gray-400 mt-6 shadow-sm">
          <p className="font-bold text-lg">Select a cage from the grid above to enter data.</p>
        </div>
      )}
    </main>
  );
}
