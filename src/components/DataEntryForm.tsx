import React, { useState, useEffect } from 'react'
import { CageData } from '@/lib/constants'
import { Bird, Egg, Leaf, Save, AlertCircle } from 'lucide-react'

type FormData = {
  liveQuails: string;
  eggsLaid: string;
  eggMass: string;
  feedIntake: string;
  feedRefused: string;
}

const DEFAULT_FORM_DATA: FormData = {
  liveQuails: '3',
  eggsLaid: '0',
  eggMass: '',
  feedIntake: '90',
  feedRefused: '',
}

type DataEntryFormProps = {
  selectedCage: CageData;
  onSave: (data: Record<string, string | number | null>) => Promise<void>;
  onCancel: () => void;
  initialData?: Partial<FormData>;
}

export const DataEntryForm = ({ selectedCage, onSave, onCancel, initialData }: DataEntryFormProps) => {
  const [formData, setFormData] = useState<FormData>({ ...DEFAULT_FORM_DATA, ...initialData })
  const [isSaving, setIsSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Update formData if initialData changes (e.g. switching to a previously completed cage)
  useEffect(() => {
    if (initialData) {
      setFormData(prev => ({ ...DEFAULT_FORM_DATA, ...initialData }))
    } else {
      setFormData({ ...DEFAULT_FORM_DATA })
    }
    setError(null)
  }, [selectedCage, initialData])

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({ ...prev, [name]: value }))
    // Clear error on change
    if (error) setError(null)
  }

  // Calculations
  const liveQuailsNum = parseFloat(formData.liveQuails) || 0
  const eggsLaidNum = parseFloat(formData.eggsLaid) || 0
  const eggMassNum = parseFloat(formData.eggMass) || 0
  const feedIntakeNum = parseFloat(formData.feedIntake) || 0
  const feedRefusedNum = parseFloat(formData.feedRefused) || 0

  const vfi = formData.feedRefused !== '' ? feedIntakeNum - feedRefusedNum : null
  const fcr = vfi !== null && eggMassNum > 0 ? vfi / eggMassNum : null
  const hdep = liveQuailsNum > 0 ? (eggsLaidNum / liveQuailsNum) * 100 : null

  const handleSave = async () => {
    // Validation
    if (formData.feedRefused === '') {
      setError("Please enter the Feed Refused. It cannot be empty.")
      return
    }

    if (eggsLaidNum > 0 && formData.eggMass === '') {
      setError("Eggs were laid, so Total Egg Mass cannot be empty.")
      return
    }

    setIsSaving(true)
    setError(null)

    try {
      await onSave({
        block: selectedCage.block,
        treatment: selectedCage.treatment,
        liveQuails: liveQuailsNum,
        eggsLaid: eggsLaidNum,
        eggMass: formData.eggMass === '' ? null : eggMassNum,
        feedIntake: feedIntakeNum,
        feedRefused: feedRefusedNum
      })
      // Parent component will handle clearing and deselecting
    } catch (err) {
      setError("Failed to save data. Please try again.")
    } finally {
      setIsSaving(false)
    }
  }

  return (
    <div className="flex flex-col lg:flex-row gap-6">
      {/* Form Panel */}
      <div className="flex-1 bg-white rounded-xl border-2 border-stitch-blue p-5 shadow-md">
        <div className="flex items-center justify-between border-b-2 border-gray-100 pb-3 mb-5">
          <h3 className="text-xl font-bold text-stitch-blue flex items-center gap-2">
            Entering Data for
            <span className="bg-stitch-blue text-white px-3 py-1 rounded-md ml-2">
              Block {selectedCage.block} - {selectedCage.treatment}
            </span>
          </h3>
          <button onClick={onCancel} className="text-gray-400 hover:text-gray-600 font-bold text-sm">
            Close
          </button>
        </div>

        {error && (
          <div className="bg-red-50 border-l-4 border-red-500 p-4 mb-6 rounded-md flex items-start gap-3">
            <AlertCircle className="text-red-500 shrink-0 mt-0.5" />
            <div>
              <h4 className="text-red-800 font-bold">Validation Error</h4>
              <p className="text-red-700 text-sm mt-1">{error}</p>
            </div>
          </div>
        )}

        <div className="space-y-5">
          {/* Live Quails */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 items-center">
            <label className="flex items-center gap-2 font-bold text-gray-700">
              <Bird className="text-stitch-blue w-5 h-5" />
              Live Quails
            </label>
            <input
              type="number"
              name="liveQuails"
              value={formData.liveQuails}
              onChange={handleChange}
              step="1"
              min="0"
              className="border-2 border-gray-300 rounded-lg p-2 w-full focus:border-stitch-blue focus:ring-2 focus:ring-blue-200 outline-none transition-all text-xl font-bold text-center text-gray-800 font-roboto-mono"
            />
          </div>

          <div className="h-px bg-gray-100 my-2"></div>

          {/* Eggs */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 items-center bg-yellow-50 p-3 rounded-lg border border-yellow-100">
            <label className="flex items-center gap-2 font-bold text-gray-700">
              <Egg className="text-yellow-600 w-5 h-5" />
              Eggs Laid Today
            </label>
            <input
              type="number"
              name="eggsLaid"
              value={formData.eggsLaid}
              onChange={handleChange}
              step="1"
              min="0"
              className="border-2 border-yellow-300 rounded-lg p-2 w-full focus:border-yellow-500 focus:ring-2 focus:ring-yellow-200 outline-none transition-all text-xl font-bold text-center text-gray-800 font-roboto-mono"
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 items-center">
            <label className="flex items-center gap-2 font-bold text-gray-700 pl-7">
              Total Egg Mass (g)
            </label>
            <input
              type="number"
              name="eggMass"
              value={formData.eggMass}
              onChange={handleChange}
              step="0.1"
              min="0"
              placeholder="e.g. 12.5"
              className="border-2 border-gray-300 rounded-lg p-2 w-full focus:border-stitch-blue focus:ring-2 focus:ring-blue-200 outline-none transition-all text-xl font-bold text-center text-gray-800 font-roboto-mono placeholder:font-normal placeholder:text-gray-400"
            />
          </div>

          <div className="h-px bg-gray-100 my-2"></div>

          {/* Feed */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 items-center">
            <label className="flex items-center gap-2 font-bold text-gray-700">
              <Leaf className="text-green-600 w-5 h-5" />
              Total Feed Intake (g)
            </label>
            <input
              type="number"
              name="feedIntake"
              value={formData.feedIntake}
              onChange={handleChange}
              step="1"
              min="0"
              className="border-2 border-gray-300 rounded-lg p-2 w-full focus:border-stitch-blue focus:ring-2 focus:ring-blue-200 outline-none transition-all text-xl font-bold text-center text-gray-800 font-roboto-mono"
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 items-center bg-red-50 p-3 rounded-lg border border-red-100">
            <label className="flex items-center gap-2 font-bold text-gray-700 pl-7">
              Feed Refused (g) <span className="text-red-500">*</span>
            </label>
            <input
              type="number"
              name="feedRefused"
              value={formData.feedRefused}
              onChange={handleChange}
              step="1"
              min="0"
              placeholder="Required"
              className="border-2 border-red-300 rounded-lg p-2 w-full focus:border-red-500 focus:ring-2 focus:ring-red-200 outline-none transition-all text-xl font-bold text-center text-gray-800 font-roboto-mono placeholder:font-normal placeholder:text-red-300"
            />
          </div>
        </div>

        <button
          onClick={handleSave}
          disabled={isSaving}
          className="w-full mt-8 bg-hibiscus-pink hover:bg-pink-600 text-white font-bold text-xl py-4 rounded-xl shadow-lg transition-transform transform hover:-translate-y-1 active:translate-y-0 disabled:opacity-70 flex items-center justify-center gap-2"
        >
          <Save className="w-6 h-6" />
          {isSaving ? 'Saving...' : 'Save Cage Data'}
        </button>
      </div>

      {/* Live Dashboard Panel */}
      <div className="w-full lg:w-72 bg-stitch-blue text-white rounded-xl p-5 shadow-md flex flex-col">
        <h3 className="text-lg font-bold border-b border-blue-400 pb-2 mb-4 opacity-90 uppercase tracking-wider">
          Live Dashboard
        </h3>

        <div className="space-y-6 flex-1">
          <DashboardMetric
            label="Voluntary Feed Intake"
            abbr="VFI"
            value={vfi !== null ? vfi.toFixed(2) : '--'}
            unit="g/day"
          />
          <DashboardMetric
            label="Feed Conversion Ratio"
            abbr="FCR"
            value={fcr !== null ? fcr.toFixed(2) : '--'}
            unit="feed/egg"
          />
          <DashboardMetric
            label="Hen-Day Production"
            abbr="HDEP"
            value={hdep !== null ? hdep.toFixed(2) : '--'}
            unit="%"
          />
        </div>

        <div className="mt-6 text-xs text-blue-200 italic opacity-80 text-center">
          Calculations are 24-hour equivalents for UI verification.
        </div>
      </div>
    </div>
  )
}

const DashboardMetric = ({ label, abbr, value, unit }: { label: string, abbr: string, value: string | number, unit: string }) => (
  <div className="bg-white/10 rounded-lg p-3">
    <div className="text-blue-200 text-xs font-bold uppercase mb-1 flex justify-between">
      <span>{label}</span>
      <span className="opacity-50">{abbr}</span>
    </div>
    <div className="flex items-baseline gap-1">
      <span className="text-3xl font-black font-roboto-mono tracking-tight">{value}</span>
      <span className="text-sm font-bold opacity-70">{unit}</span>
    </div>
  </div>
)
