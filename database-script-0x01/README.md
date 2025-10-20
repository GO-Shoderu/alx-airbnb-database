# ALX Airbnb Database — Schema (DDL)

This folder contains the SQL to create a normalized PostgreSQL schema for an Airbnb app.

## Files
- `schema.sql` — creates tables, keys, constraints, and helpful indexes.

## Prerequisites
- PostgreSQL 13+ (or compatible)
- Recommended extensions: `citext`, `pgcrypto`
  - `citext` enables case-insensitive unique emails
  - `pgcrypto` provides `gen_random_uuid()` for UUID defaults

## Quick Start
```bash
psql -U <user> -h <host> -d <database> -f schema.sql
