
/* ==========================================================
   Optimizing Complex Queries (AirBnB, PostgreSQL)
   File: perfomance.sql

   How to run (Docker):
     docker cp perfomance.sql airbnb-pg:/tmp/perfomance.sql
     docker exec -it airbnb-pg psql -U postgres -d airbnb_db -f /tmp/perfomance.sql
   ========================================================== */

-- Make sure planner statistics are fresh for consistent measurements
VACUUM ANALYZE;
\timing on;

/* ==========================================================
 1) BASELINE (initial) query
    - Retrieves all bookings + user details + property details + payment rows
    - If a booking has multiple payments, this will create duplicate
      booking rows (cartesian magnification). 
      
      We refactoring it away in the optimized version.
========================================================== */

-- (A) Initial query (broad SELECT)
SELECT
  b.booking_id,
  b.user_id,
  b.property_id,
  b.start_date,
  b.end_date,
  b.total_price,
  b.status,
  b.created_at AS booking_created_at,
  u.first_name,
  u.last_name,
  u.email,
  p.name         AS property_name,
  p.location     AS property_location,
  p.price_per_night,
  pay.payment_id,
  pay.amount     AS payment_amount,
  pay.payment_date,
  pay.payment_method
FROM bookings   AS b
JOIN users      AS u   ON u.user_id      = b.user_id
JOIN properties AS p   ON p.property_id  = b.property_id
LEFT JOIN payments AS pay ON pay.booking_id = b.booking_id
ORDER BY b.created_at DESC;

-- (B) Measure baseline
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
  b.booking_id,
  b.user_id,
  b.property_id,
  b.start_date,
  b.end_date,
  b.total_price,
  b.status,
  b.created_at AS booking_created_at,
  u.first_name,
  u.last_name,
  u.email,
  p.name         AS property_name,
  p.location     AS property_location,
  p.price_per_night,
  pay.payment_id,
  pay.amount     AS payment_amount,
  pay.payment_date,
  pay.payment_method
FROM bookings   AS b
JOIN users      AS u   ON u.user_id      = b.user_id
JOIN properties AS p   ON p.property_id  = b.property_id
LEFT JOIN payments AS pay ON pay.booking_id = b.booking_id
ORDER BY b.created_at DESC;

/* ==========================================================
 2) Helpful indexes used in the refactors below
    (Run once; IF NOT EXISTS prevents duplicates)
========================================================== */

-- Speeds join to payments and ordering by latest payment
CREATE INDEX IF NOT EXISTS idx_payments_booking_id       ON payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_booking_date_desc ON payments(booking_id, payment_date DESC);

-- Joins already covered by earlier tasks, but included here for clarity
CREATE INDEX IF NOT EXISTS idx_bookings_user_id    ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_property_id ON bookings(property_id);

/* ==========================================================
 3) REFACTOR #1 — LATERAL subquery to pick the latest payment per booking
    Why this helps:
      - Eliminates booking row duplication caused by multiple payments
      - Reads at most 1 payment row per booking (ORDER BY payment_date DESC LIMIT 1)
      - Uses the composite index (booking_id, payment_date DESC)
========================================================== */

SELECT
  b.booking_id,
  b.user_id,
  b.property_id,
  b.start_date,
  b.end_date,
  b.total_price,
  b.status,
  b.created_at   AS booking_created_at,
  u.first_name,
  u.last_name,
  u.email,
  p.name         AS property_name,
  p.location     AS property_location,
  p.price_per_night,
  pay_latest.payment_id,
  pay_latest.amount      AS payment_amount,
  pay_latest.payment_date,
  pay_latest.payment_method
FROM bookings   AS b
JOIN users      AS u   ON u.user_id      = b.user_id
JOIN properties AS p   ON p.property_id  = b.property_id
LEFT JOIN LATERAL (
  SELECT payment_id, amount, payment_date, payment_method
  FROM payments pay
  WHERE pay.booking_id = b.booking_id
  ORDER BY payment_date DESC
  LIMIT 1
) AS pay_latest ON TRUE
ORDER BY b.created_at DESC;

-- Measure refactor #1
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
  b.booking_id,
  b.user_id,
  b.property_id,
  b.start_date,
  b.end_date,
  b.total_price,
  b.status,
  b.created_at   AS booking_created_at,
  u.first_name,
  u.last_name,
  u.email,
  p.name         AS property_name,
  p.location     AS property_location,
  p.price_per_night,
  pay_latest.payment_id,
  pay_latest.amount      AS payment_amount,
  pay_latest.payment_date,
  pay_latest.payment_method
FROM bookings   AS b
JOIN users      AS u   ON u.user_id      = b.user_id
JOIN properties AS p   ON p.property_id  = b.property_id
LEFT JOIN LATERAL (
  SELECT payment_id, amount, payment_date, payment_method
  FROM payments pay
  WHERE pay.booking_id = b.booking_id
  ORDER BY payment_date DESC
  LIMIT 1
) AS pay_latest ON TRUE
ORDER BY b.created_at DESC;

/* ==========================================================
 4) REFACTOR #2 — Window function (alternative approach)
    Why this helps:
      - Pre-compute latest payment per booking once, then join a deduplicated
        set using rn = 1; useful if you need to reuse the latest-payment set
        across multiple queries in a session.
========================================================== */

WITH latest_payment AS (
  SELECT
    payment_id,
    booking_id,
    amount,
    payment_date,
    payment_method,
    ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY payment_date DESC) AS rn
  FROM payments
)
SELECT
  b.booking_id,
  b.user_id,
  b.property_id,
  b.start_date,
  b.end_date,
  b.total_price,
  b.status,
  b.created_at   AS booking_created_at,
  u.first_name,
  u.last_name,
  u.email,
  p.name         AS property_name,
  p.location     AS property_location,
  p.price_per_night,
  lp.payment_id,
  lp.amount      AS payment_amount,
  lp.payment_date,
  lp.payment_method
FROM bookings   AS b
JOIN users      AS u   ON u.user_id      = b.user_id
JOIN properties AS p   ON p.property_id  = b.property_id
LEFT JOIN latest_payment AS lp
  ON lp.booking_id = b.booking_id AND lp.rn = 1
ORDER BY b.created_at DESC;

-- Measure refactor #2
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
WITH latest_payment AS (
  SELECT
    payment_id,
    booking_id,
    amount,
    payment_date,
    payment_method,
    ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY payment_date DESC) AS rn
  FROM payments
)
SELECT
  b.booking_id,
  b.user_id,
  b.property_id,
  b.start_date,
  b.end_date,
  b.total_price,
  b.status,
  b.created_at   AS booking_created_at,
  u.first_name,
  u.last_name,
  u.email,
  p.name         AS property_name,
  p.location     AS property_location,
  p.price_per_night,
  lp.payment_id,
  lp.amount      AS payment_amount,
  lp.payment_date,
  lp.payment_method
FROM bookings   AS b
JOIN users      AS u   ON u.user_id      = b.user_id
JOIN properties AS p   ON p.property_id  = b.property_id
LEFT JOIN latest_payment AS lp
  ON lp.booking_id = b.booking_id AND lp.rn = 1
ORDER BY b.created_at DESC;
