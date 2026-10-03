import { createApp } from './app.js';
import { config } from './config.js';
import { openDb } from './db.js';
import { seedIfEmpty } from './seed.js';

const db = await openDb({
  url: config.databaseUrl,
  ssl: config.databaseSsl,
  dataDir: config.pgliteDir,
});
console.log(
  db.kind === 'postgres'
    ? 'Connected to PostgreSQL.'
    : `Using embedded Postgres (PGlite) in ${config.pgliteDir} — set DATABASE_URL for a real server.`,
);
if (await seedIfEmpty(db)) console.log('Seeded empty database with the catalogue.');

const server = createApp(db).listen(config.port, () => {
  console.log(`Vellora API listening on http://localhost:${config.port}`);
});

function shutdown(signal) {
  console.log(`${signal} received, shutting down`);
  server.close(async () => {
    await db.close();
    process.exit(0);
  });
  // Don't hang forever on open keep-alive connections.
  setTimeout(() => process.exit(1), 10_000).unref();
}
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
