import React, { useState, useEffect } from 'react';
import { CheckCircle, Info, WifiOff, X } from 'lucide-react';

export const Onboarding = () => {
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    const hasSeenOnboarding = localStorage.getItem('quail_tracker_onboarding_seen');
    // Using setTimeout to avoid calling setState synchronously within an effect
    if (!hasSeenOnboarding) {
      setTimeout(() => setIsOpen(true), 0);
    }
  }, []);

  const handleClose = () => {
    localStorage.setItem('quail_tracker_onboarding_seen', 'true');
    setIsOpen(false);
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm animate-in fade-in duration-300">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg border-2 border-stitch-blue overflow-hidden flex flex-col max-h-[90vh]">

        <div className="bg-stitch-blue text-white p-6 relative">
          <button
            onClick={handleClose}
            className="absolute top-4 right-4 text-blue-200 hover:text-white transition-colors"
            aria-label="Close onboarding"
          >
            <X size={24} />
          </button>
          <h2 className="text-2xl font-black font-nunito tracking-wide">Aloha! Welcome to Experiment 626</h2>
          <p className="mt-2 text-blue-100 font-bold">Your daily quail data collection tool.</p>
        </div>

        <div className="p-6 overflow-y-auto space-y-6">

          <div>
            <h3 className="font-bold text-gray-800 text-lg flex items-center gap-2 mb-3">
              <Info className="text-stitch-blue" />
              How to use the Grid
            </h3>
            <ul className="space-y-3">
              <li className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-md bg-pending-bg border-2 border-stitch-blue flex-shrink-0 flex items-center justify-center font-bold text-pending-text text-xs">T1</div>
                <span className="text-sm text-gray-700"><strong>Pending:</strong> Tap a cage to enter today&apos;s data.</span>
              </li>
              <li className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-md bg-stitch-blue ring-2 ring-stitch-blue ring-opacity-50 flex-shrink-0 flex items-center justify-center font-bold text-white text-xs scale-105">T1</div>
                <span className="text-sm text-gray-700"><strong>Selected:</strong> Currently entering data for this cage.</span>
              </li>
              <li className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-md bg-mint-green border-2 border-mint-green flex-shrink-0 flex items-center justify-center font-bold text-completed-text text-xs">T1</div>
                <span className="text-sm text-gray-700"><strong>Completed:</strong> Data saved successfully!</span>
              </li>
            </ul>
          </div>

          <div className="h-px bg-gray-100"></div>

          <div>
            <h3 className="font-bold text-gray-800 text-lg flex items-center gap-2 mb-2">
              <WifiOff className="text-stitch-blue" />
              Offline Ready
            </h3>
            <p className="text-sm text-gray-700 leading-relaxed">
              No signal in the facility? No problem. The app works offline. Your data is safely stored on your device and will automatically sync when you reconnect to the internet.
            </p>
          </div>

        </div>

        <div className="p-6 bg-gray-50 border-t border-gray-100">
          <button
            onClick={handleClose}
            className="w-full bg-hibiscus-pink hover:bg-pink-600 text-white font-bold py-3 rounded-xl shadow-md transition-transform transform hover:-translate-y-1 active:translate-y-0 flex items-center justify-center gap-2"
          >
            <CheckCircle size={20} />
            Let&apos;s Get Started
          </button>
        </div>

      </div>
    </div>
  );
};
