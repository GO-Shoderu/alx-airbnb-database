/* ----------------------------------------------------------
  Non-Correlated Subquery: retrieving all properties 
  with average rating > 4.0
----------------------------------------------------------- */

SELECT 
    p.property_id,
    p.name AS property_name,
    p.location,
    p.pricepernight,
    p.host_id
FROM Property AS p
WHERE p.property_id IN (
    SELECT r.property_id
    FROM Review AS r
    GROUP BY r.property_id
    HAVING AVG(r.rating) > 4.0
)
ORDER BY p.name;

/* ----------------------------------------------------------
  Correlated Subquery: retrieving all users 
  who have made more than 3 bookings
----------------------------------------------------------- */

SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    u.role
FROM "User" AS u
WHERE (
    SELECT COUNT(*)
    FROM Booking AS b
    WHERE b.user_id = u.user_id
) > 3
ORDER BY u.first_name;
