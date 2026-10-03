import jwt from 'jsonwebtoken';
import { config } from '../config.js';
import { unauthorized } from '../errors.js';

export function signAccessToken(user) {
  return jwt.sign({ email: user.email, typ: 'access' }, config.jwtSecret, {
    subject: user.id,
    expiresIn: config.jwtExpiresIn,
  });
}

function readUser(req) {
  const header = req.get('authorization') ?? '';
  const [scheme, token] = header.split(' ');
  if (scheme?.toLowerCase() !== 'bearer' || !token) return null;
  try {
    const payload = jwt.verify(token, config.jwtSecret);
    if (payload.typ !== 'access') return null;
    return { id: payload.sub, email: payload.email };
  } catch {
    return null;
  }
}

/** Rejects the request unless it carries a valid access token. */
export function requireAuth(req, _res, next) {
  const user = readUser(req);
  if (!user) return next(unauthorized('Invalid or expired token'));
  req.user = user;
  next();
}

/** Attaches `req.user` when a valid token is present; never rejects. */
export function optionalAuth(req, _res, next) {
  req.user = readUser(req);
  next();
}
