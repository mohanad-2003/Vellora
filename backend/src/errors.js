/** Error with an HTTP status and a stable machine-readable code. */
export class ApiError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export const badRequest = (msg, details) =>
  new ApiError(400, 'bad_request', msg, details);
export const unauthorized = (msg = 'Authentication required') =>
  new ApiError(401, 'unauthorized', msg);
export const notFound = (msg = 'Not found') =>
  new ApiError(404, 'not_found', msg);
export const conflict = (msg) => new ApiError(409, 'conflict', msg);
