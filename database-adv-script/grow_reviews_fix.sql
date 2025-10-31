-- Re-generate reviews with rating in 1..5 safely

-- Remove any previously inserted auto-generated reviews if needed (optional):
-- DELETE FROM reviews WHERE comment LIKE 'Auto-generated review %';

WITH review_rows AS (
  -- how many reviews to create (adjust if you want more/less)
  SELECT 15000::int AS n
),
gs AS (
  SELECT generate_series(1, (SELECT n FROM review_rows)) AS i
),
pick_prop AS (
  SELECT property_id FROM properties ORDER BY random() LIMIT (SELECT n FROM review_rows)
),
pick_user AS (
  SELECT user_id FROM users     ORDER BY random() LIMIT (SELECT n FROM review_rows)
),
pairs AS (
  SELECT row_number() OVER () AS rn, p.property_id, u.user_id
  FROM pick_prop p
  JOIN pick_user u ON TRUE
  LIMIT (SELECT n FROM review_rows)
)
INSERT INTO reviews (review_id, property_id, user_id, rating, comment, created_at)
SELECT _any_uuid(),
       pairs.property_id,
       pairs.user_id,
       -- ALWAYS 1..5:
       width_bucket(random(), 0, 1, 5),
       'Auto-generated review ' || pairs.rn,
       now() - ((random()*365)::int || ' days')::interval
FROM pairs;

VACUUM ANALYZE reviews;
