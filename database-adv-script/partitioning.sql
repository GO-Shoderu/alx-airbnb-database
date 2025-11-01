-- Partition Bookings by start_date

BEGIN;

-- Fresh stats
VACUUM ANALYZE;

-- Create a partitioned replacement table with same structure
CREATE TABLE IF NOT EXISTS bookings_part (LIKE bookings INCLUDING ALL)
PARTITION BY RANGE (start_date);

-- Yearly partitions (add more years as needed)
CREATE TABLE IF NOT EXISTS bookings_2024 PARTITION OF bookings_part
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE IF NOT EXISTS bookings_2025 PARTITION OF bookings_part
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE IF NOT EXISTS bookings_2026 PARTITION OF bookings_part
FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

-- Catch-all older/newer
CREATE TABLE IF NOT EXISTS bookings_before_2024 PARTITION OF bookings_part
FOR VALUES FROM (MINVALUE) TO ('2024-01-01');

CREATE TABLE IF NOT EXISTS bookings_after_2026 PARTITION OF bookings_part
FOR VALUES FROM ('2027-01-01') TO (MAXVALUE);

-- Helpful partitioned indexes (created on parent; auto-propagates)
CREATE INDEX IF NOT EXISTS idx_bookings_part_start_end
  ON bookings_part(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_bookings_part_user
  ON bookings_part(user_id);

CREATE INDEX IF NOT EXISTS idx_bookings_part_property
  ON bookings_part(property_id);

-- Move data into the new partitioned table
INSERT INTO bookings_part SELECT * FROM bookings;

-- Swap tables (keep old as backup)
ALTER TABLE bookings RENAME TO bookings_old;
ALTER TABLE bookings_part RENAME TO bookings;

-- Refresh stats
VACUUM ANALYZE;

COMMIT;

-- Quick check: partition pruning should happen here
EXPLAIN (ANALYZE, BUFFERS)
SELECT booking_id, user_id, property_id
FROM bookings
WHERE start_date >= DATE '2025-10-01'
  AND end_date   <= DATE '2025-10-31';
