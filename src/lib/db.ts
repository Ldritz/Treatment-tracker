import sqlite3 from 'sqlite3'
import { open, Database } from 'sqlite'
import path from 'path'

// Database file path
// Use /tmp in production (Vercel) since it's the only writable directory
const dbPath = process.env.NODE_ENV === 'production'
  ? path.join('/tmp', 'database.sqlite')
  : path.join(process.cwd(), 'database.sqlite')

// Singleton to reuse database connection
let dbInstance: Database<sqlite3.Database, sqlite3.Statement> | null = null

export async function openDb() {
  if (dbInstance) {
    return dbInstance
  }

  dbInstance = await open({
    filename: dbPath,
    driver: sqlite3.Database
  })

  // Initialize schema
  await dbInstance.exec(`
    CREATE TABLE IF NOT EXISTS daily_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      block INTEGER NOT NULL,
      treatment TEXT NOT NULL,
      liveQuails INTEGER NOT NULL,
      eggsLaid INTEGER NOT NULL,
      eggMass REAL,
      feedIntake REAL NOT NULL,
      feedRefused REAL NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(date, block, treatment)
    );

    CREATE TABLE IF NOT EXISTS egg_quality_logs (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL,
      block INTEGER NOT NULL,
      treatment TEXT NOT NULL,
      l1 REAL,
      l2 REAL,
      l3 REAL,
      w1 REAL,
      w2 REAL,
      w3 REAL,
      intactEggWeight REAL,
      albumenHeight REAL,
      yolkWeight REAL,
      dryShellWeight REAL,
      status TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `)

  return dbInstance
}
