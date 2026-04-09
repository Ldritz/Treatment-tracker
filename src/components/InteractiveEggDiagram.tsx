"use client";

import React from 'react';

type DiagramProps = {
  onSelectRegion: (regionId: string) => void;
};

export const InteractiveEggDiagram = ({ onSelectRegion }: DiagramProps) => {
  return (
    <div className="bg-white rounded-xl border-2 border-stitch-blue p-6 mb-6 shadow-sm flex flex-col items-center">
      <h3 className="text-xl font-bold text-stitch-blue mb-4 uppercase tracking-wide">Interactive Egg Selector</h3>
      <p className="text-sm text-gray-500 mb-6 font-bold">Tap a section of the egg to jump to its data entry field.</p>

      <div className="relative w-full max-w-sm aspect-[3/4]">
        <svg
          viewBox="0 0 300 400"
          className="w-full h-full drop-shadow-lg"
          xmlns="http://www.w3.org/2000/svg"
        >
          {/* Shell */}
          <path
            id="shell"
            d="M150 20 C60 20, 20 150, 20 250 C20 350, 80 380, 150 380 C220 380, 280 350, 280 250 C280 150, 240 20, 150 20 Z"
            fill="#F3E5F5"
            stroke="#D1C4E9"
            strokeWidth="8"
            className="cursor-pointer hover:fill-purple-100 transition-colors"
            onClick={() => onSelectRegion('shell')}
          />

          {/* Shell Membrane */}
          <path
            id="shell-membrane"
            d="M150 32 C70 32, 35 150, 35 250 C35 340, 90 368, 150 368 C210 368, 265 340, 265 250 C265 150, 230 32, 150 32 Z"
            fill="#FAFAFA"
            stroke="#E0E0E0"
            strokeWidth="3"
            strokeDasharray="4,4"
            className="cursor-pointer hover:fill-gray-100 transition-colors"
            onClick={() => onSelectRegion('shell')}
          />

          {/* Albumen (White) */}
          <path
            id="albumen"
            d="M150 45 C80 45, 50 155, 50 250 C50 330, 100 355, 150 355 C200 355, 250 330, 250 250 C250 155, 220 45, 150 45 Z"
            fill="#E3F2FD"
            className="cursor-pointer hover:fill-blue-100 transition-colors"
            onClick={() => onSelectRegion('albumen')}
          />

          {/* Vitelline Membrane (Outer Yolk Ring) */}
          <circle
            id="vitelline-membrane"
            cx="150"
            cy="240"
            r="85"
            fill="#FFD54F"
            className="cursor-pointer hover:fill-yellow-300 transition-colors"
            onClick={() => onSelectRegion('yolk')}
          />

          {/* Yolk */}
          <circle
            id="yolk"
            cx="150"
            cy="240"
            r="80"
            fill="#FFCA28"
            className="cursor-pointer hover:fill-yellow-400 transition-colors"
            onClick={() => onSelectRegion('yolk')}
          />

          {/* Labels and Pointers */}
          <g className="font-nunito font-bold text-sm" fill="#1A237E">

            {/* Shell Pointer */}
            <polyline points="30,120 10,120 10,100" fill="none" stroke="#1A237E" strokeWidth="2" />
            <text x="5" y="90" className="cursor-pointer hover:underline" onClick={() => onSelectRegion('shell')}>Shell</text>

            {/* Albumen Pointer */}
            <polyline points="100,100 70,80 70,60" fill="none" stroke="#1A237E" strokeWidth="2" />
            <text x="45" y="50" className="cursor-pointer hover:underline" onClick={() => onSelectRegion('albumen')}>Albumen</text>

            {/* Yolk Pointer */}
            <polyline points="200,200 240,180 260,180" fill="none" stroke="#1A237E" strokeWidth="2" />
            <text x="265" y="185" className="cursor-pointer hover:underline" onClick={() => onSelectRegion('yolk')}>Yolk</text>

            {/* Vitelline Membrane Pointer */}
            <polyline points="230,280 260,300 260,320" fill="none" stroke="#1A237E" strokeWidth="2" />
            <text x="210" y="335" className="cursor-pointer hover:underline text-xs" onClick={() => onSelectRegion('yolk')}>Vitelline Memb.</text>

            {/* Shell Membrane Pointer */}
            <polyline points="270,250 290,250 290,270" fill="none" stroke="#1A237E" strokeWidth="2" />
            <text x="240" y="285" className="cursor-pointer hover:underline text-xs" onClick={() => onSelectRegion('shell')}>Shell Memb.</text>

          </g>
        </svg>
      </div>
    </div>
  );
};
