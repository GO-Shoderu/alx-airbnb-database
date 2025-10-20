-- ALX Airbnb Database — schema.sql (PostgreSQL)

CREATE EXTENSION IF NOT EXISTS citext;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ================
-- 1) USERS
-- ================
CREATE TABLE IF NOT EXISTS users (
  user_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name     TEXT        NOT NULL,
  last_name      TEXT        NOT NULL,
  email          CITEXT      NOT NULL UNIQUE, -- case-insensitive unique
  password_hash  TEXT        NOT NULL,
  phone_number   TEXT,
  role           TEXT        NOT NULL CHECK (role IN ('guest','host','admin')),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ================
-- 2) PROPERTIES
-- ================
CREATE TABLE IF NOT EXISTS properties (
  property_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id          UUID        NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
  name             TEXT        NOT NULL,
  description      TEXT        NOT NULL,
  location         TEXT        NOT NULL,
  price_per_night  NUMERIC(10,2) NOT NULL CHECK (price_per_night >= 0),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Keep updated_at fresh
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS properties_set_updated_at ON properties;
CREATE TRIGGER properties_set_updated_at
BEFORE UPDATE ON properties
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_properties_host ON properties(host_id);
CREATE INDEX IF NOT EXISTS idx_properties_price ON properties(price_per_night);

-- ================
-- 3) BOOKINGS
-- ================
CREATE TABLE IF NOT EXISTS bookings (
  booking_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id  UUID        NOT NULL REFERENCES properties(property_id) ON DELETE RESTRICT,
  user_id      UUID        NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
  start_date   DATE        NOT NULL,
  end_date     DATE        NOT NULL,
  total_price  NUMERIC(10,2) NOT NULL CHECK (total_price >= 0),
  status       TEXT        NOT NULL CHECK (status IN ('pending','confirmed','canceled')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (end_date > start_date)
);

-- Indexes for common lookups
CREATE INDEX IF NOT EXISTS idx_bookings_property_dates ON bookings(property_id, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_bookings_user ON bookings(user_id);

-- Optional: prevent overlapping bookings per property (requires btree_gist)
-- CREATE EXTENSION IF NOT EXISTS btree_gist;
-- ALTER TABLE bookings
--   ADD CONSTRAINT bookings_no_overlap
--   EXCLUDE USING gist (property_id WITH =, daterange(start_date, end_date, '[)') WITH &&);

-- ================
-- 4) PAYMENTS
-- ================
CREATE TABLE IF NOT EXISTS payments (
  payment_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id     UUID        NOT NULL REFERENCES bookings(booking_id) ON DELETE CASCADE,
  amount         NUMERIC(10,2) NOT NULL CHECK (amount > 0),
  payment_date   TIMESTAMPTZ NOT NULL DEFAULT now(),
  payment_method TEXT        NOT NULL CHECK (payment_method IN ('credit_card','paypal','stripe'))
);

CREATE INDEX IF NOT EXISTS idx_payments_booking ON payments(booking_id);

-- ================
-- 5) REVIEWS
-- ================
CREATE TABLE IF NOT EXISTS reviews (
  review_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id  UUID        NOT NULL REFERENCES properties(property_id) ON DELETE CASCADE,
  user_id      UUID        NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  rating       INT         NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment      TEXT        NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, property_id)
);

CREATE INDEX IF NOT EXISTS idx_reviews_property ON reviews(property_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON reviews(user_id);

-- ================
-- 6) MESSAGES
-- ================
CREATE TABLE IF NOT EXISTS messages (
  message_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id      UUID        NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  recipient_id   UUID        NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  message_body   TEXT        NOT NULL,
  sent_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (sender_id <> recipient_id)
);

CREATE INDEX IF NOT EXISTS idx_messages_sender_time    ON messages(sender_id, sent_at);
CREATE INDEX IF NOT EXISTS idx_messages_recipient_time ON messages(recipient_id, sent_at);
