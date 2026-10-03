import { Router } from 'express';
import { z } from 'zod';
import { badRequest, notFound } from '../errors.js';
import { requireAuth } from '../middleware/auth.js';
import { notificationDto, productDto } from '../serializers.js';
import { isUuid } from '../uuid.js';
import { parse } from '../validate.js';

/** Wishlist, notifications and promo validation. */
export function accountRouter(db) {
  const router = Router();

  // ---------------------------------------------------------------- wishlist
  router.get('/wishlist', requireAuth, async (req, res) => {
    const rows = await db.query(
      `SELECT p.* FROM wishlist w JOIN products p ON p.id = w.product_id
       WHERE w.user_id = $1 ORDER BY w.created_at DESC`,
      [req.user.id],
    );
    const favs = new Set(rows.map((r) => r.id));
    res.json(rows.map((r) => productDto(req, r, favs)));
  });

  // Idempotent: adding twice is fine.
  router.put('/wishlist/:productId', requireAuth, async (req, res) => {
    const product = await db.one('SELECT id FROM products WHERE id = $1', [
      req.params.productId,
    ]);
    if (!product) throw notFound('Product not found');
    await db.query(
      `INSERT INTO wishlist (user_id, product_id) VALUES ($1, $2)
       ON CONFLICT DO NOTHING`,
      [req.user.id, product.id],
    );
    res.status(204).end();
  });

  router.delete('/wishlist/:productId', requireAuth, async (req, res) => {
    await db.query('DELETE FROM wishlist WHERE user_id = $1 AND product_id = $2', [
      req.user.id,
      req.params.productId,
    ]);
    res.status(204).end();
  });

  // ----------------------------------------------------------- notifications
  router.get('/notifications', requireAuth, async (req, res) => {
    const rows = await db.query(
      'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 100',
      [req.user.id],
    );
    res.json({
      items: rows.map(notificationDto),
      unreadCount: rows.filter((r) => r.is_unread).length,
    });
  });

  router.post('/notifications/read-all', requireAuth, async (req, res) => {
    await db.query('UPDATE notifications SET is_unread = FALSE WHERE user_id = $1', [
      req.user.id,
    ]);
    res.status(204).end();
  });

  router.patch('/notifications/:id/read', requireAuth, async (req, res) => {
    if (!isUuid(req.params.id)) throw notFound('Notification not found');
    const updated = await db.query(
      `UPDATE notifications SET is_unread = FALSE
       WHERE id = $1 AND user_id = $2 RETURNING id`,
      [req.params.id, req.user.id],
    );
    if (!updated.length) throw notFound('Notification not found');
    res.status(204).end();
  });

  router.delete('/notifications/:id', requireAuth, async (req, res) => {
    if (isUuid(req.params.id)) {
      await db.query('DELETE FROM notifications WHERE id = $1 AND user_id = $2', [
        req.params.id,
        req.user.id,
      ]);
    }
    res.status(204).end();
  });

  // ------------------------------------------------------------------- promos
  const promoSchema = z.object({ code: z.string().trim().min(1).max(40) });
  router.post('/promos/validate', async (req, res) => {
    const { code } = parse(promoSchema, req.body);
    const promo = await db.one(
      'SELECT * FROM promo_codes WHERE code = $1 AND active',
      [code.toUpperCase()],
    );
    if (!promo) throw badRequest('Invalid promo code');
    res.json({ code: promo.code, discountPercent: promo.discount_percent });
  });

  return router;
}
