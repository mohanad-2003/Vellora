# Vellora API

REST backend for the Vellora Flutter app. **Node.js + Express 5**, **PostgreSQL**, JWT
authentication, input validation with `zod`.

Requires **Node 22+** (developed on Node 24).

## Run it

```bash
cd backend
npm install
npm start            # http://localhost:3000  (creates the schema and seeds the catalogue)
```

With no configuration it uses an **embedded PostgreSQL** (PGlite: a real Postgres compiled
to WebAssembly) that stores its files in `data/pgdata/`. Nothing to install, and it is
the same SQL dialect as production. It is meant for development: single process, and not
for production traffic.

### Use a real PostgreSQL server

```bash
docker compose up -d        # local Postgres 16 (see docker-compose.yml), or any server
DATABASE_URL=postgres://vellora:vellora@localhost:5432/vellora npm start
```

Hosted databases (Neon, Supabase, Render, Railway, RDS…) work the same way: pass their
connection string, with `?sslmode=require` if they ask for TLS. **`DATABASE_URL` and
`JWT_SECRET` are required when `NODE_ENV=production`.** The schema is created by the
SQL files in `migrations/`, applied once each at startup and recorded in
`schema_migrations`. To change the schema, add `002_something.sql`; never edit an
applied file.

| Script | Does |
|--------|------|
| `npm start` | Start the API |
| `npm run dev` | Start with auto-reload |
| `npm run seed` | Wipe and re-seed the **embedded** dev database |
| `npm test` | API tests on an in-memory embedded Postgres (no setup) |
| `npm run test:pg` | The same tests against a real server: `TEST_DATABASE_URL=… npm run test:pg` (**wipes that database**) |

Copy [`.env.example`](.env.example) to `.env` to change the port, database, CORS origin
or JWT settings. `JWT_SECRET` **must** be set to a long random value in production.

### From the Flutter app

- Android emulator → `http://10.0.2.2:3000`
- iOS simulator / desktop / web → `http://localhost:3000`
- Real phone → your computer's LAN IP (e.g. `http://192.168.1.20:3000`)

Product, category and banner images are served by the API itself under
`/static/images/...`, and every response already contains absolute `imageUrl`s.

## Deploy on Render

The repository root has a [`render.yaml`](../render.yaml) Blueprint that creates the API
(a Node web service) and its PostgreSQL database together.

1. Push the repository to GitHub.
2. Render dashboard → **New → Blueprint** → select the repository → **Apply**.
3. Wait for the first deploy. The service creates the schema and seeds the catalogue on
   its first start. Check `https://<your-service>.onrender.com/health` → `{"status":"ok"}`.
4. Build the app against it:
   ```bash
   flutter build apk --dart-define=API_BASE_URL=https://<your-service>.onrender.com
   ```

