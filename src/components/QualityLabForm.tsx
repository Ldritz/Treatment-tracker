"use client";

import React, { useState, useEffect, useRef } from 'react';
import { Tooltip } from '@/components/Tooltip';
import { Save, Clock, Rocket } from 'lucide-react';

export type QualityFormData = {
  id: string;
  block: string;
  treatment: string;
  l1: string; l2: string; l3: string;
  w1: string; w2: string; w3: string;
  intactEggWeight: string;
  albumenHeight: string;
  yolkWeight: string;
  dryShellWeight: string;
  status: 'draft' | 'completed';
};

const DEFAULT_FORM: Omit<QualityFormData, 'id' | 'status'> = {
  block: '', treatment: '',
  l1: '', l2: '', l3: '',
  w1: '', w2: '', w3: '',
  intactEggWeight: '', albumenHeight: '', yolkWeight: '', dryShellWeight: ''
};

type QualityLabFormProps = {
  initialData?: QualityFormData | null;
  onSave: (data: QualityFormData) => Promise<void>;
  scrollToRegion?: string;
  selectedBlock?: string;
  selectedTreatment?: string;
};

export const QualityLabForm = ({ initialData, onSave, scrollToRegion, selectedBlock, selectedTreatment }: QualityLabFormProps) => {
  const [formData, setFormData] = useState<Omit<QualityFormData, 'id' | 'status'>>({ ...DEFAULT_FORM });
  const [isSaving, setIsSaving] = useState(false);
  const [showAnimation, setShowAnimation] = useState(false);

  // Refs for scrolling
  const caliperRef = useRef<HTMLDivElement>(null);
  const internalRef = useRef<HTMLDivElement>(null);
  const shellRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    // Timeout to prevent synchronous state update in effect
    setTimeout(() => {
      if (initialData) {
        setFormData(initialData);
      } else {
        setFormData({ ...DEFAULT_FORM, block: selectedBlock || '', treatment: selectedTreatment || '' });
      }
    }, 0);
  }, [initialData, selectedBlock, selectedTreatment]);

  useEffect(() => {
    if (scrollToRegion === 'albumen' || scrollToRegion === 'yolk') {
      internalRef.current?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    } else if (scrollToRegion === 'shell') {
      shellRef.current?.scrollIntoView({ behavior: 'smooth', block: 'center' });
      shellRef.current?.focus();
    }
  }, [scrollToRegion]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  // Calculations
  const parse = (val: string) => parseFloat(val) || null;

  const l1 = parse(formData.l1), l2 = parse(formData.l2), l3 = parse(formData.l3);
  const avgL = (l1 !== null && l2 !== null && l3 !== null) ? (l1 + l2 + l3) / 3 : null;

  const w1 = parse(formData.w1), w2 = parse(formData.w2), w3 = parse(formData.w3);
  const avgW = (w1 !== null && w2 !== null && w3 !== null) ? (w1 + w2 + w3) / 3 : null;

  const shapeIndex = (avgL !== null && avgW !== null && avgL > 0) ? (avgW / avgL) * 100 : null;

  const intactWt = parse(formData.intactEggWeight);
  const yolkWt = parse(formData.yolkWeight);
  const shellWt = parse(formData.dryShellWeight);
  const albHt = parse(formData.albumenHeight);

  const yolkPct = (yolkWt !== null && intactWt !== null && intactWt > 0) ? (yolkWt / intactWt) * 100 : null;
  const shellPct = (shellWt !== null && intactWt !== null && intactWt > 0) ? (shellWt / intactWt) * 100 : null;

  let haughUnit = null;
  if (albHt !== null && intactWt !== null) {
    const val = albHt - 1.7 * Math.pow(intactWt, 0.37) + 7.6;
    if (val > 0) {
      haughUnit = 100 * Math.log10(val);
    }
  }

  // Validation conditions
  const isMetadataFilled = formData.block !== '' && formData.treatment !== '';
  const isMeasurementsFilled = [l1, l2, l3, w1, w2, w3, intactWt, yolkWt, albHt].every(val => val !== null);
  const isShellFilled = shellWt !== null;

  const canSaveDraft = isMetadataFilled && (l1 !== null || w1 !== null || intactWt !== null || yolkWt !== null || albHt !== null);
  const isComplete = isMetadataFilled && isMeasurementsFilled && isShellFilled;

  const handleSave = async (status: 'draft' | 'completed') => {
    setIsSaving(true);

    const idToUse = initialData?.id || `ql_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    await onSave({
      ...formData,
      id: idToUse,
      status
    });

    if (status === 'completed') {
      setShowAnimation(true);
      setTimeout(() => setShowAnimation(false), 3000);
      setFormData({ ...DEFAULT_FORM, block: formData.block, treatment: formData.treatment });
    }

    setIsSaving(false);
  };

  return (
    <div className="flex flex-col lg:flex-row gap-6 relative">

      {showAnimation && (
        <div className="absolute inset-0 z-50 flex items-center justify-center pointer-events-none">
          <div className="animate-bounce bg-stitch-blue text-white p-6 rounded-full shadow-2xl flex flex-col items-center gap-2">
            <Rocket size={48} />
            <span className="font-black text-xl">Sample Saved!</span>
          </div>
        </div>
      )}

      {/* Form Area */}
      <div className="flex-1 space-y-6">

        {/* Card 1: Metadata - Hidden when cage is selected via grid */}
        {!selectedBlock && (
          <div className="bg-white rounded-xl border-2 border-stitch-blue p-5 shadow-sm">
            <h4 className="font-bold text-stitch-blue mb-4">Metadata</h4>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-bold text-gray-700 mb-1">Block</label>
                <select name="block" value={formData.block} onChange={handleChange} className="w-full border-2 border-gray-300 rounded-lg p-2 font-bold focus:border-stitch-blue outline-none">
                  <option value="">Select...</option>
                  <option value="1">Block 1</option>
                  <option value="2">Block 2</option>
                  <option value="3">Block 3</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-bold text-gray-700 mb-1">Treatment</label>
                <select name="treatment" value={formData.treatment} onChange={handleChange} className="w-full border-2 border-gray-300 rounded-lg p-2 font-bold focus:border-stitch-blue outline-none">
                  <option value="">Select...</option>
                  {['T1','T2','T3','T4','T5','T6','T7','T8','T9'].map(t => <option key={t} value={t}>{t}</option>)}
                </select>
              </div>
            </div>
          </div>
        )}

        {/* Card 2: Caliper Measurements */}
        <div ref={caliperRef} className="bg-white rounded-xl border-2 border-stitch-blue p-5 shadow-sm">
          <h4 className="font-bold text-stitch-blue mb-4 flex items-center gap-2">
            Caliper Measurements
            <Tooltip text="Take 3 readings across the egg to ensure average accuracy." />
          </h4>

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-bold text-gray-700 mb-2">Length (mm)</label>
              <div className="grid grid-cols-3 gap-2">
                <input type="number" step="0.1" placeholder="L1" name="l1" value={formData.l1} onChange={handleChange} className="border-2 border-gray-300 rounded-lg p-2 text-center font-roboto-mono font-bold focus:border-stitch-blue outline-none" />
                <input type="number" step="0.1" placeholder="L2" name="l2" value={formData.l2} onChange={handleChange} className="border-2 border-gray-300 rounded-lg p-2 text-center font-roboto-mono font-bold focus:border-stitch-blue outline-none" />
                <input type="number" step="0.1" placeholder="L3" name="l3" value={formData.l3} onChange={handleChange} className="border-2 border-gray-300 rounded-lg p-2 text-center font-roboto-mono font-bold focus:border-stitch-blue outline-none" />
              </div>
            </div>
            <div>
              <label className="block text-sm font-bold text-gray-700 mb-2">Width (mm)</label>
              <div className="grid grid-cols-3 gap-2">
                <input type="number" step="0.1" placeholder="W1" name="w1" value={formData.w1} onChange={handleChange} className="border-2 border-gray-300 rounded-lg p-2 text-center font-roboto-mono font-bold focus:border-stitch-blue outline-none" />
                <input type="number" step="0.1" placeholder="W2" name="w2" value={formData.w2} onChange={handleChange} className="border-2 border-gray-300 rounded-lg p-2 text-center font-roboto-mono font-bold focus:border-stitch-blue outline-none" />
                <input type="number" step="0.1" placeholder="W3" name="w3" value={formData.w3} onChange={handleChange} className="border-2 border-gray-300 rounded-lg p-2 text-center font-roboto-mono font-bold focus:border-stitch-blue outline-none" />
              </div>
            </div>
          </div>
        </div>

        {/* Card 3: Internal Quality & Weights */}
        <div ref={internalRef} className="bg-white rounded-xl border-2 border-stitch-blue p-5 shadow-sm space-y-4">
          <h4 className="font-bold text-stitch-blue mb-2">Internal Quality & Weights</h4>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 items-center">
            <label className="font-bold text-gray-700">Intact Sample Egg Weight (g)</label>
            <input type="number" step="0.1" name="intactEggWeight" value={formData.intactEggWeight} onChange={handleChange} className="border-2 border-gray-300 rounded-lg p-2 text-center font-roboto-mono font-bold focus:border-stitch-blue outline-none" />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 items-center">
            <label className="font-bold text-gray-700">Albumen Height (mm)</label>
            <input type="number" step="0.1" name="albumenHeight" value={formData.albumenHeight} onChange={handleChange} className="border-2 border-gray-300 rounded-lg p-2 text-center font-roboto-mono font-bold focus:border-stitch-blue outline-none" />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 items-center">
            <label className="font-bold text-gray-700">Egg Yolk Weight (g)</label>
            <input type="number" step="0.1" name="yolkWeight" value={formData.yolkWeight} onChange={handleChange} className="border-2 border-gray-300 rounded-lg p-2 text-center font-roboto-mono font-bold focus:border-stitch-blue outline-none" />
          </div>

          <div className="h-px bg-gray-200 my-4"></div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 items-center bg-yellow-50 p-3 rounded-lg border border-yellow-200">
            <label className="font-bold text-gray-800 flex items-center gap-2">
              Air-Dried Shell Wt. (g)
              <Tooltip text="Requires 24 hours of air drying. Save as Draft until ready." />
            </label>
            <input ref={shellRef} type="number" step="0.1" name="dryShellWeight" value={formData.dryShellWeight} onChange={handleChange} className="border-2 border-yellow-300 rounded-lg p-2 text-center font-roboto-mono font-bold focus:border-yellow-500 outline-none bg-white" placeholder="24hr wait..." />
          </div>

        </div>

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row gap-4 mt-6">
          <button
            onClick={() => handleSave('draft')}
            disabled={!canSaveDraft || isSaving}
            className="flex-1 bg-yellow-500 hover:bg-yellow-600 text-white font-bold py-4 rounded-xl shadow-md transition-all disabled:opacity-50 flex justify-center items-center gap-2"
          >
            <Clock size={20} />
            Save as Draft (Awaiting Shell)
          </button>

          <button
            onClick={() => handleSave('completed')}
            disabled={!isComplete || isSaving}
            className="flex-1 bg-hibiscus-pink hover:bg-pink-600 text-white font-bold py-4 rounded-xl shadow-md transition-all disabled:opacity-50 flex justify-center items-center gap-2"
          >
            <Save size={20} />
            Complete & Save Sample
          </button>
        </div>

      </div>

      {/* Dashboard Area */}
      <div className="w-full lg:w-72 bg-stitch-blue text-white rounded-xl p-5 shadow-md h-fit sticky top-6">
        <h3 className="text-lg font-bold border-b border-blue-400 pb-2 mb-4 uppercase tracking-wider">
          Quality Dashboard
        </h3>

        <div className="space-y-4">
          <DashMetric label="Avg Length" value={avgL !== null ? avgL.toFixed(2) : '--'} unit="mm" />
          <DashMetric label="Avg Width" value={avgW !== null ? avgW.toFixed(2) : '--'} unit="mm" />
          <DashMetric label="Shape Index" value={shapeIndex !== null ? shapeIndex.toFixed(2) : '--'} unit="%" />

          <div className="h-px bg-blue-800/50 my-2"></div>

          <DashMetric label="Yolk Percentage" value={yolkPct !== null ? yolkPct.toFixed(2) : '--'} unit="%" />
          <DashMetric label="Shell Percentage" value={shellPct !== null ? shellPct.toFixed(2) : '--'} unit="%" />

          <div className="bg-blue-900/50 p-3 rounded-lg mt-4 border border-blue-400/30">
            <div className="text-blue-200 text-xs font-bold uppercase mb-1">Haugh Unit (HU)</div>
            <div className="text-3xl font-black font-roboto-mono text-mint-green">
              {haughUnit !== null ? haughUnit.toFixed(2) : '--'}
            </div>
          </div>
        </div>
      </div>

    </div>
  );
};

const DashMetric = ({ label, value, unit }: { label: string, value: string | number, unit: string }) => (
  <div className="flex justify-between items-end">
    <span className="text-blue-200 text-sm font-bold">{label}</span>
    <div className="flex items-baseline gap-1">
      <span className="text-xl font-black font-roboto-mono">{value}</span>
      <span className="text-xs font-bold opacity-70">{unit}</span>
    </div>
  </div>
);
