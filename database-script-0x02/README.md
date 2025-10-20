# ALX Airbnb Database — Seed (DML)

This folder contains SQL to populate the schema with realistic sample data:
- Multiple **users** (guests + hosts)
- Multiple **properties** owned by hosts
- **Bookings** covering confirmed, pending, and canceled states
- **Payments** including partial and full payments
- **Reviews** (unique per user–property)
- **Messages** between guests and hosts

## Files
- `seed.sql` — INSERT statements wrapped in a transaction.

## Prerequisites
- Run `database-script-0x01/schema.sql` first (creates tables, constraints, indexes).
- PostgreSQL 13+ (or compatible).

## Load the data
```bash
psql -U <user> -h <host> -d <database> -f seed.sql
