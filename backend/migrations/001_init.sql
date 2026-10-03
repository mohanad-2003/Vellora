-- Vellora schema, PostgreSQL.

CREATE TABLE users (
  id            UUID PRIMARY KEY,
  name          TEXT NOT NULL,
  email         TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One pending password-reset code per email.
CREATE TABLE otp_codes (
  email      TEXT PRIMARY KEY,
  code_hash  TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  attempts   INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE categories (
  id    TEXT PRIMARY KEY,
  name  TEXT NOT NULL,
  image TEXT NOT NULL,
  sort  INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE banners (
  id       TEXT PRIMARY KEY,
  title    TEXT NOT NULL,
  subtitle TEXT NOT NULL,
  image    TEXT NOT NULL,
  sort     INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE products (
  id             TEXT PRIMARY KEY,
  name           TEXT NOT NULL,
  brand          TEXT NOT NULL,
  category_id    TEXT NOT NULL REFERENCES categories(id),
  price          DOUBLE PRECISION NOT NULL CHECK (price >= 0),
  original_price DOUBLE PRECISION,
  rating         DOUBLE PRECISION NOT NULL DEFAULT 0,
  review_count   INTEGER NOT NULL DEFAULT 0,
  image          TEXT NOT NULL,
  description    TEXT NOT NULL DEFAULT '',
  colors         JSONB NOT NULL DEFAULT '[]',
  sizes          JSONB NOT NULL DEFAULT '[]',
  in_stock       BOOLEAN NOT NULL DEFAULT TRUE,
  position       INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_products_category ON products(category_id);

CREATE TABLE product_images (
  product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  pos        INTEGER NOT NULL,
  image      TEXT NOT NULL,
  PRIMARY KEY (product_id, pos)
);

CREATE TABLE reviews (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES users(id) ON DELETE SET NULL,
  author     TEXT NOT NULL,
  rating     INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment    TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_reviews_product ON reviews(product_id, created_at DESC);

CREATE TABLE wishlist (
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, product_id)
);

CREATE TABLE promo_codes (
  code             TEXT PRIMARY KEY,
  discount_percent DOUBLE PRECISION NOT NULL,
  active           BOOLEAN NOT NULL DEFAULT TRUE
);

-- Human-readable order numbers (#VL-20001, ...). A sequence is safe under
-- concurrent checkouts, unlike COUNT(*) + 1.
CREATE SEQUENCE order_number_seq START 20001;

CREATE TABLE orders (
  id             UUID PRIMARY KEY,
  user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  number         TEXT NOT NULL UNIQUE,
  status         TEXT NOT NULL CHECK (status IN ('processing','shipped','delivered','cancelled')),
  subtotal       DOUBLE PRECISION NOT NULL,
  discount       DOUBLE PRECISION NOT NULL,
  shipping       DOUBLE PRECISION NOT NULL,
  total          DOUBLE PRECISION NOT NULL,
  promo_code     TEXT,
  delivery       TEXT NOT NULL,
  recipient      TEXT NOT NULL,
  phone          TEXT,
  address_line   TEXT NOT NULL,
  city           TEXT NOT NULL,
  payment_kind   TEXT NOT NULL,
  payment_detail TEXT NOT NULL DEFAULT '',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_orders_user ON orders(user_id, created_at DESC);

CREATE TABLE order_items (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id   UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  name       TEXT NOT NULL,
  image      TEXT NOT NULL,
  quantity   INTEGER NOT NULL CHECK (quantity > 0),
  price      DOUBLE PRECISION NOT NULL,
  color      TEXT,
  size       TEXT
);
CREATE INDEX idx_order_items_order ON order_items(order_id);

CREATE TABLE notifications (
  id         UUID PRIMARY KEY,
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind       TEXT NOT NULL,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  is_unread  BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);
