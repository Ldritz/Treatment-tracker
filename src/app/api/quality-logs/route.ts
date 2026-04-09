import { NextResponse } from 'next/server'
import { openDb } from '@/lib/db'

export const dynamic = 'force-dynamic';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url)
    const date = searchParams.get('date')

    const db = await openDb()

    let logs;
    if (date) {
      logs = await db.all('SELECT * FROM egg_quality_logs WHERE date = ? ORDER BY updated_at DESC', date)
    } else {
      logs = await db.all('SELECT * FROM egg_quality_logs ORDER BY updated_at DESC')
    }

    return NextResponse.json({ logs })
  } catch (error) {
    console.error('Error fetching quality logs:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

export async function POST(request: Request) {
  try {
    const data = await request.json()
    const {
      id, date, block, treatment,
      l1, l2, l3, w1, w2, w3,
      intactEggWeight, albumenHeight, yolkWeight, dryShellWeight, status
    } = data

    if (!id || !date || block === undefined || !treatment || !status) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })
    }

    const db = await openDb()

    await db.run(`
      INSERT INTO egg_quality_logs (
        id, date, block, treatment, l1, l2, l3, w1, w2, w3,
        intactEggWeight, albumenHeight, yolkWeight, dryShellWeight, status, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
      ON CONFLICT(id) DO UPDATE SET
        date = excluded.date,
        block = excluded.block,
        treatment = excluded.treatment,
        l1 = excluded.l1,
        l2 = excluded.l2,
        l3 = excluded.l3,
        w1 = excluded.w1,
        w2 = excluded.w2,
        w3 = excluded.w3,
        intactEggWeight = excluded.intactEggWeight,
        albumenHeight = excluded.albumenHeight,
        yolkWeight = excluded.yolkWeight,
        dryShellWeight = excluded.dryShellWeight,
        status = excluded.status,
        updated_at = CURRENT_TIMESTAMP
    `, [
      id, date, block, treatment,
      l1, l2, l3, w1, w2, w3,
      intactEggWeight, albumenHeight, yolkWeight, dryShellWeight, status
    ])

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error saving quality log:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
