// Runs the API test suite against a real PostgreSQL server.
//
//   TEST_DATABASE_URL=postgres://user:pass@localhost:5432/vellora_test npm run test:pg
//
// WARNING: the target database is wiped (DROP SCHEMA public CASCADE) before the
// run. Use an empty, disposable database.
import { spawn } from 'node:child_process';

if (!process.env.TEST_DATABASE_URL) {
  console.error(
    'Set TEST_DATABASE_URL to an empty, disposable PostgreSQL database, e.g.
' +
      '  TEST_DATABASE_URL=postgres://postgres:postgres@localhost:5432/vellora_test npm run test:pg',
  );
  process.exit(1);
}

const child = spawn(
  process.execPath,
  ['--disable-warning=ExperimentalWarning', '--test', 'test/api.test.js'],
  { stdio: 'inherit', env: process.env },
);
child.on('exit', (code) => process.exit(code ?? 1));
