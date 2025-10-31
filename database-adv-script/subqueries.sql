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
