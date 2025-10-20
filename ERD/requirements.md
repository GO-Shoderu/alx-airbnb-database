# ERD Requirements
Designing an Entity–Relationship Diagram (ERD) for an Airbnb-like system that supports users (guests/hosts/admin), property listings, bookings, payments, reviews, and messaging. The ERD identifies entities, attributes, and relationships with clear cardinalities.


## Entities & Attributes

### User
- user_id (PK, UUID)
- first_name (TEXT, NOT NULL)
- last_name (TEXT, NOT NULL)
- email (TEXT, UNIQUE, NOT NULL)
- password_hash (TEXT, NOT NULL)
- phone_number (TEXT, NULL)
- role (ENUM: guest | host | admin, NOT NULL)
- created_at (TIMESTAMP, DEFAULT current timestamp)

### Property
- property_id (PK, UUID)
- host_id (FK → User.user_id)
- name (TEXT, NOT NULL)
- description (TEXT, NOT NULL)
- location (TEXT, NOT NULL)
- price_per_night (DECIMAL, NOT NULL)
- created_at (TIMESTAMP, DEFAULT current timestamp)
- updated_at (TIMESTAMP, auto-update)

### Booking
- booking_id (PK, UUID)
- property_id (FK → Property.property_id)
- user_id (FK → User.user_id)
- start_date (DATE, NOT NULL)
- end_date (DATE, NOT NULL)
- total_price (DECIMAL, NOT NULL)
- status (ENUM: pending | confirmed | canceled, NOT NULL)
- created_at (TIMESTAMP, DEFAULT current timestamp)

### Payment
- payment_id (PK, UUID)
- booking_id (FK → Booking.booking_id)
- amount (DECIMAL, NOT NULL)
- payment_date (TIMESTAMP, DEFAULT current timestamp)
- payment_method (ENUM: credit_card | paypal | stripe, NOT NULL)

### Review
- review_id (PK, UUID)
- property_id (FK → Property.property_id)
- user_id (FK → User.user_id)
- rating (INT, CHECK 1–5, NOT NULL)
- comment (TEXT, NOT NULL)
- created_at (TIMESTAMP, DEFAULT current timestamp)

### Message
- message_id (PK, UUID)
- sender_id (FK → User.user_id)
- recipient_id (FK → User.user_id)
- message_body (TEXT, NOT NULL)
- sent_at (TIMESTAMP, DEFAULT current timestamp)


## Relationships & Cardinalities

| Relationship                          | Cardinality                      | FK Location                                  | Rationale                                                                        |
| ------------------------------------- | -------------------------------- | -------------------------------------------- | -------------------------------------------------------------------------------- |
| **User → Property (hosts)**           | `User (1) —— (0..N) Property`    | `Property.host_id → User.user_id`            | A user may host zero or many properties; each property has exactly one host.     |
| **User → Booking (makes)**            | `User (1) —— (0..N) Booking`     | `Booking.user_id → User.user_id`             | A user (guest) can make zero or many bookings; each booking belongs to one user. |
| **Property → Booking (is booked in)** | `Property (1) —— (0..N) Booking` | `Booking.property_id → Property.property_id` | A property can be booked zero or many times; each booking is for one property.   |
| **Booking → Payment (has)**           | `Booking (1) —— (1..N) Payment`  | `Payment.booking_id → Booking.booking_id`    | Every booking must have at least one payment; partial payments allowed.          |
| **Property → Review (receives)**      | `Property (1) —— (0..N) Review`  | `Review.property_id → Property.property_id`  | A property can receive zero or many reviews; each review is for one property.    |
| **User → Review (writes)**            | `User (1) —— (0..N) Review`      | `Review.user_id → User.user_id`              | A user can write zero or many reviews; each review has one author.               |
| **User → Message (sends)**            | `User (1) —— (0..N) Message`     | `Message.sender_id → User.user_id`           | A user can send zero or many messages; each message has one sender.              |
| **User → Message (receives)**         | `User (1) —— (0..N) Message`     | `Message.recipient_id → User.user_id`        | A user can receive zero or many messages; each message has one recipient.        |
