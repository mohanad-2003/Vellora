import { Router } from 'express';
import { z } from 'zod';
import { notFound } from '../errors.js';
import { optionalAuth, requireAuth } from '../middleware/auth.js';
import { imageUrl, productDto, reviewDto } from '../serializers.js';
import { parse } from '../validate.js';

// Whitelist: the sort key picks the SQL, user input is never interpolated.
const SORTS = {
  relevance: 'p.position ASC',
  newest: 'p.position DESC',
  price_asc: 'p.price ASC, p.position ASC',
  price_desc: 'p.price DESC, p.position ASC',
  rating: 'p.rating DESC, p.review_count DESC, p.position ASC',
  popular: 'p.review_count DESC, p.position ASC',
  discount:
    '(CASE WHEN p.original_price IS NOT NULL THEN (p.original_price - p.price) / p.original_price ELSE 0 END) DESC, p.position ASC',
};

const num = z.coerce.number();
const csv = z
  .string()
  .trim()
  .transform((v) => v.split(',').map((s) => s.trim()).filter(Boolean).slice(0, 100))
  .optional();

const listSchema = z.object({
  category: z.string().trim().optional(),
  q: z.string().trim().max(100).optional(),
  brand: csv,
  ids: csv,
  sort: z.enum(Object.keys(SORTS)).default('relevance'),
  minPrice: num.min(0).optional(),
  maxPrice: num.min(0).optional(),
  minRating: num.min(0).max(5).optional(),
  onSale: z.enum(['true', 'false']).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

const reviewSchema = z.object({
  rating: z.number().int().min(1).max(5),
  comment: z.string().trim().min(3).max(1000),
});

const escapeLike = (s) => s.replace(/[\\%_]/g, (c) => `\\${c}`);

const CATEGORIES_SQL = `
  SELECT c.*, (SELECT COUNT(*)::int FROM products p WHERE p.category_id = c.id) AS count
  FROM categories c ORDER BY c.sort`;

export function catalogRouter(db) {
  const router = Router();

  const favoritesOf = async (req) =>
    req.user
      ? new Set(
          (
            await db.query('SELECT product_id FROM wishlist WHERE user_id = $1', [
              req.user.id,
            ])
          ).map((r) => r.product_id),
        )
      : null;

  const categoryDto = (req, c) => ({
    id: c.id,
    name: c.name,
    imageUrl: imageUrl(req, c.image),
    productCount: c.count,
  });

  router.get('/categories', async (req, res) => {
    const rows = await db.query(CATEGORIES_SQL);
    res.json(rows.map((c) => categoryDto(req, c)));
  });

  router.get('/home', optionalAuth, async (req, res) => {
    const favs = await favoritesOf(req);
    const all = await db.query('SELECT * FROM products ORDER BY position');
    const dto = (rows) => rows.map((r) => productDto(req, r, favs));
    const discount = (p) =>
      p.original_price ? (p.original_price - p.price) / p.original_price : 0;

    const flashSale = all
      .filter((p) => p.original_price && p.original_price > p.price)
      .sort((a, b) => discount(b) - discount(a));
    const bestSellers = [...all].sort((a, b) => b.review_count - a.review_count);
    const featured = all.filter((p) => p.rating >= 4.7);
    const newArrivals = [...all].reverse();
    const recommended = all.filter((_, i) => i % 2 === 0);

    const banners = await db.query('SELECT * FROM banners ORDER BY sort');
    const categories = await db.query(CATEGORIES_SQL);

    res.json({
      banners: banners.map((b) => ({
        id: b.id,
        title: b.title,
        subtitle: b.subtitle,
        imageUrl: imageUrl(req, b.image),
      })),
      categories: categories.map((c) => categoryDto(req, c)),
      featured: dto(featured.slice(0, 8)),
      flashSale: dto(flashSale.slice(0, 8)),
      newArrivals: dto(newArrivals.slice(0, 8)),
      bestSellers: dto(bestSellers.slice(0, 8)),
      recommended: dto(recommended.slice(0, 10)),
    });
  });

  // Facets for the filter sheet.
  router.get('/products/filters', async (_req, res) => {
    const brands = (await db.query('SELECT DISTINCT brand FROM products ORDER BY brand')).map(
      (r) => r.brand,
    );
    const range = await db.one('SELECT MIN(price) AS min, MAX(price) AS max FROM products');
    res.json({
      brands,
      priceMin: range.min ?? 0,
      priceMax: range.max ?? 0,
      sorts: Object.keys(SORTS),
    });
  });

  router.get('/products', optionalAuth, async (req, res) => {
    const f = parse(listSchema, req.query);
    const where = [];
    const params = [];
    // Registers a value and returns its $n placeholder.
    const arg = (value) => {
      params.push(value);
      return `$${params.length}`;
    };

    if (f.category) where.push(`p.category_id = ${arg(f.category)}`);
    if (f.q) {
      const like = arg(`%${escapeLike(f.q.toLowerCase())}%`);
      where.push(
        `(LOWER(p.name) LIKE ${like} OR LOWER(p.brand) LIKE ${like} OR LOWER(p.category_id) LIKE ${like})`,
      );
    }
    if (f.brand?.length) where.push(`p.brand = ANY(${arg(f.brand)}::text[])`);
    if (f.ids) where.push(`p.id = ANY(${arg(f.ids)}::text[])`);
    if (f.minPrice !== undefined) where.push(`p.price >= ${arg(f.minPrice)}`);
    if (f.maxPrice !== undefined) where.push(`p.price <= ${arg(f.maxPrice)}`);
    if (f.minRating !== undefined) where.push(`p.rating >= ${arg(f.minRating)}`);
    if (f.onSale === 'true') {
      where.push('p.original_price IS NOT NULL AND p.original_price > p.price');
    }

    const clause = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const { total } = await db.one(
      `SELECT COUNT(*)::int AS total FROM products p ${clause}`,
      params,
    );
    const limit = arg(f.limit);
    const offset = arg((f.page - 1) * f.limit);
    const rows = await db.query(
      `SELECT p.* FROM products p ${clause} ORDER BY ${SORTS[f.sort]} LIMIT ${limit} OFFSET ${offset}`,
      params,
    );

    const favs = await favoritesOf(req);
    res.json({
      items: rows.map((r) => productDto(req, r, favs)),
      page: f.page,
      limit: f.limit,
      total,
      totalPages: Math.max(1, Math.ceil(total / f.limit)),
    });
  });

  router.get('/products/:id', optionalAuth, async (req, res) => {
    const row = await db.one('SELECT * FROM products WHERE id = $1', [req.params.id]);
    if (!row) throw notFound('Product not found');
    const gallery = (
      await db.query('SELECT image FROM product_images WHERE product_id = $1 ORDER BY pos', [
        row.id,
      ])
    ).map((g) => imageUrl(req, g.image));
    const reviews = await db.query(
      'SELECT * FROM reviews WHERE product_id = $1 ORDER BY created_at DESC LIMIT 20',
      [row.id],
    );
    res.json({
      product: productDto(req, row, await favoritesOf(req)),
      gallery,
      description: row.description,
      variant: { colors: row.colors, sizes: row.sizes },
      reviews: reviews.map(reviewDto),
    });
  });

  router.get('/products/:id/related', optionalAuth, async (req, res) => {
    const row = await db.one('SELECT * FROM products WHERE id = $1', [req.params.id]);
    if (!row) throw notFound('Product not found');
    const rows = await db.query(
      `SELECT * FROM products WHERE category_id = $1 AND id <> $2
       ORDER BY review_count DESC, position LIMIT 6`,
      [row.category_id, row.id],
    );
    const favs = await favoritesOf(req);
    res.json(rows.map((r) => productDto(req, r, favs)));
  });

  router.get('/products/:id/reviews', async (req, res) => {
    const exists = await db.one('SELECT 1 FROM products WHERE id = $1', [req.params.id]);
    if (!exists) throw notFound('Product not found');
    const rows = await db.query(
      'SELECT * FROM reviews WHERE product_id = $1 ORDER BY created_at DESC',
      [req.params.id],
    );
    res.json(rows.map(reviewDto));
  });

  router.post('/products/:id/reviews', requireAuth, async (req, res) => {
    const body = parse(reviewSchema, req.body);
    const review = await db.tx(async (t) => {
      // Lock the product row so concurrent reviews update the aggregate in turn.
      const product = await t.one('SELECT id FROM products WHERE id = $1 FOR UPDATE', [
        req.params.id,
      ]);
      if (!product) throw notFound('Product not found');
      const user = await t.one('SELECT name FROM users WHERE id = $1', [req.user.id]);

      const row = await t.one(
        `INSERT INTO reviews (product_id, user_id, author, rating, comment)
         VALUES ($1, $2, $3, $4, $5) RETURNING *`,
        [product.id, req.user.id, user.name, body.rating, body.comment],
      );
      // Keep the product's displayed aggregate in step with the new review.
      await t.query(
        `UPDATE products SET
           rating = ROUND((rating * review_count + $1)::numeric / (review_count + 1), 1),
           review_count = review_count + 1
         WHERE id = $2`,
        [body.rating, product.id],
      );
      return row;
    });
    res.status(201).json(reviewDto(review));
  });

  return router;
}
