/* ----------------------------------------------------------
  Aggregation: Total number of bookings per user
----------------------------------------------------------- */
SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    COUNT(b.booking_id) AS total_bookings
FROM "User" AS u
LEFT JOIN Booking AS b
    ON u.user_id = b.user_id
GROUP BY u.user_id, u.first_name, u.last_name
ORDER BY total_bookings DESC;
