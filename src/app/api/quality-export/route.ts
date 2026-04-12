import { NextResponse } from 'next/server'
import { openDb } from '@/lib/db'

export const dynamic = 'force-dynamic';

export async function GET() {
  try {
    const db = await openDb()
    const logs = await db.all('SELECT * FROM egg_quality_logs ORDER BY date DESC, block ASC, treatment ASC')

    if (logs.length === 0) {
      return NextResponse.json({ message: 'No data to export' }, { status: 404 })
    }

    const headers = [
      'ID', 'Date', 'Block', 'Treatment', 'Status',
      'Length 1 (mm)', 'Length 2 (mm)', 'Length 3 (mm)', 'Avg Length',
      'Width 1 (mm)', 'Width 2 (mm)', 'Width 3 (mm)', 'Avg Width',
      'Shape Index (%)',
      'Intact Egg Weight (g)', 'Albumen Height (mm)', 'Yolk Weight (g)', 'Dry Shell Weight (g)',
      'Yolk Percentage (%)', 'Shell Percentage (%)', 'Haugh Unit'
    ]

    const csvRows = [headers.join(',')]

    logs.forEach(log => {
      // Calculate averages and derived metrics for export
      let avgL = '';
      if (log.l1 !== null && log.l2 !== null && log.l3 !== null) {
        avgL = ((log.l1 + log.l2 + log.l3) / 3).toFixed(2);
      }

      let avgW = '';
      if (log.w1 !== null && log.w2 !== null && log.w3 !== null) {
        avgW = ((log.w1 + log.w2 + log.w3) / 3).toFixed(2);
      }

      let shapeIndex = '';
      if (avgL && avgW && parseFloat(avgL) > 0) {
        shapeIndex = ((parseFloat(avgW) / parseFloat(avgL)) * 100).toFixed(2);
      }

      let yolkPct = '';
      if (log.yolkWeight !== null && log.intactEggWeight !== null && log.intactEggWeight > 0) {
        yolkPct = ((log.yolkWeight / log.intactEggWeight) * 100).toFixed(2);
      }

      let shellPct = '';
      if (log.dryShellWeight !== null && log.intactEggWeight !== null && log.intactEggWeight > 0) {
        shellPct = ((log.dryShellWeight / log.intactEggWeight) * 100).toFixed(2);
      }

      let hu = '';
      if (log.albumenHeight !== null && log.intactEggWeight !== null) {
        const val = log.albumenHeight - 1.7 * Math.pow(log.intactEggWeight, 0.37) + 7.6;
        if (val > 0) {
            hu = (100 * Math.log10(val)).toFixed(2);
        }
      }

      const row = [
        log.id,
        log.date,
        log.block,
        log.treatment,
        log.status,
        log.l1 !== null ? log.l1 : '',
        log.l2 !== null ? log.l2 : '',
        log.l3 !== null ? log.l3 : '',
        avgL,
        log.w1 !== null ? log.w1 : '',
        log.w2 !== null ? log.w2 : '',
        log.w3 !== null ? log.w3 : '',
        avgW,
        shapeIndex,
        log.intactEggWeight !== null ? log.intactEggWeight : '',
        log.albumenHeight !== null ? log.albumenHeight : '',
        log.yolkWeight !== null ? log.yolkWeight : '',
        log.dryShellWeight !== null ? log.dryShellWeight : '',
        yolkPct,
        shellPct,
        hu
      ]
      csvRows.push(row.join(','))
    })

    const csv = csvRows.join('\n') + '\n'

    return new NextResponse(csv, {
      status: 200,
      headers: {
        'Content-Type': 'text/csv',
        'Content-Disposition': 'attachment; filename="experiment_626_egg_quality_data.csv"'
      }
    })
  } catch (error) {
    console.error('Error exporting quality logs:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
