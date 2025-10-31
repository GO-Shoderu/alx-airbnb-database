# Complex Joins (AirBnB DB)

This folder contains SQL queries demonstrating **INNER JOIN**, **LEFT JOIN**, **FULL OUTER JOIN**, **Correlated Subquery, Non-Correlated Subquery** using the AirBnB schema:

- **User(user_id, first_name, last_name, email, role, ...)**
- **Property(property_id, host_id, name, location, pricepernight, ...)**
- **Booking(booking_id, property_id, user_id, start_date, end_date, total_price, status, ...)**
- **Review(review_id, property_id, user_id, rating, comment, ...)**

##### _**More information about the schema can be found in the ERD directory!!!**_

## Files
- `joins_queries.sql` — contains three join queries:
    1. **INNER JOIN**: Bookings with their Users.
    2. **LEFT JOIN**: All Properties with (optional) Reviews.
    3. **FULL OUTER JOIN**: All Users and all Bookings (native in Postgres; emulated for MySQL via `LEFT JOIN UNION ALL RIGHT JOIN ... WHERE left IS NULL`).

- `subqueries.sql` — contains Subqueries:
    1. **Correlated Subquery**: Finding all users who have made more than 3 bookings.
    2. **Non-Correlated Subquery**: Finding all properties where the average rating is greater than 4.0.  
