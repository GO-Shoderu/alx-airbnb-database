# Partitioning Performance — Bookings (PostgreSQL)

## What I did
- Implemented **range partitioning by `start_date`**:
  - Parent: `bookings` (partitioned)
  - Partitions: `bookings_2024`, `bookings_2025`, `bookings_2026`, plus MINVALUE/MAXVALUE catch-alls.
- Created indexes on the **parent** so each partition has:
  - `(start_date, end_date)`, `(user_id)`, `(property_id)`.
- Bulk-copied data from the original table and **swapped** names (`bookings_old` kept as backup).

## How I measured
Before and after, I ran:
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT booking_id, user_id, property_id
FROM bookings
WHERE start_date >= DATE '2025-10-01'
  AND end_date   <= DATE '2025-10-31';
