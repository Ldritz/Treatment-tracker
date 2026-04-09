import React, { useState } from 'react';
import { HelpCircle } from 'lucide-react';

type TooltipProps = {
  text: string;
};

export const Tooltip = ({ text }: TooltipProps) => {
  const [isVisible, setIsVisible] = useState(false);

  return (
    <div
      className="relative flex items-center"
      onMouseEnter={() => setIsVisible(true)}
      onMouseLeave={() => setIsVisible(false)}
      onClick={() => setIsVisible(!isVisible)}
    >
      <HelpCircle className="w-4 h-4 text-gray-400 hover:text-stitch-blue cursor-help transition-colors" />

      {isVisible && (
        <div className="absolute z-50 w-48 p-2 text-xs font-bold text-white bg-gray-800 rounded-lg shadow-lg -top-2 left-6 animate-in fade-in zoom-in duration-200">
          <div className="absolute w-2 h-2 bg-gray-800 transform rotate-45 -left-1 top-3"></div>
          {text}
        </div>
      )}
    </div>
  );
};
