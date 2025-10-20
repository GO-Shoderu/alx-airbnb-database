# Normalization to 3NF

For my own future reminder, **Normalization** is the disciplined way we structure relational tables so that:
- Each fact is stored once (no unnecessary duplication),
- Changes don’t create update/insert/delete anomalies (for example, if a user's email were stored in multiple tables, changing it in one place and forgetting others would create an update anomaly), and
- Queries remain reliable and maintainable as the system grows.

Related facts are kept together, unrelated facts are apart, and connected with foreign keys.
