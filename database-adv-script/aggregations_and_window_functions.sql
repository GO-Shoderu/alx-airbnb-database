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


/* ----------------------------------------------------------
  Window Function: Ranking properties by total bookings
----------------------------------------------------------- */
SELECT
    p.property_id,
    p.name AS property_name,
    COUNT(b.booking_id) AS total_bookings,
    RANK() OVER (ORDER BY COUNT(b.booking_id) DESC) AS property_rank,
    ROW_NUMBER() OVER (ORDER BY COUNT(b.booking_id) DESC) AS property_row_number
FROM Property AS p
LEFT JOIN Booking AS b
    ON p.property_id = b.property_id
GROUP BY p.property_id, p.name
ORDER BY property_rank;