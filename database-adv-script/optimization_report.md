# Optimization Report (AirBnB)

## Objective
Refactor a complex multi-join query to reduce execution time and avoid unnecessary work while preserving the required result (bookings with user, property, and payment details).

## Environment
- PostgreSQL 16 (Docker container `airbnb-pg`)
- DB: `airbnb_db`
- How executed: `docker exec -it airbnb-pg psql -U postgres -d airbnb_db`
- Files: `perfomance.sql` (queries + EXPLAIN), `database_index.sql` (indexes from Task 3)

## Initial Query (Baseline)
**Shape:**
```sql
SELECT ...
FROM bookings b
JOIN users u       ON u.user_id = b.user_id
JOIN properties p  ON p.property_id = b.property_id
LEFT JOIN payments pay ON pay.booking_id = b.booking_id
ORDER BY b.created_at DESC;
```

**Observed issues:**
- **Row multiplication:** each booking can have **multiple payments**, so joining `payments` directly duplicates booking rows.
- **Extra I/O / Sort Work:** wider rowset and duplicates increase sort and memory usage.
- **Join selectivity:** no filtering; plans tend to favor scans/aggregations across many rows.

**Measurement:**
Executed with `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)` inside `perfomance.sql`.

## Refactor Strategy
1. **Reduce duplicates at the source** by selecting **only the latest payment per booking**.
2. **Use appropriate indexes** so the planner can jump to needed rows quickly.

### Indexes supporting the refactor
- `CREATE INDEX IF NOT EXISTS idx_payments_booking_id            ON payments(booking_id);`
- `CREATE INDEX IF NOT EXISTS idx_payments_booking_date_desc     ON payments(booking_id, payment_date DESC);`
- `bookings(user_id)`, `bookings(property_id)` speed the core joins.

## Refactor #1 — LATERAL
```sql
LEFT JOIN LATERAL (
  SELECT payment_id, amount, payment_date, payment_method
  FROM payments pay
  WHERE pay.booking_id = b.booking_id
  ORDER BY payment_date DESC
  LIMIT 1
) AS pay_latest ON TRUE
```
**Why it’s faster:** reads **one** payment per booking using `(booking_id, payment_date DESC)`; avoids row bloat.

## Refactor #2 — Window Function (alternative)
```sql
WITH latest_payment AS (
  SELECT payment_id, booking_id, amount, payment_date, payment_method,
         ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY payment_date DESC) AS rn
  FROM payments
)
... LEFT JOIN latest_payment lp ON lp.booking_id = b.booking_id AND lp.rn = 1
```
**Why it’s good:** decouples the "latest payment" set for reuse in other queries; similar runtime when indexed.

## Conclusion
- The refactor removes unnecessary row multiplication and reduces I/O.
- The composite index on `payments(booking_id, payment_date DESC)` enables efficient access to the most recent payment.
- For paginated endpoints, consider adding `LIMIT/OFFSET` and projecting only necessary columns to further reduce work.


