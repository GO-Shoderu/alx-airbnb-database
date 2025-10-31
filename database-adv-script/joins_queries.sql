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

/* ----------------------------------------------------------
  LEFT JOIN: retrieving all properties and their reviews,
     including properties that have no reviews
----------------------------------------------------------- */
SELECT
  p.property_id,
  p.host_id,
  p.name AS property_name,
  p.location,
  p.pricepernight,
  p.created_at AS property_created_at,
  r.review_id,
  r.user_id AS reviewer_id,
  r.rating,
  r.comment,
  r.created_at AS review_created_at
FROM Property AS p
LEFT JOIN Review AS r
  ON r.property_id = p.property_id
ORDER BY p.created_at DESC, r.created_at DESC NULLS LAST;

/* ----------------------------------------------------------
  FULL OUTER JOIN: retrieving all users and all bookings,
     even if the user has no booking OR a booking is not
     linked to a user (orphan booking)
----------------------------------------------------------- */
SELECT
  u.user_id,
  u.first_name,
  u.last_name,
  u.email,
  u.role,
  b.booking_id,
  b.property_id,
  b.start_date,
  b.end_date,
  b.total_price,
  b.status,
  b.created_at AS booking_created_at
FROM "User" AS u
FULL OUTER JOIN Booking AS b
  ON u.user_id = b.user_id
ORDER BY COALESCE(b.created_at, u.created_at) DESC;

