-- Re-generate reviews without violating (user_id, property_id) uniqueness
-- and keep rating strictly in 1..5

-- How many reviews do you want to try insert?
-- (The script will automatically skip duplicates via ON CONFLICT.)
WITH desired AS (
  SELECT 15000::int AS n
),
-- sample users and properties (you can adjust sizes if you want more variety)
u AS (
  SELECT user_id
  FROM users
  ORDER BY random()
  LIMIT (SELECT n FROM desired)
),
p AS (
  SELECT property_id
  FROM properties
  ORDER BY random()
  LIMIT (SELECT n FROM desired)
),
-- candidate pairs (remove duplicates at the source)
pairs AS (
  SELECT DISTINCT u.user_id, p.property_id
  FROM u CROSS JOIN p
  -- do NOT limit here; we want as many unique pairs as possible from the samples
),
-- exclude pairs that already have a review
new_pairs AS (
  SELECT pr.user_id, pr.property_id
  FROM pairs pr
  LEFT JOIN reviews r
    ON r.user_id = pr.user_id
   AND r.property_id = pr.property_id
  WHERE r.user_id IS NULL
)
INSERT INTO reviews (review_id, property_id, user_id, rating, comment, created_at)
SELECT
  _any_uuid(),
  np.property_id,
  np.user_id,
  -- guaranteed 1..5
  width_bucket(random(), 0, 1, 5),
  'Auto-generated review ' || row_number() OVER (),
  now() - ((random()*365)::int || ' days')::interval
FROM new_pairs np
-- final safety net: if two sessions race, don't error
ON CONFLICT (user_id, property_id) DO NOTHING;

-- Update stats for the planner
VACUUM ANALYZE reviews;
