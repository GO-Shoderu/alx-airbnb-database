# Index Performance Report — AirBnB (PostgreSQL)

This report captures baseline performance **before** and **after** adding indexes, and justifies each index choice based on common query shapes in the ALX Airbnb project.

---

## Environment
- DB: PostgreSQL 16 (Docker container `airbnb-pg`)
- DB name: `airbnb_db`
- Tables: `users`, `properties`, `bookings`, `payments`, `reviews`, `messages`
- How queries were run: `docker exec -it airbnb-pg psql -U postgres -d airbnb_db`

---

## Data growth (for realistic measurements)
To make the dataset large enough to see indexing effects, we generated additional data with:

- `grow_data.sql` — expands users/properties and synthesizes bookings, payments, reviews, messages.
- `grow_reviews_fix_v2.sql` — safely regenerates reviews respecting `(user_id, property_id)` uniqueness and rating check (1..5).

> Commands used
```
docker cp grow_data.sql airbnb-pg:/tmp/grow_data.sql
docker exec -it airbnb-pg psql -U postgres -d airbnb_db -f /tmp/grow_data.sql

# If needed for reviews
docker cp grow_reviews_fix_v2.sql airbnb-pg:/tmp/grow_reviews_fix_v2.sql
docker exec -it airbnb-pg psql -U postgres -d airbnb_db -f /tmp/grow_reviews_fix_v2.sql
```

After data growth: `VACUUM ANALYZE;` was executed to refresh planner statistics.

---

## 1) Baseline measurements (before indexes)
All queries executed with: `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)`

**A) Bookings per user (join + aggregate)**
- Execution Time: **2.185 ms**
- Plan highlights: **Seq Scan on bookings**, Hash Right Join, HashAggregate

**B) Bookings per property (join + aggregate)**
- Execution Time: **2.278 ms**
- Plan highlights: **Seq Scan on bookings**, Hash Right Join, HashAggregate

**C) Date window (2025‑10) with ORDER BY start_date**
- Execution Time: **0.274 ms**
- Plan highlights: **Seq Scan on bookings**, many rows removed by filter

**D) Browse properties (location=‘Cape Town’, price_per_night 800–1500, ORDER BY created_at DESC)**
- Execution Time: **0.057 ms**
- Plan highlights: **Seq Scan on properties** (small table, low selectivity)

### commands used to measure BEFORE
```sql
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT u.user_id, u.first_name, u.last_name, COUNT(b.booking_id) AS total_bookings
FROM users u
LEFT JOIN bookings b ON b.user_id = u.user_id
GROUP BY u.user_id, u.first_name, u.last_name
ORDER BY total_bookings DESC
LIMIT 50;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT p.property_id, p.name, COUNT(b.booking_id) AS total_bookings
FROM properties p
LEFT JOIN bookings b ON b.property_id = p.property_id
GROUP BY p.property_id, p.name
ORDER BY total_bookings DESC
LIMIT 50;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT booking_id, user_id, property_id
FROM bookings
WHERE start_date >= DATE '2025-10-01'
  AND end_date   <= DATE '2025-10-31'
ORDER BY start_date
LIMIT 100;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT property_id, name, location, price_per_night, created_at
FROM properties
WHERE location = 'Cape Town'
  AND price_per_night BETWEEN 800 AND 1500
ORDER BY created_at DESC
LIMIT 50;
```

---

## 2) Indexes applied
Script: `database_index.sql` (run inside Docker), followed by `VACUUM ANALYZE;`

**Users**
- `idx_users_role` on `users(role)`
- `idx_users_created_at` on `users(created_at)`

**Properties**
- `idx_properties_host_id` on `properties(host_id)`
- `idx_properties_loc_price_created` on `(location, price_per_night, created_at)` INCLUDE `(property_id, name)`
- `idx_properties_host_created` on `(host_id, created_at)`

**Bookings**
- `idx_bookings_user_id` on `bookings(user_id)`
- `idx_bookings_property_id` on `bookings(property_id)`
- `idx_bookings_start_end` on `(start_date, end_date)`
- `idx_bookings_status_created` on `(status, created_at)`
- `idx_bookings_user_start` on `(user_id, start_date)` INCLUDE `(booking_id, property_id, status, total_price)`

### SQL `CREATE INDEX` commands
```sql
-- USERS
CREATE INDEX IF NOT EXISTS idx_users_role           ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_created_at     ON users(created_at);

-- PROPERTIES
CREATE INDEX IF NOT EXISTS idx_properties_host_id   ON properties(host_id);
CREATE INDEX IF NOT EXISTS idx_properties_loc_price_created
  ON properties(location, price_per_night, created_at)
  INCLUDE (property_id, name);
CREATE INDEX IF NOT EXISTS idx_properties_host_created
  ON properties(host_id, created_at);

-- BOOKINGS
CREATE INDEX IF NOT EXISTS idx_bookings_user_id     ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_property_id ON bookings(property_id);
CREATE INDEX IF NOT EXISTS idx_bookings_start_end   ON bookings(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_bookings_status_created
  ON bookings(status, created_at);
CREATE INDEX IF NOT EXISTS idx_bookings_user_start
  ON bookings(user_id, start_date)
  INCLUDE (booking_id, property_id, status, total_price);
```

