import React from 'react'

export const Header = ({
  selectedDate,
  setSelectedDate
}: {
  selectedDate: string,
  setSelectedDate: (date: string) => void
}) => {
  return (
    <header className="flex flex-col sm:flex-row items-center justify-between bg-white border-2 border-stitch-blue rounded-xl p-4 mb-6 shadow-sm">
      <div className="flex items-center gap-3 mb-4 sm:mb-0">
        <h1 className="text-2xl font-black text-stitch-blue tracking-wide">
          Experiment 626
        </h1>
        <span className="text-gray-500 font-bold hidden sm:inline">|</span>
        <h2 className="text-lg font-bold text-gray-700">Quail Tracker</h2>
      </div>

      <div className="flex items-center bg-baby-blue border border-stitch-blue rounded-lg px-3 py-2">
        <label htmlFor="date-picker" className="font-bold text-stitch-blue mr-2 text-sm uppercase tracking-wider">
          Date:
        </label>
        <input
          id="date-picker"
          type="date"
          value={selectedDate}
          onChange={(e) => setSelectedDate(e.target.value)}
          className="bg-transparent font-roboto-mono text-gray-900 font-bold outline-none"
        />
      </div>
    </header>
  )
}
