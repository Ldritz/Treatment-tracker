import React, { useState } from 'react'
import { CAGE_LAYOUT, CageState, CageData } from '@/lib/constants'
import { ChevronLeft, ChevronRight } from 'lucide-react'

type CageGridProps = {
  selectedCage: CageData | null;
  onSelectCage: (cage: CageData) => void;
  completedCages: Set<string>; // 'block-treatment'
  draftCages?: Set<string>; // 'block-treatment'
}

export const CageGrid = ({ selectedCage, onSelectCage, completedCages, draftCages = new Set() }: CageGridProps) => {
  const [activeBlockIndex, setActiveBlockIndex] = useState(selectedCage ? selectedCage.block - 1 : 0);

  const getCageState = (block: number, treatment: string): CageState => {
    if (selectedCage?.block === block && selectedCage?.treatment === treatment) {
      return 'selected'
    }
    if (completedCages.has(`${block}-${treatment}`)) {
      return 'completed'
    }
    if (draftCages.has(`${block}-${treatment}`)) {
      return 'draft'
    }
    return 'pending'
  }

  const getCageStyle = (state: CageState) => {
    switch (state) {
      case 'selected':
        return 'bg-stitch-blue text-white ring-4 ring-stitch-blue ring-opacity-50 scale-105 z-10'
      case 'completed':
        return 'bg-mint-green text-completed-text border-mint-green'
      case 'draft':
        return 'bg-yellow-300 text-yellow-900 border-yellow-500'
      case 'pending':
      default:
        return 'bg-pending-bg text-pending-text hover:bg-blue-200 border-stitch-blue'
    }
  }

  const currentBlock = CAGE_LAYOUT[activeBlockIndex];

  const handlePrevBlock = () => {
    setActiveBlockIndex((prev) => (prev > 0 ? prev - 1 : prev));
  };

  const handleNextBlock = () => {
    setActiveBlockIndex((prev) => (prev < CAGE_LAYOUT.length - 1 ? prev + 1 : prev));
  };

  return (
    <div className="flex justify-center mb-6">
      <div className="bg-white rounded-xl border-2 border-stitch-blue p-4 shadow-sm inline-block">

        <div className="flex items-center justify-between mb-4">
          <button
            onClick={handlePrevBlock}
            disabled={activeBlockIndex === 0}
            className="p-1 rounded-full hover:bg-gray-100 disabled:opacity-30 disabled:hover:bg-transparent"
            aria-label="Previous Block"
          >
            <ChevronLeft className="text-stitch-blue" />
            <span className="sr-only">back</span>
          </button>

          <h4 className="font-black text-center text-stitch-blue uppercase tracking-wider text-lg">
            Block {currentBlock.block}
          </h4>

          <button
            onClick={handleNextBlock}
            disabled={activeBlockIndex === CAGE_LAYOUT.length - 1}
            className="p-1 rounded-full hover:bg-gray-100 disabled:opacity-30 disabled:hover:bg-transparent"
            aria-label="Next Block"
          >
            <ChevronRight className="text-stitch-blue" />
            <span className="sr-only">Next</span>
          </button>
        </div>

        <div className="flex flex-col gap-2 p-3 bg-gray-50 rounded-lg border border-gray-200">
          <div className="flex flex-col gap-2">
            {currentBlock.rows.map((row, rowIndex) => (
              <div key={`b${currentBlock.block}-r${rowIndex}`} className="flex gap-2 justify-center">
                {row.map((treatment) => {
                  const state = getCageState(currentBlock.block, treatment)
                  return (
                    <button
                      key={`${currentBlock.block}-${treatment}`}
                      onClick={() => onSelectCage({ block: currentBlock.block, row: rowIndex + 1, treatment })}
                      className={`
                        w-14 h-14 md:w-16 md:h-16 lg:w-20 lg:h-20 rounded-lg border-2
                        font-black text-xl transition-all duration-200 shadow-sm
                        flex items-center justify-center
                        ${getCageStyle(state)}
                      `}
                      aria-label={`Select Block ${currentBlock.block}, Treatment ${treatment}`}
                    >
                      {treatment}
                    </button>
                  )
                })}
              </div>
            ))}
          </div>
        </div>

      </div>
    </div>
  )
}
