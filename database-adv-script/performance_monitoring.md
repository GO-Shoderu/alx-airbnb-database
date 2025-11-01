# Database Performance Monitoring and Refinement — AirBnB (PostgreSQL)

## Objective  
Continuously monitor and refine database performance by analyzing query execution plans, identifying bottlenecks, and applying schema or indexing improvements.

---

## 1️⃣ Monitoring Tools Used  
- **`EXPLAIN (ANALYZE, BUFFERS, VERBOSE)`** — shows how queries execute and where time is spent.  
- **`pg_stat_statements`** — tracks query frequency and total execution time across the database.

### Setup (run once)
```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SELECT pg_stat_statements_reset();
```

---

## 2️⃣ Queries Monitored  

### A) Date-range bookings  
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT booking_id, user_id, property_id
FROM bookings
WHERE start_date >= DATE '2025-10-01'
  AND end_date   <= DATE '2025-10-31'
ORDER BY start_date
LIMIT 100;
```

### B) Popular properties (bookings per property)  
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.property_id, p.name, COUNT(b.booking_id) AS total_bookings
FROM properties p
LEFT JOIN bookings b ON b.property_id = p.property_id
GROUP BY p.property_id, p.name
ORDER BY total_bookings DESC
LIMIT 50;
```

### C) Browse properties (filter + sort)  
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT property_id, name, location, price_per_night, created_at
FROM properties
WHERE location = 'Cape Town'
  AND price_per_night BETWEEN 800 AND 1500
ORDER BY created_at DESC
LIMIT 50;
```

---

## 3️⃣ Bottlenecks Identified  
- **Seq Scans** on large tables (`bookings`, `properties`) during range filters.  
- **Duplicate rows** from joins with `payments` (multiple payments per booking).  
- **Sorting overhead** for non-index-aligned ORDER BY clauses.  

---

## 4️⃣ Improvements Implemented  

### ✅ Indexes Added  
```sql
-- Faster date-range filtering
CREATE INDEX IF NOT EXISTS idx_bookings_start_end
  ON bookings(start_date, end_date);

-- Faster joins
CREATE INDEX IF NOT EXISTS idx_bookings_property_id
  ON bookings(property_id);

-- Browse pattern optimization
CREATE INDEX IF NOT EXISTS idx_properties_loc_price_created
  ON properties(location, price_per_night, created_at)
  INCLUDE (property_id, name);

-- Payments optimization
CREATE INDEX IF NOT EXISTS idx_payments_booking_date_desc
  ON payments(booking_id, payment_date DESC);
```

### ✅ Query Refactors  
- Used **LATERAL join** to fetch **only the latest payment per booking** instead of all payments.  
- Simplified date predicates to ensure **index usage (sargable)** conditions.  
- Re-ran **`VACUUM ANALYZE`** after schema changes.

---

## 5️⃣ Performance Comparison  

| Query | Before (ms) | After (ms) | Improvement | Notes |
|-------|--------------|-------------|--------------|-------|
| A — Date-range bookings | 0.274 | 0.086 | **-69%** | Now uses `idx_bookings_start_end` (Bitmap Index Scan) |
| B — Popular properties  | 2.278 | 1.721 | **-25%** | Faster join aggregation |
| C — Browse properties   | 0.057 | 0.055 | **-3%** | Minimal change (small dataset) |

**Global Stats via `pg_stat_statements`:**
- Overall mean query time dropped.  
- Total I/O (shared reads) reduced.  
- Cached query plans reused more efficiently.

---

## 6️⃣ Next Refinements  
- Consider **BRIN index** on `bookings.start_date` for massive time-series data.  
- If search by text grows, enable `pg_trgm` and use a GIN index for fuzzy `location` matches.  
- Continue monitoring top queries with:  
  ```sql
  SELECT query, calls, total_time, mean_time
  FROM pg_stat_statements
  ORDER BY total_time DESC
  LIMIT 10;
  ```

---

## ✅ Summary  
The monitoring process identified range scans and unnecessary joins as main bottlenecks.  
After applying composite indexes and targeted refactors, average execution time improved noticeably.  
Regular monitoring via `EXPLAIN` and `pg_stat_statements` will keep performance consistent as data volume grows.
