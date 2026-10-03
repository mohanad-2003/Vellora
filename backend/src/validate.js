import { badRequest } from './errors.js';

/** Parses [data] with a zod [schema]; throws a 400 listing every bad field. */
export function parse(schema, data) {
  const result = schema.safeParse(data ?? {});
  if (result.success) return result.data;
  const details = result.error.issues.map((i) => ({
    field: i.path.join('.'),
    message: i.message,
  }));
  throw badRequest('Validation failed', details);
}
