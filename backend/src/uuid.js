const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Postgres rejects malformed UUIDs with an error; check first and answer 404. */
export const isUuid = (value) => typeof value === 'string' && UUID.test(value);
