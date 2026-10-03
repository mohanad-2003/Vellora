const env = process.env;
const isProd = env.NODE_ENV === 'production';

if (isProd && !env.DATABASE_URL) {
  throw new Error('DATABASE_URL (PostgreSQL) must be set in production');
}
if (isProd && (!env.JWT_SECRET || env.JWT_SECRET === 'change-me')) {
  throw new Error('JWT_SECRET must be set to a strong value in production');
}

export const config = {
  isProd,
  isTest: env.NODE_ENV === 'test',
  port: Number(env.PORT ?? 3000),
  jwtSecret: env.JWT_SECRET ?? 'dev-only-secret-change-me',
  jwtExpiresIn: env.JWT_EXPIRES_IN ?? '7d',
  // PostgreSQL connection string. When unset, an embedded Postgres (PGlite)
  // stores its files in pgliteDir: fine for development, not for production.
  databaseUrl: env.DATABASE_URL || undefined,
  // Set DATABASE_SSL=true for hosted databases reached over the public internet.
  databaseSsl: env.DATABASE_SSL === 'true',
  pgliteDir: env.PGLITE_DIR ?? './data/pgdata',
  corsOrigin: env.CORS_ORIGIN ?? '*',
  // Business rules shared with the Flutter app.
  freeShippingThreshold: 100,
  standardShipping: 9.99,
  expressShipping: 14.99,
  otpTtlMs: 10 * 60 * 1000,
  otpMaxAttempts: 5,
  resetTokenExpiresIn: '15m',
};
