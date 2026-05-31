const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

const dataDir = path.join(__dirname, 'data');
if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });

const db = new Database(path.join(dataDir, 'brakeknights.db'));
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(`
  CREATE TABLE IF NOT EXISTS leads (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at        TEXT    NOT NULL DEFAULT (datetime('now')),
    first_name        TEXT    NOT NULL,
    last_name         TEXT    NOT NULL,
    phone             TEXT    NOT NULL,
    email             TEXT,
    vehicle           TEXT,
    service           TEXT,
    message           TEXT,
    preferred_contact TEXT,
    source            TEXT,
    status            TEXT    NOT NULL DEFAULT 'new',
    square_customer_id TEXT
  );

  CREATE TABLE IF NOT EXISTS quotes (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    lead_id           INTEGER NOT NULL REFERENCES leads(id),
    created_at        TEXT    NOT NULL DEFAULT (datetime('now')),
    sent_at           TEXT,
    service           TEXT,
    tier              TEXT,
    price_parts_labor REAL    NOT NULL DEFAULT 0,
    shop_supplies     REAL    NOT NULL DEFAULT 0,
    tax_rate          REAL    NOT NULL DEFAULT 0,
    tax               REAL    NOT NULL DEFAULT 0,
    total             REAL    NOT NULL DEFAULT 0,
    vin               TEXT,
    internal_notes    TEXT,
    status            TEXT    NOT NULL DEFAULT 'draft'
  );
`);

module.exports = db;
