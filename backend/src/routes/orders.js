import { Router } from 'express';
import { randomUUID } from 'node:crypto';
import { z } from 'zod';
import { config } from '../config.js';
import { ApiError, badRequest, notFound } from '../errors.js';
import { requireAuth } from '../middleware/auth.js';
import { notify } from '../notify.js';
import { orderDto } from '../serializers.js';
import { isUuid } from '../uuid.js';
import { parse } from '../validate.js';

export const ORDER_STATUSES = ['processing', 'shipped', 'delivered', 'cancelled'];

const orderSchema = z.object({
  items: z
    .array(
      z.object({
        productId: z.string().min(1),
        quantity: z.number().int().min(1).max(20),
        color: z.string().optional(),
        size: z.string().optional(),
      }),
    )
    .min(1, 'Order needs at least one item')
    .max(50),
  promoCode: z.string().trim().optional(),
  delivery: z.enum(['standard', 'express']).default('standard'),
  address: z.object({
    recipient: z.string().trim().min(2).max(80),
    phone: z.string().trim().max(30).optional(),
    line: z.string().trim().min(3).max(200),
    city: z.string().trim().min(2).max(80),
  }),
  payment: z.object({
    kind: z.enum(['card', 'paypal', 'cashOnDelivery']),
    detail: z.string().trim().max(60).default(''),
  }),
});

const money = (n) => Math.round(n * 100) / 100;

const STATUS_COPY = {
  shipped: ['Order shipped', 'is on its way.'],
  delivered: ['Order delivered', 'has been delivered. Enjoy!'],
  cancelled: ['Order cancelled', 'has been cancelled.'],
};

export function ordersRouter(db) {
  const router = Router();

  const itemsOf = (runner, orderId) =>
    runner.query('SELECT * FROM order_items WHERE order_id = $1 ORDER BY id', [orderId]);

  /** The caller's order, or 404 (also for malformed ids and other people's orders). */
  const ownOrder = async (req) => {
    if (!isUuid(req.params.id)) throw notFound('Order not found');
    const order = await db.one('SELECT * FROM orders WHERE id = $1 AND user_id = $2', [
      req.params.id,
      req.user.id,
    ]);
    if (!order) throw notFound('Order not found');
    return order;
  };

  router.post('/orders', requireAuth, async (req, res) => {
    const body = parse(orderSchema, req.body);

    const { order, items } = await db.tx(async (t) => {
      // Prices always come from the database, never from the client.
      const lines = [];
      for (const item of body.items) {
        const p = await t.one('SELECT * FROM products WHERE id = $1', [item.productId]);
        if (!p) throw badRequest(`Unknown product: ${item.productId}`);
        if (!p.in_stock) throw badRequest(`${p.name} is out of stock`);
        if (p.colors.length && !p.colors.includes(item.color)) {
          throw badRequest(`Choose a valid colour for ${p.name}`);
        }
        if (p.sizes.length && !p.sizes.includes(item.size)) {
          throw badRequest(`Choose a valid size for ${p.name}`);
        }
        lines.push({ p, ...item });
      }

      const subtotal = money(lines.reduce((s, l) => s + l.p.price * l.quantity, 0));

      let discount = 0;
      let promoCode = null;
      if (body.promoCode) {
        const promo = await t.one(
          'SELECT * FROM promo_codes WHERE code = $1 AND active',
          [body.promoCode.toUpperCase()],
        );
        if (!promo) throw badRequest('Invalid promo code');
        promoCode = promo.code;
        discount = money((subtotal * promo.discount_percent) / 100);
      }

      const shipping =
        body.delivery === 'express'
          ? config.expressShipping
          : subtotal >= config.freeShippingThreshold
            ? 0
            : config.standardShipping;
      const total = money(subtotal - discount + shipping);

      const { n } = await t.one("SELECT nextval('order_number_seq')::int AS n");
      const row = await t.one(
        `INSERT INTO orders (id, user_id, number, status, subtotal, discount, shipping,
           total, promo_code, delivery, recipient, phone, address_line, city,
           payment_kind, payment_detail)
         VALUES ($1, $2, $3, 'processing', $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
         RETURNING *`,
        [
          randomUUID(), req.user.id, `#VL-${n}`, subtotal, discount, shipping, total,
          promoCode, body.delivery, body.address.recipient, body.address.phone ?? null,
          body.address.line, body.address.city, body.payment.kind, body.payment.detail,
        ],
      );

      for (const l of lines) {
        await t.query(
          `INSERT INTO order_items (order_id, product_id, name, image, quantity, price, color, size)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
          [row.id, l.p.id, l.p.name, l.p.image, l.quantity, l.p.price, l.color ?? null, l.size ?? null],
        );
      }

      await notify(t, req.user.id, 'order', 'Order placed',
        `Thanks! Order ${row.number} was placed and is being processed.`);
      return { order: row, items: await itemsOf(t, row.id) };
    });

    res.status(201).json(orderDto(req, order, items));
  });

  router.get('/orders', requireAuth, async (req, res) => {
    const orders = await db.query(
      'SELECT * FROM orders WHERE user_id = $1 ORDER BY created_at DESC, number DESC',
      [req.user.id],
    );
    // One query for every item instead of one per order.
    const items = orders.length
      ? await db.query(
          'SELECT * FROM order_items WHERE order_id = ANY($1::uuid[]) ORDER BY id',
          [orders.map((o) => o.id)],
        )
      : [];
    res.json(
      orders.map((o) =>
        orderDto(req, o, items.filter((i) => i.order_id === o.id)),
      ),
    );
  });

  router.get('/orders/:id', requireAuth, async (req, res) => {
    const order = await ownOrder(req);
    res.json(orderDto(req, order, await itemsOf(db, order.id)));
  });

  router.post('/orders/:id/cancel', requireAuth, async (req, res) => {
    const order = await ownOrder(req);
    // The status check is part of the UPDATE, so a concurrent shipment cannot be
    // overwritten by a late cancellation.
    const updated = await db.tx(async (t) => {
      const row = await t.one(
        `UPDATE orders SET status = 'cancelled'
         WHERE id = $1 AND status = 'processing' RETURNING *`,
        [order.id],
      );
      if (row) {
        await notify(t, req.user.id, 'order', 'Order cancelled',
          `Order ${order.number} has been cancelled.`);
      }
      return row;
    });
    if (!updated) {
      throw new ApiError(409, 'conflict', 'Only orders that are still processing can be cancelled');
    }
    res.json(orderDto(req, updated, await itemsOf(db, order.id)));
  });

  // Back-office hook: move an order along. Disabled unless ADMIN_API_KEY is set.
  router.patch('/admin/orders/:id/status', async (req, res) => {
    const key = process.env.ADMIN_API_KEY;
    if (!key) throw notFound('Route not found');
    if (req.get('x-admin-key') !== key) {
      throw new ApiError(403, 'forbidden', 'Invalid admin key');
    }
    const { status } = parse(z.object({ status: z.enum(ORDER_STATUSES) }), req.body);
    if (!isUuid(req.params.id)) throw notFound('Order not found');

    const updated = await db.tx(async (t) => {
      const row = await t.one('UPDATE orders SET status = $1 WHERE id = $2 RETURNING *', [
        status,
        req.params.id,
      ]);
      const copy = STATUS_COPY[status];
      if (row && copy) {
        await notify(t, row.user_id, 'order', copy[0], `Order ${row.number} ${copy[1]}`);
      }
      return row;
    });
    if (!updated) throw notFound('Order not found');
    res.json(orderDto(req, updated, await itemsOf(db, updated.id)));
  });

  return router;
}
