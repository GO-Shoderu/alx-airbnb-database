-- ============================================================
-- grow_data.sql  (PostgreSQL) — FIXED
-- - VOLATILE UUID helper
-- - Uses properties.price_per_night (correct column)
-- ============================================================

-- Ensure extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Safe UUID helper (VOLATILE!)
CREATE OR REPLACE FUNCTION _any_uuid() RETURNS uuid AS $$
BEGIN
  IF to_regprocedure('gen_random_uuid()') IS NOT NULL THEN
    RETURN gen_random_uuid();
  ELSE
    RETURN uuid_generate_v4();
  END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- =============== SCALE ==========================
-- Adjust these to make bigger/smaller datasets
DO $$
DECLARE
  user_dups     int := 10;     -- duplicate each existing user this many times
  prop_dups     int := 10;     -- duplicate each existing property this many times
  booking_rows  int := 20000;  -- number of new bookings to synthesize
  review_rows   int := 15000;  -- number of new reviews to synthesize
  payment_rows  int := 12000;  -- number of new payments to synthesize
  message_rows  int := 8000;   -- number of new messages to synthesize
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'pg_temp' AND tablename = 'scale_cfg') THEN
    CREATE TEMP TABLE scale_cfg(
      user_dups int, prop_dups int, booking_rows int, review_rows int, payment_rows int, message_rows int
    ) ON COMMIT PRESERVE ROWS;
  END IF;
  DELETE FROM scale_cfg;
  INSERT INTO scale_cfg VALUES (user_dups, prop_dups, booking_rows, review_rows, payment_rows, message_rows);
END$$;

-- ================= USERS ========================
WITH base AS (
  SELECT u.*,
         split_part(u.email,'@',1) AS local,
         split_part(u.email,'@',2) AS domain
  FROM users u
),
gs AS (
  SELECT generate_series(1, (SELECT user_dups FROM scale_cfg)) AS i
)
INSERT INTO users (user_id, first_name, last_name, email, password_hash, phone_number, role, created_at)
SELECT _any_uuid(),
       b.first_name, b.last_name,
       b.local || '+' || gs.i || '@' || b.domain,
       b.password_hash, b.phone_number, b.role,
       b.created_at + (gs.i || ' days')::interval
FROM base b
CROSS JOIN gs;

-- ================= PROPERTIES ===================
WITH gs AS (
  SELECT generate_series(1, (SELECT prop_dups FROM scale_cfg)) AS i
),
props AS (
  SELECT p.*
  FROM properties p
)
INSERT INTO properties (property_id, host_id, name, description, location, price_per_night, created_at, updated_at)
SELECT _any_uuid(),
       (SELECT user_id FROM users WHERE role='host' ORDER BY random() LIMIT 1),
       p.name || ' #' || gs.i,
       p.description,
       p.location,
       p.price_per_night,
       p.created_at + (gs.i || ' days')::interval,
       now()
FROM props p
CROSS JOIN gs;

-- ================= BOOKINGS =====================
WITH cfg AS (SELECT booking_rows FROM scale_cfg),
gs AS (
  SELECT generate_series(1, (SELECT booking_rows FROM cfg)) AS i
),
pick_prop AS (
  SELECT property_id, price_per_night FROM properties ORDER BY random() LIMIT (SELECT booking_rows FROM cfg)
),
pick_guest AS (
  SELECT user_id FROM users WHERE role='guest' ORDER BY random() LIMIT (SELECT booking_rows FROM cfg)
),
pairs AS (
  SELECT row_number() OVER () AS rn, pp.property_id, pp.price_per_night, ug.user_id
  FROM pick_prop pp
  JOIN pick_guest ug ON TRUE
  LIMIT (SELECT booking_rows FROM cfg)
),
dates AS (
  SELECT rn,
         (DATE '2024-01-01' + ((random()*600)::int))::date AS start_d,
         (1 + (random()*6)::int) AS nights
  FROM generate_series(1, (SELECT booking_rows FROM cfg)) rn
)
INSERT INTO bookings (booking_id, property_id, user_id, start_date, end_date, total_price, status, created_at)
SELECT _any_uuid(),
       pr.property_id,
       pr.user_id,
       d.start_d,
       (d.start_d + (prc.nights || ' days')::interval)::date,
       (prc.nights * pr.price_per_night)::numeric(10,2),
       (ARRAY['pending','confirmed','canceled'])[1 + floor(random()*3)]::text,
       now()
FROM (
  SELECT pairs.property_id, pairs.price_per_night, pairs.user_id, pairs.rn
  FROM pairs
) pr
JOIN (
  SELECT rn, nights FROM dates
) prc ON prc.rn = pr.rn
JOIN dates d ON d.rn = pr.rn;

-- ================= PAYMENTS =====================
WITH cfg AS (SELECT payment_rows FROM scale_cfg),
pick AS (
  SELECT booking_id, total_price
  FROM bookings
  ORDER BY random()
  LIMIT (SELECT payment_rows FROM cfg)
)
INSERT INTO payments (payment_id, booking_id, amount, payment_date, payment_method)
SELECT _any_uuid(), booking_id, total_price,
       now() - ((random()*90)::int || ' days')::interval,
       (ARRAY['credit_card','paypal','stripe'])[1 + floor(random()*3)]::text
FROM pick;

-- ================= REVIEWS ======================
WITH cfg AS (SELECT review_rows FROM scale_cfg),
gs2 AS (
  SELECT generate_series(1, (SELECT review_rows FROM cfg)) AS i
),
pick_prop2 AS (
  SELECT property_id FROM properties ORDER BY random() LIMIT (SELECT review_rows FROM cfg)
),
pick_user2 AS (
  SELECT user_id FROM users ORDER BY random() LIMIT (SELECT review_rows FROM cfg)
),
pairs2 AS (
  SELECT row_number() OVER () AS rn, p.property_id, u.user_id
  FROM pick_prop2 p JOIN pick_user2 u ON TRUE
  LIMIT (SELECT review_rows FROM cfg)
)
INSERT INTO reviews (review_id, property_id, user_id, rating, comment, created_at)
SELECT _any_uuid(),
       pairs2.property_id,
       pairs2.user_id,
       1 + (random()*5)::int,
       'Auto-generated review ' || pairs2.rn,
       now() - ((random()*365)::int || ' days')::interval
FROM pairs2;

-- ================= MESSAGES =====================
WITH cfg AS (SELECT message_rows FROM scale_cfg),
senders AS (
  SELECT user_id FROM users ORDER BY random() LIMIT (SELECT message_rows FROM cfg)
),
recipients AS (
  SELECT user_id FROM users ORDER BY random() LIMIT (SELECT message_rows FROM cfg)
),
paired AS (
  SELECT row_number() OVER () AS rn,
         s.user_id AS sender_id,
         r.user_id AS recipient_id
  FROM senders s
  JOIN recipients r ON s.user_id <> r.user_id
  LIMIT (SELECT message_rows FROM cfg)
)
INSERT INTO messages (message_id, sender_id, recipient_id, message_body, sent_at)
SELECT _any_uuid(), sender_id, recipient_id,
       'Auto-generated message #' || rn,
       now() - ((random()*60)::int || ' days')::interval
FROM paired;

VACUUM ANALYZE;
