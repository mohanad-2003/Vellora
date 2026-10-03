import { ApiError } from '../errors.js';
import { config } from '../config.js';

export function notFoundHandler(req, _res, next) {
  next(new ApiError(404, 'not_found', `Route not found: ${req.method} ${req.path}`));
}

// Express recognises error handlers by their 4-argument signature.
// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, _next) {
  if (err instanceof ApiError) {
    return res.status(err.status).json({
      error: { code: err.code, message: err.message, details: err.details },
    });
  }
  // Malformed JSON body from express.json().
  if (err?.type === 'entity.parse.failed') {
    return res.status(400).json({
      error: { code: 'bad_request', message: 'Malformed JSON body' },
    });
  }
  if (err?.type === 'entity.too.large') {
    return res.status(413).json({
      error: { code: 'payload_too_large', message: 'Request body too large' },
    });
  }
  console.error(err);
  res.status(500).json({
    error: {
      code: 'internal_error',
      message: config.isProd ? 'Something went wrong' : String(err?.message),
    },
  });
}
