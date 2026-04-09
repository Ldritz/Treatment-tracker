import { NextResponse } from 'next/server'
import { openDb } from '@/lib/db'

export const dynamic = 'force-dynamic';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url)
    const date = searchParams.get('date')

    if (!date) {
      return NextResponse.json({ error: 'Date parameter is required' }, { status: 400 })
    }

    const db = await openDb()
    const logs = await db.all('SELECT * FROM daily_logs WHERE date = ?', date)

    return NextResponse.json({ logs })
  } catch (error) {
    console.error('Error fetching logs:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

export async function POST(request: Request) {
  try {
    const data = await request.json()
    const { date, block, treatment, liveQuails, eggsLaid, eggMass, feedIntake, feedRefused } = data

    if (!date || block === undefined || !treatment || liveQuails === undefined || eggsLaid === undefined || feedIntake === undefined || feedRefused === undefined) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })
    }

    const db = await openDb()

    // Insert or replace existing entry for the same date, block, and treatment
    await db.run(`
      INSERT INTO daily_logs (date, block, treatment, liveQuails, eggsLaid, eggMass, feedIntake, feedRefused)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(date, block, treatment) DO UPDATE SET
        liveQuails = excluded.liveQuails,
        eggsLaid = excluded.eggsLaid,
        eggMass = excluded.eggMass,
        feedIntake = excluded.feedIntake,
        feedRefused = excluded.feedRefused,
        created_at = CURRENT_TIMESTAMP
    `, [date, block, treatment, liveQuails, eggsLaid, eggMass, feedIntake, feedRefused])

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error saving log:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