What the Blueprint sets: `NODE_ENV=production`, a generated `JWT_SECRET`, and
`DATABASE_URL` wired to the database (Render's internal connection string, so no SSL
setting is needed; set `DATABASE_SSL=true` if you use the database's external URL).
Uncomment `ADMIN_API_KEY` in the file to enable the order-status admin route.

**Free plan limits** (check Render's pricing page, they change):
- A free web service goes to sleep after a period without traffic, and the first request
  then takes tens of seconds. The app's 20-second request timeout will fail on that first
  call; a paid instance does not sleep.
- A free PostgreSQL database is temporary and expires, so it is only suitable for demos.
  Use a paid database for anything with real users.
- Product images are served by the API itself, so they are covered by the same limits.

## Conventions

- JSON in, JSON out. Protected routes need `Authorization: Bearer <token>`.
- Errors always look like:
  ```json
  { "error": { "code": "bad_request", "message": "Validation failed",
               "details": [{ "field": "email", "message": "Invalid email" }] } }
  ```
- Prices are numbers in USD. Order totals are always recalculated on the server from
  database prices; the client never sends a price.

## Endpoints

### Auth & profile
| Method | Path | Auth | Notes |
|--------|------|:----:|-------|
| POST | `/auth/register` | | `{name, email, password}` → `{user, token}` (409 if the email exists) |
| POST | `/auth/login` | | `{email, password}` → `{user, token}` |
| POST | `/auth/forgot-password` | | `{email}` → 202. Same response whether or not the account exists |
| POST | `/auth/verify-otp` | | `{email, code}` (4 digits) → `{resetToken}` |
| POST | `/auth/reset-password` | | `{resetToken, newPassword}` |
| GET / PATCH | `/me` | ✔ | Profile; PATCH `{name}` |
| POST | `/me/change-password` | ✔ | `{currentPassword, newPassword}` |

The reset code is valid for 10 minutes, works once, and is locked after 5 wrong attempts.
**No email provider is connected yet**: outside production the code is printed in the
server log and returned as `devCode`, so the flow is testable end to end.

### Catalogue
| Method | Path | Notes |
|--------|------|-------|
| GET | `/home` | `banners, categories, featured, flashSale, newArrivals, bestSellers, recommended` |
| GET | `/categories` | With product counts |
| GET | `/products` | Query: `category`, `q`, `brand` (comma list), `minPrice`, `maxPrice`, `minRating`, `onSale`, `sort` (`relevance, newest, price_asc, price_desc, rating, popular, discount`), `page`, `limit` (max 100) → `{items, page, limit, total, totalPages}` |
| GET | `/products/filters` | Brands and price range for the filter sheet |
| GET | `/products/:id` | `{product, gallery, description, variant:{colors,sizes}, reviews}` |
| GET | `/products/:id/related` | Same-category products |
| GET / POST | `/products/:id/reviews` | POST needs auth: `{rating 1-5, comment}`; updates the product rating |

Send a token to any product route and each product carries the right `isFavorite`.

### Wishlist, notifications, promos
| Method | Path | Auth | Notes |
|--------|------|:----:|-------|
| GET | `/wishlist` | ✔ | |
| PUT / DELETE | `/wishlist/:productId` | ✔ | Idempotent, 204 |
| GET | `/notifications` | ✔ | `{items, unreadCount}` |
| PATCH | `/notifications/:id/read` | ✔ | |
| POST | `/notifications/read-all` | ✔ | |
| DELETE | `/notifications/:id` | ✔ | |
| POST | `/promos/validate` | | `{code}` → `{code, discountPercent}`. Seeded: `SAVE10`, `WELCOME20` |

### Orders
| Method | Path | Auth | Notes |
|--------|------|:----:|-------|
| POST | `/orders` | ✔ | See below → 201 with the full order |
| GET | `/orders` | ✔ | Your orders, newest first |
| GET | `/orders/:id` | ✔ | 404 for other people's orders |
| POST | `/orders/:id/cancel` | ✔ | Only while `processing` |
| PATCH | `/admin/orders/:id/status` | key | Header `x-admin-key`. Disabled unless `ADMIN_API_KEY` is set. Notifies the customer |

```jsonc
// POST /orders
{
  "items": [{ "productId": "p7", "quantity": 2, "color": "Black", "size": "42" }],
  "promoCode": "SAVE10",                 // optional
  "delivery": "standard",                // or "express"
  "address": { "recipient": "Sam", "phone": "+962…", "line": "12 Main St", "city": "Amman" },
  "payment": { "kind": "card", "detail": "Visa •••• 4242" }   // card | paypal | cashOnDelivery
}
```

Colour and size are required for products that have them (apparel, shoes, accessories).
Shipping is free for a subtotal of 100 or more, otherwise 9.99; express is a flat 19.99.
Statuses: `processing → shipped → delivered`, or `cancelled`.

## Layout

```
backend/
├── migrations/             # numbered SQL schema files
├── data/products.json      # catalogue seed (the app's former mock data)
├── public/images/          # product and banner photos, served at /static/images
├── src/
│   ├── app.js  server.js   # Express setup / process entry
│   ├── config.js  db.js  seed.js   # db.js: one interface over pg / PGlite, + migrator
│   ├── middleware/         # auth, error handling
│   └── routes/             # auth, catalog, account (wishlist/notifications/promos), orders
└── test/api.test.js        # end-to-end tests (real HTTP, real Postgres engine)
```

## Not built yet

- Real email delivery for the reset code.
- Payment processing (`payment` is recorded, not charged).
- Server-side cart (the app keeps the cart on the device and sends it at checkout).
- Admin dashboard and stock management.
- Translations: product text is English only.
- Registration of a device for push notifications.
