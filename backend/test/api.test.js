process.env.NODE_ENV = 'test';
process.env.ADMIN_API_KEY = 'test-admin-key';

import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';

const { createApp } = await import('../src/app.js');
const { openDb } = await import('../src/db.js');
const { seedIfEmpty } = await import('../src/seed.js');

let server;
let base;
let db;

before(async () => {
  const url = process.env.TEST_DATABASE_URL;
  if (url) {
    // Disposable PostgreSQL (see scripts/test-pg.mjs): start from a clean slate.
    const { default: pg } = await import('pg');
    const client = new pg.Client({ connectionString: url });
    await client.connect();
    await client.query('DROP SCHEMA public CASCADE');
    await client.query('CREATE SCHEMA public');
    await client.end();
  }
  db = await openDb({ url }); // PostgreSQL via `pg`, else embedded in-memory PGlite
  await seedIfEmpty(db);
  server = createApp(db).listen(0);
  await new Promise((r) => server.once('listening', r));
  base = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  server.close();
  await db.close();
});

async function call(method, path, { body, token, headers } = {}) {
  const res = await fetch(base + path, {
    method,
    headers: {
      ...(body ? { 'content-type': 'application/json' } : {}),
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...headers,
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  return { status: res.status, body: text ? JSON.parse(text) : null };
}

async function signUp(email = `u${Date.now()}${Math.random()}@test.com`) {
  const r = await call('POST', '/auth/register', {
    body: { name: 'Test User', email, password: 'secret12' },
  });
  assert.equal(r.status, 201);
  return { token: r.body.token, user: r.body.user, email };
}

test('health check', async () => {
  const r = await call('GET', '/health');
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'ok');
});

test('home payload has every rail with absolute image urls', async () => {
  const r = await call('GET', '/home');
  assert.equal(r.status, 200);
  for (const key of ['banners', 'categories', 'featured', 'flashSale', 'newArrivals', 'bestSellers', 'recommended']) {
    assert.ok(r.body[key].length > 0, key);
  }
  assert.match(r.body.featured[0].imageUrl, /^http:\/\/127\.0\.0\.1:\d+\/static\/images\/products\//);
  assert.equal(r.body.categories.length, 7);
});

test('packshot photos are tagged in their url', async () => {
  const r = await call('GET', '/products/p2'); // star print shirt is a packshot
  assert.match(r.body.product.imageUrl, /\?packshot=1$/);
  const lifestyle = await call('GET', '/products/p1');
  assert.doesNotMatch(lifestyle.body.product.imageUrl, /packshot/);
});

test('static product images are served', async () => {
  const home = await call('GET', '/home');
  const res = await fetch(home.body.featured[0].imageUrl);
  assert.equal(res.status, 200);
  assert.match(res.headers.get('content-type'), /image\/png/);
});

test('product list: filters, search, sort and pagination', async () => {
  const shoes = await call('GET', '/products?category=shoes&limit=100');
  assert.ok(shoes.body.total > 0);
  assert.ok(shoes.body.items.every((p) => p.category === 'shoes'));

  const search = await call('GET', '/products?q=jordan');
  assert.ok(search.body.total > 0);
  assert.ok(search.body.items.every((p) => /jordan/i.test(p.name)));

  const cheap = await call('GET', '/products?sort=price_asc&limit=5');
  const prices = cheap.body.items.map((p) => p.price);
  assert.deepEqual(prices, [...prices].sort((a, b) => a - b));

  const ranged = await call('GET', '/products?minPrice=50&maxPrice=100&limit=100');
  assert.ok(ranged.body.items.every((p) => p.price >= 50 && p.price <= 100));

  const sale = await call('GET', '/products?onSale=true&limit=100');
  assert.ok(sale.body.items.every((p) => p.originalPrice > p.price));

  const page2 = await call('GET', '/products?limit=10&page=2');
  assert.equal(page2.body.page, 2);
  assert.equal(page2.body.items.length, 10);

  const wildcard = await call('GET', '/products?q=%25');
  assert.equal(wildcard.body.total, 0, 'LIKE wildcards are escaped');

  const byIds = await call('GET', '/products?ids=p1,p3,nope');
  assert.deepEqual(byIds.body.items.map((p) => p.id).sort(), ['p1', 'p3']);

  const bad = await call('GET', '/products?sort=nope');
  assert.equal(bad.status, 400);
});

test('product details, related and filters', async () => {
  const r = await call('GET', '/products/p7');
  assert.equal(r.status, 200);
  assert.equal(r.body.product.name, 'Court Air Sneakers');
  assert.ok(r.body.gallery.length >= 2);
  assert.ok(r.body.variant.sizes.includes('42'));
  assert.equal(r.body.reviews.length, 3);

  const rel = await call('GET', '/products/p7/related');
  assert.ok(rel.body.length > 0 && rel.body.every((p) => p.id !== 'p7'));

  const filters = await call('GET', '/products/filters');
  assert.ok(filters.body.brands.includes('Nike'));

  const missing = await call('GET', '/products/nope');
  assert.equal(missing.status, 404);
  assert.equal(missing.body.error.code, 'not_found');
});

test('register, login, profile', async () => {
  const { token, email } = await signUp();

  const dup = await call('POST', '/auth/register', {
    body: { name: 'Dup', email, password: 'secret12' },
  });
  assert.equal(dup.status, 409);

  const weak = await call('POST', '/auth/register', {
    body: { name: 'X', email: 'bad', password: '1' },
  });
  assert.equal(weak.status, 400);
  assert.ok(weak.body.error.details.length >= 2);

  const login = await call('POST', '/auth/login', { body: { email, password: 'secret12' } });
  assert.equal(login.status, 200);
  assert.ok(login.body.token);

  const wrong = await call('POST', '/auth/login', { body: { email, password: 'wrongpass' } });
  assert.equal(wrong.status, 401);

  const me = await call('GET', '/me', { token });
  assert.equal(me.body.user.email, email);
  assert.equal((await call('GET', '/me')).status, 401);
  assert.equal((await call('GET', '/me', { token: 'garbage' })).status, 401);

  const renamed = await call('PATCH', '/me', { token, body: { name: 'New Name' } });
  assert.equal(renamed.body.user.name, 'New Name');
});

test('password reset flow (forgot → verify → reset → login)', async () => {
  const { email } = await signUp();

  const forgot = await call('POST', '/auth/forgot-password', { body: { email } });
  assert.equal(forgot.status, 202);
  const code = forgot.body.devCode;
  assert.match(code, /^\d{4}$/);

  const wrongCode = await call('POST', '/auth/verify-otp', {
    body: { email, code: code === '0000' ? '1111' : '0000' },
  });
  assert.equal(wrongCode.status, 400);

  const verified = await call('POST', '/auth/verify-otp', { body: { email, code } });
  assert.equal(verified.status, 200);

  // A code works once.
  const again = await call('POST', '/auth/verify-otp', { body: { email, code } });
  assert.equal(again.status, 400);

  const reset = await call('POST', '/auth/reset-password', {
    body: { resetToken: verified.body.resetToken, newPassword: 'brandnew1' },
  });
  assert.equal(reset.status, 200);

  const old = await call('POST', '/auth/login', { body: { email, password: 'secret12' } });
  assert.equal(old.status, 401);
  const fresh = await call('POST', '/auth/login', { body: { email, password: 'brandnew1' } });
  assert.equal(fresh.status, 200);

  // A login token is not accepted as a reset token.
  const abuse = await call('POST', '/auth/reset-password', {
    body: { resetToken: fresh.body.token, newPassword: 'hacked123' },
  });
  assert.equal(abuse.status, 400);
});

test('forgot password does not reveal whether an email exists', async () => {
  const r = await call('POST', '/auth/forgot-password', {
    body: { email: 'nobody@nowhere.com' },
  });
  assert.equal(r.status, 202);
  assert.equal(r.body.devCode, undefined);
});

test('wishlist toggles and shows up as isFavorite', async () => {
  const { token } = await signUp();
  assert.equal((await call('GET', '/wishlist')).status, 401);

  assert.equal((await call('PUT', '/wishlist/p3', { token })).status, 204);
  assert.equal((await call('PUT', '/wishlist/p3', { token })).status, 204);
  assert.equal((await call('PUT', '/wishlist/nope', { token })).status, 404);

  const list = await call('GET', '/wishlist', { token });
  assert.deepEqual(list.body.map((p) => p.id), ['p3']);

  const details = await call('GET', '/products/p3', { token });
  assert.equal(details.body.product.isFavorite, true);
  const anon = await call('GET', '/products/p3');
  assert.equal(anon.body.product.isFavorite, false);

  assert.equal((await call('DELETE', '/wishlist/p3', { token })).status, 204);
  assert.equal((await call('GET', '/wishlist', { token })).body.length, 0);
});

test('reviews update the product aggregate', async () => {
  const { token } = await signUp();
  const before = (await call('GET', '/products/p1')).body.product;

  assert.equal((await call('POST', '/products/p1/reviews', { body: { rating: 5, comment: 'Great' } })).status, 401);
  const bad = await call('POST', '/products/p1/reviews', { token, body: { rating: 9, comment: 'Great' } });
  assert.equal(bad.status, 400);

  const ok = await call('POST', '/products/p1/reviews', { token, body: { rating: 5, comment: 'Really great' } });
  assert.equal(ok.status, 201);
  const after = (await call('GET', '/products/p1')).body.product;
  assert.equal(after.reviewCount, before.reviewCount + 1);
});

test('promo validation', async () => {
  const ok = await call('POST', '/promos/validate', { body: { code: 'save10' } });
  assert.equal(ok.status, 200);
  assert.equal(ok.body.discountPercent, 10);
  assert.equal((await call('POST', '/promos/validate', { body: { code: 'NOPE' } })).status, 400);
});

const address = { recipient: 'Test User', phone: '+10000000', line: '12 Main Street', city: 'Amman' };

test('checkout computes totals on the server', async () => {
  const { token } = await signUp();

  // p7: 119.00 (shoes need colour and size) x2 + p14: 9.50 = 247.50
  const order = await call('POST', '/orders', {
    token,
    body: {
      items: [
        { productId: 'p7', quantity: 2, color: 'Black', size: '42' },
        { productId: 'p14', quantity: 1 },
      ],
      promoCode: 'SAVE10',
      delivery: 'standard',
      address,
      payment: { kind: 'card', detail: 'Visa •••• 4242' },
    },
  });
  assert.equal(order.status, 201);
  assert.equal(order.body.subtotal, 247.5);
  assert.equal(order.body.discount, 24.75);
  assert.equal(order.body.shipping, 0); // free over 100
  assert.equal(order.body.total, 222.75);
  assert.equal(order.body.status, 'processing');
  assert.match(order.body.number, /^#VL-\d+$/);

  const small = await call('POST', '/orders', {
    token,
    body: {
      items: [{ productId: 'p14', quantity: 1 }],
      delivery: 'express',
      address,
      payment: { kind: 'cashOnDelivery' },
    },
  });
  assert.equal(small.body.shipping, 14.99);
  assert.equal(small.body.total, 24.49);

  const standard = await call('POST', '/orders', {
    token,
    body: {
      items: [{ productId: 'p14', quantity: 1 }],
      address,
      payment: { kind: 'paypal' },
    },
  });
  assert.equal(standard.body.shipping, 9.99);

  const list = await call('GET', '/orders', { token });
  assert.equal(list.body.length, 3);
  const one = await call('GET', `/orders/${order.body.id}`, { token });
  assert.equal(one.body.items.length, 2);

  // Order placement leaves a notification behind.
  const notes = await call('GET', '/notifications', { token });
  assert.ok(notes.body.items.some((n) => n.kind === 'order'));
  assert.ok(notes.body.unreadCount >= 1);
});

test('checkout rejects invalid input', async () => {
  const { token } = await signUp();
  const post = (body) => call('POST', '/orders', { token, body });
  const base = { address, payment: { kind: 'card' } };

  assert.equal((await post({ ...base, items: [] })).status, 400);
  assert.equal((await post({ ...base, items: [{ productId: 'nope', quantity: 1 }] })).status, 400);
  // Shoes without a size.
  assert.equal((await post({ ...base, items: [{ productId: 'p7', quantity: 1, color: 'Black' }] })).status, 400);
  assert.equal((await post({ ...base, items: [{ productId: 'p14', quantity: 0 }] })).status, 400);
  assert.equal((await post({ ...base, items: [{ productId: 'p14', quantity: 1 }], promoCode: 'FAKE' })).status, 400);
  assert.equal((await call('POST', '/orders', { body: {} })).status, 401);
});

test('orders are private to their owner and can be cancelled while processing', async () => {
  const a = await signUp();
  const b = await signUp();
  const placed = await call('POST', '/orders', {
    token: a.token,
    body: { items: [{ productId: 'p14', quantity: 1 }], address, payment: { kind: 'card' } },
  });

  assert.equal((await call('GET', `/orders/${placed.body.id}`, { token: b.token })).status, 404);
  assert.equal((await call('POST', `/orders/${placed.body.id}/cancel`, { token: b.token })).status, 404);

  const cancelled = await call('POST', `/orders/${placed.body.id}/cancel`, { token: a.token });
  assert.equal(cancelled.body.status, 'cancelled');
  assert.equal((await call('POST', `/orders/${placed.body.id}/cancel`, { token: a.token })).status, 409);
});

test('admin can advance an order and the customer is notified', async () => {
  const { token } = await signUp();
  const placed = await call('POST', '/orders', {
    token,
    body: { items: [{ productId: 'p14', quantity: 1 }], address, payment: { kind: 'card' } },
  });
  const id = placed.body.id;

  const noKey = await call('PATCH', `/admin/orders/${id}/status`, { body: { status: 'shipped' } });
  assert.equal(noKey.status, 403);

  const shipped = await call('PATCH', `/admin/orders/${id}/status`, {
    body: { status: 'shipped' },
    headers: { 'x-admin-key': 'test-admin-key' },
  });
  assert.equal(shipped.body.status, 'shipped');

  const notes = await call('GET', '/notifications', { token });
  assert.ok(notes.body.items.some((n) => n.title === 'Order shipped'));
  assert.equal((await call('POST', `/orders/${id}/cancel`, { token })).status, 409);
});

test('notifications can be marked read', async () => {
  const { token } = await signUp();
  const list = await call('GET', '/notifications', { token });
  assert.equal(list.body.unreadCount, 1); // welcome message

  const id = list.body.items[0].id;
  assert.equal((await call('PATCH', `/notifications/${id}/read`, { token })).status, 204);
  assert.equal((await call('GET', '/notifications', { token })).body.unreadCount, 0);
  assert.equal((await call('PATCH', '/notifications/nope/read', { token })).status, 404);
  assert.equal((await call('POST', '/notifications/read-all', { token })).status, 204);
});

test('unknown routes and bad JSON return the JSON error shape', async () => {
  const r = await call('GET', '/nope');
  assert.equal(r.status, 404);
  assert.equal(r.body.error.code, 'not_found');

  const res = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: '{bad json',
  });
  assert.equal(res.status, 400);
  assert.equal((await res.json()).error.code, 'bad_request');
});

test('concurrent sign-ups with one email: exactly one wins', async () => {
  const email = `race${Date.now()}@test.com`;
  const attempt = () =>
    call('POST', '/auth/register', { body: { name: 'Racer', email, password: 'secret12' } });
  const results = await Promise.all([attempt(), attempt(), attempt()]);
  assert.deepEqual(results.map((r) => r.status).sort(), [201, 409, 409]);
});

test('concurrent checkouts get distinct order numbers', async () => {
  const { token } = await signUp();
  const place = () =>
    call('POST', '/orders', {
      token,
      body: { items: [{ productId: 'p14', quantity: 1 }], address, payment: { kind: 'card' } },
    });
  const results = await Promise.all([place(), place(), place(), place()]);
  assert.ok(results.every((r) => r.status === 201));
  const numbers = new Set(results.map((r) => r.body.number));
  assert.equal(numbers.size, 4);
});

test('malformed ids are a 404, not a server error', async () => {
  const { token } = await signUp();
  assert.equal((await call('GET', '/orders/not-a-uuid', { token })).status, 404);
  assert.equal((await call('POST', '/orders/not-a-uuid/cancel', { token })).status, 404);
  assert.equal((await call('PATCH', '/notifications/123/read', { token })).status, 404);
});

test('schema migrations are recorded', async () => {
  const rows = await db.query('SELECT name FROM schema_migrations');
  assert.deepEqual(rows.map((r) => r.name), ['001_init.sql']);
});
