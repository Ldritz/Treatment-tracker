import React from 'react'
import { CAGE_LAYOUT, CageState, CageData } from '@/lib/constants'

type CageGridProps = {
  selectedCage: CageData | null;
  onSelectCage: (cage: CageData) => void;
  completedCages: Set<string>; // 'block-treatment'
}

export const CageGrid = ({ selectedCage, onSelectCage, completedCages }: CageGridProps) => {

  const getCageState = (block: number, treatment: string): CageState => {
    if (selectedCage?.block === block && selectedCage?.treatment === treatment) {
      return 'selected'
    }
    if (completedCages.has(`${block}-${treatment}`)) {
      return 'completed'
    }
    return 'pending'
  }

  const getCageStyle = (state: CageState) => {
    switch (state) {
      case 'selected':
        return 'bg-stitch-blue text-white ring-4 ring-stitch-blue ring-opacity-50 scale-105 z-10'
      case 'completed':
        return 'bg-mint-green text-completed-text border-mint-green'
      case 'pending':
      default:
        return 'bg-pending-bg text-pending-text hover:bg-blue-200 border-stitch-blue'
    }
  }

  return (
    <div className="bg-white rounded-xl border-2 border-stitch-blue p-4 shadow-sm mb-6 overflow-x-auto">
      <h3 className="text-xl font-bold text-stitch-blue mb-4 text-center">Facility Layout (27 Cages)</h3>

      <div className="flex flex-col md:flex-row gap-6 min-w-max md:min-w-0 justify-center">
        {CAGE_LAYOUT.map((blockData) => (
          <div key={`block-${blockData.block}`} className="flex flex-col gap-2 p-3 bg-gray-50 rounded-lg border border-gray-200 flex-1">
            <h4 className="font-bold text-center text-gray-700 uppercase tracking-wider text-sm mb-2">
              Block {blockData.block}
            </h4>

            <div className="flex flex-col gap-2">
              {blockData.rows.map((row, rowIndex) => (
                <div key={`b${blockData.block}-r${rowIndex}`} className="flex gap-2 justify-center">
                  {row.map((treatment) => {
                    const state = getCageState(blockData.block, treatment)
                    return (
                      <button
                        key={`${blockData.block}-${treatment}`}
                        onClick={() => onSelectCage({ block: blockData.block, row: rowIndex + 1, treatment })}
                        className={`
                          w-12 h-12 md:w-14 md:h-14 lg:w-16 lg:h-16 rounded-lg border-2
                          font-black text-lg transition-all duration-200 shadow-sm
                          flex items-center justify-center
                          ${getCageStyle(state)}
                        `}
                        aria-label={`Select Block ${blockData.block}, Treatment ${treatment}`}
                      >
                        {treatment}
                      </button>
                    )
                  })}
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
