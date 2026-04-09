import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { ClipboardList, Microscope } from 'lucide-react';

export const Navigation = () => {
  const pathname = usePathname();

  return (
    <nav className="flex items-center justify-center gap-4 mb-6">
      <Link
        href="/"
        className={`flex items-center gap-2 px-6 py-3 rounded-full font-bold transition-all ${
          pathname === '/'
            ? 'bg-stitch-blue text-white shadow-md'
            : 'bg-white text-gray-500 hover:bg-blue-50 hover:text-stitch-blue border border-gray-200'
        }`}
      >
        <ClipboardList size={20} />
        Daily Rounds
      </Link>
      <Link
        href="/quality-lab"
        className={`flex items-center gap-2 px-6 py-3 rounded-full font-bold transition-all ${
          pathname === '/quality-lab'
            ? 'bg-stitch-blue text-white shadow-md'
            : 'bg-white text-gray-500 hover:bg-blue-50 hover:text-stitch-blue border border-gray-200'
        }`}
      >
        <Microscope size={20} />
        Quality Lab
      </Link>
    </nav>
  );
};
