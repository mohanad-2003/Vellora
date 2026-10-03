import { Router } from 'express';
import { randomInt, randomUUID } from 'node:crypto';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { config } from '../config.js';
import { ApiError, badRequest, conflict, unauthorized } from '../errors.js';
import { requireAuth, signAccessToken } from '../middleware/auth.js';
import { notify } from '../notify.js';
import { userDto } from '../serializers.js';
import { parse } from '../validate.js';

const email = z.string().trim().toLowerCase().pipe(z.email('Invalid email'));
const password = z
  .string()
  .min(6, 'Password must be at least 6 characters')
  .max(128);

const registerSchema = z.object({
  name: z.string().trim().min(2, 'Name is too short').max(80),
  email,
  password,
});
const loginSchema = z.object({ email, password: z.string().min(1) });
const forgotSchema = z.object({ email });
const verifySchema = z.object({ email, code: z.string().regex(/^\d{4}$/) });
const resetSchema = z.object({ resetToken: z.string().min(1), newPassword: password });
const profileSchema = z.object({ name: z.string().trim().min(2).max(80) });
const changePasswordSchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: password,
});

const UNIQUE_VIOLATION = '23505';

export function authRouter(db) {
  const router = Router();

  router.post('/auth/register', async (req, res) => {
    const body = parse(registerSchema, req.body);
    const id = randomUUID();
    const hash = await bcrypt.hash(body.password, 10);

    let user;
    try {
      user = await db.tx(async (t) => {
        const row = await t.one(
          `INSERT INTO users (id, name, email, password_hash)
           VALUES ($1, $2, $3, $4) RETURNING *`,
          [id, body.name, body.email, hash],
        );
        await notify(t, id, 'system', 'Welcome to Vellora',
          'Your account is ready. Enjoy your first order with code WELCOME20.');
        return row;
      });
    } catch (e) {
      // The UNIQUE constraint is the source of truth: two simultaneous sign-ups
      // with the same email cannot both succeed.
      if (e?.code === UNIQUE_VIOLATION) {
        throw conflict('An account with this email already exists');
      }
      throw e;
    }
    res.status(201).json({ user: userDto(user), token: signAccessToken(user) });
  });

  router.post('/auth/login', async (req, res) => {
    const body = parse(loginSchema, req.body);
    const user = await db.one('SELECT * FROM users WHERE email = $1', [body.email]);
    // Same error for unknown email and wrong password: no account enumeration.
    const ok = user && (await bcrypt.compare(body.password, user.password_hash));
    if (!ok) throw new ApiError(401, 'invalid_credentials', 'Invalid email or password');
    res.json({ user: userDto(user), token: signAccessToken(user) });
  });

  router.post('/auth/forgot-password', async (req, res) => {
    const { email: addr } = parse(forgotSchema, req.body);
    const user = await db.one('SELECT id FROM users WHERE email = $1', [addr]);
    const response = {
      message: 'If an account exists, a verification code has been sent.',
    };
    if (user) {
      const code = String(randomInt(0, 10_000)).padStart(4, '0');
      await db.query(
        `INSERT INTO otp_codes (email, code_hash, expires_at, attempts)
         VALUES ($1, $2, $3, 0)
         ON CONFLICT (email) DO UPDATE SET code_hash = EXCLUDED.code_hash,
           expires_at = EXCLUDED.expires_at, attempts = 0`,
        [addr, await bcrypt.hash(code, 8), new Date(Date.now() + config.otpTtlMs)],
      );
      // No email provider is wired up yet: surface the code outside production.
      if (!config.isProd) {
        console.log(`[dev] password reset code for ${addr}: ${code}`);
        response.devCode = code;
      }
    }
    res.status(202).json(response);
  });

  router.post('/auth/verify-otp', async (req, res) => {
    const { email: addr, code } = parse(verifySchema, req.body);
    const row = await db.one('SELECT * FROM otp_codes WHERE email = $1', [addr]);
    const invalid = () =>
      new ApiError(400, 'invalid_code', 'The verification code is incorrect or expired');
    if (!row || row.expires_at < new Date() || row.attempts >= config.otpMaxAttempts) {
      throw invalid();
    }
    if (!(await bcrypt.compare(code, row.code_hash))) {
      await db.query('UPDATE otp_codes SET attempts = attempts + 1 WHERE email = $1', [addr]);
      throw invalid();
    }
    await db.query('DELETE FROM otp_codes WHERE email = $1', [addr]);
    const resetToken = jwt.sign({ email: addr, typ: 'reset' }, config.jwtSecret, {
      expiresIn: config.resetTokenExpiresIn,
    });
    res.json({ resetToken });
  });

  router.post('/auth/reset-password', async (req, res) => {
    const body = parse(resetSchema, req.body);
    let payload;
    try {
      payload = jwt.verify(body.resetToken, config.jwtSecret);
    } catch {
      throw badRequest('Reset session expired, please try again');
    }
    if (payload.typ !== 'reset') throw badRequest('Reset session expired, please try again');
    const hash = await bcrypt.hash(body.newPassword, 10);
    const updated = await db.query(
      'UPDATE users SET password_hash = $1 WHERE email = $2 RETURNING id',
      [hash, payload.email],
    );
    if (!updated.length) throw badRequest('Reset session expired, please try again');
    res.json({ message: 'Password updated' });
  });

  router.get('/me', requireAuth, async (req, res) => {
    const user = await db.one('SELECT * FROM users WHERE id = $1', [req.user.id]);
    if (!user) throw unauthorized('Account no longer exists');
    res.json({ user: userDto(user) });
  });

  router.patch('/me', requireAuth, async (req, res) => {
    const body = parse(profileSchema, req.body);
    const user = await db.one(
      'UPDATE users SET name = $1 WHERE id = $2 RETURNING *',
      [body.name, req.user.id],
    );
    if (!user) throw unauthorized('Account no longer exists');
    res.json({ user: userDto(user) });
  });

  router.post('/me/change-password', requireAuth, async (req, res) => {
    const body = parse(changePasswordSchema, req.body);
    const user = await db.one('SELECT * FROM users WHERE id = $1', [req.user.id]);
    if (!user || !(await bcrypt.compare(body.currentPassword, user.password_hash))) {
      throw badRequest('Current password is incorrect');
    }
    const hash = await bcrypt.hash(body.newPassword, 10);
    await db.query('UPDATE users SET password_hash = $1 WHERE id = $2', [hash, user.id]);
    res.json({ message: 'Password updated' });
  });

  return router;
}
