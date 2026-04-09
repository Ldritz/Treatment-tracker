import { NextResponse } from 'next/server'
import { openDb } from '@/lib/db'

export async function GET() {
  try {
    const db = await openDb()
    const logs = await db.all('SELECT * FROM daily_logs ORDER BY date DESC, block ASC, treatment ASC')

    if (logs.length === 0) {
      return NextResponse.json({ message: 'No data to export' }, { status: 404 })
    }

    // Generate CSV
    const headers = ['Date', 'Block', 'Treatment', 'Live Quails', 'Eggs Laid', 'Egg Mass (g)', 'Feed Intake (g)', 'Feed Refused (g)']

    let csv = headers.join(',') + '\n'

    logs.forEach(log => {
      const row = [
        log.date,
        log.block,
        log.treatment,
        log.liveQuails,
        log.eggsLaid,
        log.eggMass !== null ? log.eggMass : '',
        log.feedIntake,
        log.feedRefused
      ]
      csv += row.join(',') + '\n'
    })

    return new NextResponse(csv, {
      status: 200,
      headers: {
        'Content-Type': 'text/csv',
        'Content-Disposition': 'attachment; filename="experiment_626_quail_data.csv"'
      }
    })
  } catch (error) {
    console.error('Error exporting logs:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
