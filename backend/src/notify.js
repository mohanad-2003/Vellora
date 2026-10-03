import { randomUUID } from 'node:crypto';

/**
 * Stores an in-app notification for [userId]. [db] may be a transaction handle
 * so the notification commits (or rolls back) with the change that caused it.
 */
export function notify(db, userId, kind, title, body) {
  return db.query(
    `INSERT INTO notifications (id, user_id, kind, title, body)
     VALUES ($1, $2, $3, $4, $5)`,
    [randomUUID(), userId, kind, title, body],
  );
}
