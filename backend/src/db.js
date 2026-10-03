import { readdirSync, readFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import pg from 'pg';
import { PGlite } from '@electric-sql/pglite';

const migrationsDir = join(
  dirname(fileURLToPath(import.meta.url)),
  '..',
  'migrations',
);

// pg returns BIGINT (COUNT, identity ids) as strings by default. Our counts and
// ids fit comfortably in a JS number.
pg.types.setTypeParser(20, (v) => Number(v));

/**
 * Thin, driver-independent database handle.
 *
 *   await db.query('SELECT * FROM users WHERE id = $1', [id])  // -> rows[]
 *   await db.one('SELECT ...', [..])                           // -> row | undefined
 *   await db.tx(async (t) => { await t.query(...); ... })      // atomic
 *
 * Two backends share it:
 *  - **PostgreSQL** (`pg` pool) when a `url` / DATABASE_URL is given: production.
 *  - **PGlite** (a real Postgres compiled to WebAssembly, in-process) otherwise:
 *    zero-install development and tests. Pass `memory://` for a throwaway one.
 */
function wrap(runner, extra = {}) {
  const query = async (sql, params = []) => (await runner.query(sql, params)).rows;
  return {
    query,
    one: async (sql, params = []) => (await query(sql, params))[0],
    ...extra,
  };
}

export async function openDb({ url, ssl = false, dataDir = 'memory://' } = {}) {
  let db;

  if (url) {
    const pool = new pg.Pool({
      connectionString: url,
      max: Number(process.env.PGPOOL_MAX ?? 10),
      // Managed hosts use certificates Node does not know; the traffic is still encrypted.
      ssl: ssl ? { rejectUnauthorized: false } : undefined,
    });
    db = wrap(pool, {
      exec: (sql) => pool.query(sql),
      tx: async (fn) => {
        const client = await pool.connect();
        try {
          await client.query('BEGIN');
          const result = await fn(wrap(client, { exec: (sql) => client.query(sql) }));
          await client.query('COMMIT');
          return result;
        } catch (e) {
          await client.query('ROLLBACK');
          throw e;
        } finally {
          client.release();
        }
      },
      close: () => pool.end(),
      kind: 'postgres',
    });
  } else {
    if (!dataDir.startsWith('memory://')) mkdirSync(dataDir, { recursive: true });
    const lite = new PGlite(dataDir);
    await lite.waitReady;
    db = wrap(lite, {
      exec: (sql) => lite.exec(sql),
      tx: (fn) =>
        lite.transaction((t) => fn(wrap(t, { exec: (sql) => t.exec(sql) }))),
      close: () => lite.close(),
      kind: 'pglite',
    });
  }

  await migrate(db);
  return db;
}

/** Applies `migrations/*.sql` in filename order, once each. */
export async function migrate(db) {
  await db.exec(`CREATE TABLE IF NOT EXISTS schema_migrations (
    name TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
  )`);
  const done = new Set(
    (await db.query('SELECT name FROM schema_migrations')).map((r) => r.name),
  );
  const files = readdirSync(migrationsDir)
    .filter((f) => f.endsWith('.sql'))
    .sort();
  for (const file of files) {
    if (done.has(file)) continue;
    const sql = readFileSync(join(migrationsDir, file), 'utf8');
    await db.tx(async (t) => {
      await t.exec(sql);
      await t.query('INSERT INTO schema_migrations (name) VALUES ($1)', [file]);
    });
    console.log(`Applied migration ${file}`);
  }
}
