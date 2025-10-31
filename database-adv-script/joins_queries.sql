/* ----------------------------------------------------------
  INNER JOIN: retrieving all bookings and the respective users
----------------------------------------------------------- */
SELECT
  b.booking_id,
  b.property_id,
  b.user_id,
  b.start_date,
  b.end_date,
  b.total_price,
  b.status,
  b.created_at AS booking_created_at,
  u.first_name,
  u.last_name,
  u.email,
  u.role
FROM Booking AS b
INNER JOIN "User" AS u
  ON u.user_id = b.user_id
ORDER BY b.created_at DESC;