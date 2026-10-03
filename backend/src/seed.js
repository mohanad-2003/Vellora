import { readFileSync, rmSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join, resolve } from 'node:path';
import { openDb } from './db.js';
import { config } from './config.js';

const here = dirname(fileURLToPath(import.meta.url));
const products = JSON.parse(
  readFileSync(join(here, '..', 'data', 'products.json'), 'utf8'),
);

const CATEGORIES = [
  ['men', 'Men', 'products/product_hoodie_black.png'],
  ['women', 'Women', 'products/product_dress_black_trench.png'],
  ['shoes', 'Shoes', 'products/product_sneakers_high_top_mono.png'],
  ['accessories', 'Accessories', 'products/product_watch_aviator.png'],
  ['beauty', 'Beauty', 'products/product_lipstick_red.png'],
  ['electronics', 'Electronics', 'products/product_camera_dslr.png'],
  ['grocery', 'Grocery', 'products/product_hot_chocolate.png'],
];

const BANNERS = [
  ['summer', 'Summer Collection', 'Up to 50% off selected styles',
    'products/product_dress_black_trench.png'],
  ['flash', 'Flash Sale', 'Ends soon — grab it fast',
    'products/product_sneakers_street_orange.png'],
  ['new', 'New Arrivals', 'Fresh drops every week',
    'banners/banner_shopping_woman.png'],
];

const PROMOS = [['SAVE10', 10], ['WELCOME20', 20]];

function variantsFor(category) {
  switch (category) {
    case 'shoes':
      return {
        colors: ['Black', 'White', 'Red', 'Navy'],
        sizes: ['39', '40', '41', '42', '43', '44', '45'],
      };
    case 'men':
    case 'women':
      return {
        colors: ['Black', 'Sand', 'Navy', 'Olive'],
        sizes: ['XS', 'S', 'M', 'L', 'XL'],
      };
    case 'accessories':
      return { colors: ['Black', 'Sand', 'Navy'], sizes: [] };
    default:
      return { colors: [], sizes: [] };
  }
}

const REVIEWS = [
  ['Sarah M.', 5, 'Absolutely love it — exactly as pictured and great quality.', 2],
  ['James K.', 4, 'Solid value for the price. Fits true to size.', 7],
  ['Aisha R.', 5, 'Shipped fast and looks premium. Would buy again.', 21],
];

/** Fills an empty database with the catalogue. No-op when products exist. */
export async function seedIfEmpty(db) {
  const { n } = await db.one('SELECT COUNT(*)::int AS n FROM products');
  if (n > 0) return false;

  await db.tx(async (t) => {
    for (const [i, [id, name, image]] of CATEGORIES.entries()) {
      await t.query(
        'INSERT INTO categories (id, name, image, sort) VALUES ($1, $2, $3, $4)',
        [id, name, image, i],
      );
    }
    for (const [i, [id, title, subtitle, image]] of BANNERS.entries()) {
      await t.query(
        'INSERT INTO banners (id, title, subtitle, image, sort) VALUES ($1, $2, $3, $4, $5)',
        [id, title, subtitle, image, i],
      );
    }
    for (const [code, pct] of PROMOS) {
      await t.query(
        'INSERT INTO promo_codes (code, discount_percent) VALUES ($1, $2)',
        [code, pct],
      );
    }

    for (const [index, p] of products.entries()) {
      const v = variantsFor(p.category);
      await t.query(
        `INSERT INTO products (id, name, brand, category_id, price, original_price,
           rating, review_count, image, description, colors, sizes, position)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)`,
        [
          p.id, p.name, p.brand, p.category, p.price, p.originalPrice ?? null,
          p.rating, p.reviewCount, p.image,
          `${p.brand} presents the ${p.name} — crafted from premium materials ` +
            'with meticulous attention to detail. Designed for everyday comfort ' +
            'and a timeless, versatile look that pairs with anything in your ' +
            'wardrobe.',
          JSON.stringify(v.colors), JSON.stringify(v.sizes), index,
        ],
      );

      // Gallery: own shot first, then a few from the same category.
      const extras = products
        .filter((o) => o.category === p.category && o.id !== p.id)
        .slice(0, 3)
        .map((o) => o.image);
      for (const [i, img] of [p.image, ...extras].entries()) {
        await t.query(
          'INSERT INTO product_images (product_id, pos, image) VALUES ($1, $2, $3)',
          [p.id, i, img],
        );
      }

      for (const [author, rating, comment, daysAgo] of REVIEWS) {
        const when = new Date(Date.now() - daysAgo * 86_400_000);
        await t.query(
          `INSERT INTO reviews (product_id, author, rating, comment, created_at)
           VALUES ($1, $2, $3, $4, $5)`,
          [p.id, author, rating, comment, when],
        );
      }
    }
  });
  return true;
}

// `node src/seed.js [--reset]`  (--reset wipes the embedded dev database)
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (process.argv.includes('--reset')) {
    if (config.databaseUrl) {
      console.error('--reset only works with the embedded dev database, not DATABASE_URL.');
      process.exit(1);
    }
    if (existsSync(config.pgliteDir)) rmSync(config.pgliteDir, { recursive: true });
  }
  const db = await openDb({ url: config.databaseUrl, dataDir: config.pgliteDir });
  console.log((await seedIfEmpty(db)) ? 'Database seeded.' : 'Database already has data.');
  await db.close();
}