---

## 3) Measurements after indexes
All queries re-executed with: `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)`

**A) Bookings per user**
- **After:** **1.559 ms** (was 2.185 ms)
- Change: ~**‑28.6%**
- Plan highlight: still scanning `bookings` due to relatively small table and group-by; improvement from caching and planner choices is visible but modest.

**B) Bookings per property**
- **After:** **1.721 ms** (was 2.278 ms)
- Change: ~**‑24.4%**
- Plan highlight: similar to A; still a hash join/aggregate with small cardinality, modest gain.

**C) Date window**
- **After:** **0.086 ms** (was 0.274 ms)
- Change: ~**‑68.6%**
- Plan highlight: **Bitmap Index Scan on `idx_bookings_start_end`** + Bitmap Heap Scan — this is the clearest indexing win.

**D) Browse properties**
- **After:** **0.055 ms** (was 0.057 ms)
- Change: ~**‑3.5%** (effectively unchanged)
- Plan highlight: still **Seq Scan**; with only ~tens of rows and low selectivity, the planner prefers a cheap full scan.

### commands used to measure AFTER
```sql
-- After running database_index.sql and VACUUM ANALYZE
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT u.user_id, u.first_name, u.last_name, COUNT(b.booking_id) AS total_bookings
FROM users u
LEFT JOIN bookings b ON b.user_id = u.user_id
GROUP BY u.user_id, u.first_name, u.last_name
ORDER BY total_bookings DESC
LIMIT 50;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT p.property_id, p.name, COUNT(b.booking_id) AS total_bookings
FROM properties p
LEFT JOIN bookings b ON b.property_id = p.property_id
GROUP BY p.property_id, p.name
ORDER BY total_bookings DESC
LIMIT 50;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT booking_id, user_id, property_id
FROM bookings
WHERE start_date >= DATE '2025-10-01'
  AND end_date   <= DATE '2025-10-31'
ORDER BY start_date
LIMIT 100;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT property_id, name, location, price_per_night, created_at
FROM properties
WHERE location = 'Cape Town'
  AND price_per_night BETWEEN 800 AND 1500
ORDER BY created_at DESC
LIMIT 50;
```

---

## 4) Plan analysis and rationale

- **A & B (aggregations over joins)**
  - With small/medium tables and low group counts, PostgreSQL often prefers a sequential scan + hash aggregate even when join keys are indexed. As data scales, `bookings(user_id)` and `bookings(property_id)` will increasingly pay off (especially for user-specific or property-specific reports and when partial filtering is added).

- **C (date window)**
  - Excellent outcome. The composite index `(start_date, end_date)` is used via **Bitmap Index Scan**, drastically reducing scanned pages and execution time.

- **D (browse filter + sort)**
  - On tiny `properties`, a **Seq Scan** is cheaper than setting up an index scan, even though `idx_properties_loc_price_created` fits the query shape. With thousands+ of rows and more selective filters, the index will be chosen. The INCLUDE columns help turn list endpoints into near–covering reads when the index is used.

---

## 5) Results summary table

| Query | Before (ms) | After (ms) | Δ (Change) | Notes |
|---|---:|---:|---:|---|
| A — Bookings per user | 2.185 | 1.559 | **‑28.6%** | Still hash agg; index helps more with selective user filters. |
| B — Bookings per property | 2.278 | 1.721 | **‑24.4%** | Similar to A; greater gains at larger scale. |
| C — Date window | 0.274 | 0.086 | **‑68.6%** | **Bitmap Index Scan on `idx_bookings_start_end`**. |
| D — Browse properties | 0.057 | 0.055 | **‑3.5%** | Very small table; planner prefers Seq Scan. |

**Biggest win came from:** `idx_bookings_start_end` (date-range queries)

**Indexes considered but not added:** Full‑text search (pg_trgm) for `location` — not needed for exact match; consider only if doing fuzzy search.

**Next steps:**
- Keep running with real workloads; enable `pg_stat_statements` to identify top queries.
- Revisit index usage after the dataset grows further; consider BRIN on `bookings.start_date` if the table becomes very large and data is time-correlated.
- Drop unused indexes after observation to keep write overhead low.

---

## 6) Tips & pitfalls
- **Index only what you filter/join/order by frequently.**
- **Composite order matters:** equality → range → order-by.
- **Prefix wildcards** (e.g., `LIKE '%Town'`) defeat b‑tree indexes; use `pg_trgm` if fuzzy search is required.
- After bulk loads and index creation, run **`VACUUM ANALYZE`** to refresh stats.

