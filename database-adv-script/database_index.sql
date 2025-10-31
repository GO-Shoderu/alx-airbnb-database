/* ==========================================================
   Database Indexes for Optimization (AirBnB, PostgreSQL)
   Targets: users, properties, bookings
   Notes:
   - Primary keys are already indexed.
   - users.email is UNIQUE (already indexed by constraint).
   - Creating indexes that match your common WHERE/JOIN/ORDER BY patterns.
   ========================================================== */

-- =====================
-- USERS
-- =====================

-- Fast filters by role (e.g., dashboards, admin views)
CREATE INDEX IF NOT EXISTS idx_users_role
  ON users(role);

-- Sort or filter by creation time (recent users lists)
CREATE INDEX IF NOT EXISTS idx_users_created_at
  ON users(created_at);

-- This is ptional: name sort/search
-- CREATE INDEX IF NOT EXISTS idx_users_last_first
--   ON users(last_name, first_name);


-- =====================
-- PROPERTIES
-- =====================

-- Host → properties lookups and joins
CREATE INDEX IF NOT EXISTS idx_properties_host_id
  ON properties(host_id);

-- Common browse pattern: filter by location + price range, order by recency
-- Order columns by equality → range → order-by
CREATE INDEX IF NOT EXISTS idx_properties_loc_price_created
  ON properties(location, price_per_night, created_at)
  INCLUDE (property_id, name);

-- Host’s newest properties (host dashboards & pagination)
CREATE INDEX IF NOT EXISTS idx_properties_host_created
  ON properties(host_id, created_at);


-- =====================
-- BOOKINGS
-- =====================

-- Join/filter by user (user’s bookings)
CREATE INDEX IF NOT EXISTS idx_bookings_user_id
  ON bookings(user_id);

-- Join/filter by property (property’s bookings)
CREATE INDEX IF NOT EXISTS idx_bookings_property_id
  ON bookings(property_id);

-- Date window queries (availability, month reports)
CREATE INDEX IF NOT EXISTS idx_bookings_start_end
  ON bookings(start_date, end_date);

-- Operational status filters (e.g., pending/confirmed/canceled) + recent activity
CREATE INDEX IF NOT EXISTS idx_bookings_status_created
  ON bookings(status, created_at);

-- User’s bookings by start date (fast pagination)
CREATE INDEX IF NOT EXISTS idx_bookings_user_start
  ON bookings(user_id, start_date)
  INCLUDE (booking_id, property_id, status, total_price);


-- =====================
-- This is for later
-- =====================

-- Reviews joins (property/user)
-- CREATE INDEX IF NOT EXISTS idx_reviews_property_id ON reviews(property_id);
-- CREATE INDEX IF NOT EXISTS idx_reviews_user_id     ON reviews(user_id);

-- Payments join – aggregate by booking or time 
-- CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON payments(booking_id);
-- CREATE INDEX IF NOT EXISTS idx_payments_date       ON payments(payment_date);


-- =====================
-- This is for later (Maintenance related)
-- =====================

-- Refresh planner statistics after creating many indexes
-- VACUUM ANALYZE;

-- Drop examples (if an index is unused or redundant)
-- DROP INDEX IF EXISTS idx_properties_loc_price_created;
-- DROP INDEX IF EXISTS idx_bookings_user_start;
