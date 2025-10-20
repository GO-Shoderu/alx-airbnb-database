# Normalization to 3NF

For my own future reminder, **Normalization** is the disciplined way we structure relational tables so that:
- Each fact is stored once (no unnecessary duplication),
- Changes don’t create update/insert/delete anomalies (for example, if a user's email were stored in multiple tables, changing it in one place and forgetting others would create an update anomaly), and
- Queries remain reliable and maintainable as the system grows.

Related facts are kept together, unrelated facts are apart, and connected with foreign keys.


## Rules for the Normal Forms we target
We check in order because each level builds on the previous one.

### First Normal Form (1NF)
- Each column should store one clear piece of information only. For example, instead of keeping a list of phone numbers in one cell like '0123, 0456', store each phone number in a separate row or another table. This avoids confusion and keeps the data simple and searchable.
- No repeating groups like item1, item2, item3 columns.
- Each row is uniquely identifiable (via a primary key).

### Second Normal Form (2NF)
- This rule applies only when the primary key is made up of two or more columns, called a composite key. For example, in an Order table that uses both order_id and item_id as its key, we must ensure every other column depends on both, not just one part of that combined key.
- Every non-key attribute must depend on the whole key (no partial dependency on just part of the composite key).

### Third Normal Form (3NF)
- There should be no chain of dependencies between columns. In simple terms, every piece of information in a table should describe the main subject of that table and nothing else. A transitive dependency happens when one non‑key column depends on another non‑key column instead of directly on the primary key. For example, in a Student table that stores both dept_id and dept_name, the student's primary key is student_id. However, dept_name depends on dept_id (which is another non‑key column) rather than directly on student_id. This creates a chain of dependency: student_id → dept_id → dept_name. To fix this, move department details into a separate Department table and link it using dept_id. This ensures every column in Student depends only on its own key.
- Informally: "Every non-key fact is about the key — the whole key — and nothing but the key."


## Step-by-step Checks per Table (1NF -> 2NF -> 3NF)

### User(user_id, first_name, last_name, email, password_hash, phone_number, role, created_at)
- 1NF: All attributes are atomic; no repeating groups.
- 2NF: Single-column PK (user_id) ⇒ no partial dependency.
- 3NF: Non-key attributes (names, email, phone_number, role, created_at) depend only on user_id. None depends on another non-key (e.g., name does not determine email).

### Property(property_id, host_id, name, description, location, price_per_night, created_at, updated_at)
- 1NF: Attributes are atomic; location is treated as a single text field in this spec.
- 2NF: Single-column PK ⇒ no partial dependency.
- 3NF: All attributes depend only on property_id. host_id is a foreign key and does not determine other non-key columns within Property.

### Booking(booking_id, property_id, user_id, start_date, end_date, total_price, status, created_at)
- 1NF: All attributes are atomic.
- 2NF: Single-column PK ⇒ no partial dependency.
- 3NF: Potential concern is total_price which can be derived from Property.price_per_night × nights ± fees/discounts. Storing it can introduce a transitive dependency across tables.

### Payment(payment_id, booking_id, amount, payment_date, payment_method)
- 1NF: Atomic values.
- 2NF: Single-column PK ⇒ no partial dependency.
- 3NF: All non-key attributes depend only on payment_id. No non-key determines another non-key.

### Review(review_id, property_id, user_id, rating, comment, created_at)

- 1NF: Atomic values.
- 2NF: Single-column PK ⇒ no partial dependency.
- 3NF: All non-key attributes depend only on review_id.

### Message(message_id, sender_id, recipient_id, message_body, sent_at)
- 1NF: Atomic values.
- 2NF: Single-column PK ⇒ no partial dependency.
- 3NF: Non-key attributes depend only on message_id.

### Something that could improve is ensuring one review per user per property in the review table.
