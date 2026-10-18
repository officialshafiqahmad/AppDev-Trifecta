const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');
const { applyReset, DEFAULT_STOCK } = require('./baseline');

function createPool() {
  const requested = Number(process.env.PG_POOL_MAX || 30);
  const max = Number.isInteger(requested) && requested > 0 ? requested : 30;
  return new Pool({ connectionString: process.env.DATABASE_URL, max });
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function waitForDb(pool) {
  let lastError;
  for (let attempt = 1; attempt <= 30; attempt += 1) {
    try {
      await pool.query('SELECT 1');
      return;
    } catch (error) {
      lastError = error;
      await sleep(1000);
    }
  }
  throw lastError;
}

async function migrate(pool) {
  const sql = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
  await pool.query(sql);
}

async function ensureBaseline(pool) {
  const existing = await pool.query('SELECT baseline_ready FROM meta WHERE id = 1');
  if (existing.rowCount === 1 && existing.rows[0].baseline_ready === true) return;
  await applyReset(pool, { seed: 42, stock: { ...DEFAULT_STOCK } });
}

async function databaseReady(pool) {
  const result = await pool.query('SELECT baseline_ready FROM meta WHERE id = 1');
  return result.rowCount === 1 && result.rows[0].baseline_ready === true;
}

module.exports = { createPool, waitForDb, migrate, ensureBaseline, databaseReady };
