import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { rateLimit } from 'express-rate-limit';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { config } from './config.js';
import { errorHandler, notFoundHandler } from './middleware/error.js';
import { authRouter } from './routes/auth.js';
import { catalogRouter } from './routes/catalog.js';
import { accountRouter } from './routes/account.js';
import { ordersRouter } from './routes/orders.js';

const publicDir = join(dirname(fileURLToPath(import.meta.url)), '..', 'public');

export function createApp(db) {
  const app = express();
  app.disable('x-powered-by');
  // Correct req.protocol / host when running behind a reverse proxy.
  app.set('trust proxy', config.isProd ? 1 : false);

  app.use(
    helmet({
      // Product images are loaded by the app (a different origin).
      crossOriginResourcePolicy: { policy: 'cross-origin' },
    }),
  );
  app.use(
    cors({
      origin: config.corsOrigin === '*' ? true : config.corsOrigin.split(','),
    }),
  );
  if (!config.isTest) app.use(morgan(config.isProd ? 'combined' : 'dev'));
  app.use(express.json({ limit: '100kb' }));

  app.use('/static', express.static(publicDir, { maxAge: '7d', index: false }));

  app.get('/health', async (_req, res) => {
    await db.query('SELECT 1');
    res.json({ status: 'ok' });
  });

  // Brute-force protection on credential endpoints.
  if (!config.isTest) {
    app.use(
      ['/auth/login', '/auth/register', '/auth/forgot-password', '/auth/verify-otp'],
      rateLimit({
        windowMs: 15 * 60 * 1000,
        limit: 30,
        standardHeaders: 'draft-7',
        legacyHeaders: false,
        message: {
          error: { code: 'rate_limited', message: 'Too many attempts, try again later' },
        },
      }),
    );
  }

  app.use(authRouter(db));
  app.use(catalogRouter(db));
  app.use(accountRouter(db));
  app.use(ordersRouter(db));

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
