-- ALX Airbnb Database — seed.sql (PostgreSQL)
-- Populates users, properties, bookings, payments, reviews, messages
-- Safe to run after schema.sql

BEGIN;

-- =========
-- USERS
-- =========
-- Note: password_hash values are placeholders
INSERT INTO users (user_id, first_name, last_name, email, password_hash, phone_number, role)
VALUES
  ('2f1a6a10-1111-4a1b-9c10-aaa000000001','Tumi','Mokoena','tumi@example.com','hash$1','+27110000001','guest'),
  ('2f1a6a10-1111-4a1b-9c10-aaa000000002','Ayo','Adegoke','ayo@example.com','hash$2','+27110000002','guest'),
  ('2f1a6a10-1111-4a1b-9c10-aaa000000003','Zee','Nkosi','zee@example.com','hash$3','+27110000003','host'),
  ('2f1a6a10-1111-4a1b-9c10-aaa000000004','Becky','Smith','becky@example.com','hash$4','+27110000004','guest'),
  ('2f1a6a10-1111-4a1b-9c10-aaa000000005','Alex','Dlamini','alex@example.com','hash$5','+27110000005','host');

-- =========
-- PROPERTIES
-- =========
INSERT INTO properties (property_id, host_id, name, description, location, price_per_night)
VALUES
  ('5b2b7b20-2222-4b2c-8d20-bbb000000001','2f1a6a10-1111-4a1b-9c10-aaa000000005',
   'Sunny Loft','Top-floor loft with skyline views','Johannesburg, Gauteng',950.00),
  ('5b2b7b20-2222-4b2c-8d20-bbb000000002','2f1a6a10-1111-4a1b-9c10-aaa000000003',
   'City Pad','Modern 1-bed close to transit','Pretoria, Gauteng',700.00),
  ('5b2b7b20-2222-4b2c-8d20-bbb000000003','2f1a6a10-1111-4a1b-9c10-aaa000000005',
   'Garden Cottage','Cozy cottage with private garden','Centurion, Gauteng',650.00),
  ('5b2b7b20-2222-4b2c-8d20-bbb000000004','2f1a6a10-1111-4a1b-9c10-aaa000000003',
   'Beach Hut','Rustic hut near the coast','Durban, KZN',800.00);

-- =========
-- BOOKINGS
-- =========
-- Note: totals are snapshots at time of booking (price_per_night * nights; simple example)
INSERT INTO bookings (booking_id, property_id, user_id, start_date, end_date, total_price, status)
VALUES
  -- Tumi books Sunny Loft: 3 nights * 950 = 2850
  ('7c3c8c30-3333-4c3d-9e30-ccc000000001','5b2b7b20-2222-4b2c-8d20-bbb000000001',
   '2f1a6a10-1111-4a1b-9c10-aaa000000001','2025-11-01','2025-11-04',2850.00,'confirmed'),

  -- Ayo books City Pad: 2 nights * 700 = 1400
  ('7c3c8c30-3333-4c3d-9e30-ccc000000002','5b2b7b20-2222-4b2c-8d20-bbb000000002',
   '2f1a6a10-1111-4a1b-9c10-aaa000000002','2025-12-10','2025-12-12',1400.00,'pending'),

  -- Becky books Beach Hut: 2 nights * 800 = 1600
  ('7c3c8c30-3333-4c3d-9e30-ccc000000003','5b2b7b20-2222-4b2c-8d20-bbb000000004',
   '2f1a6a10-1111-4a1b-9c10-aaa000000004','2025-10-25','2025-10-27',1600.00,'confirmed'),

  -- Tumi books Garden Cottage: 3 nights * 650 = 1950
  ('7c3c8c30-3333-4c3d-9e30-ccc000000004','5b2b7b20-2222-4b2c-8d20-bbb000000003',
   '2f1a6a10-1111-4a1b-9c10-aaa000000001','2026-01-05','2026-01-08',1950.00,'confirmed'),

  -- Ayo books Sunny Loft: 2 nights * 950 = 1900 (then cancels)
  ('7c3c8c30-3333-4c3d-9e30-ccc000000005','5b2b7b20-2222-4b2c-8d20-bbb000000001',
   '2f1a6a10-1111-4a1b-9c10-aaa000000002','2025-11-15','2025-11-17',1900.00,'canceled');

-- =========
-- PAYMENTS
-- =========
-- Each booking has at least one payment; some have partials
INSERT INTO payments (payment_id, booking_id, amount, payment_method, payment_date)
VALUES
  -- Booking 1 (Tumi, Sunny Loft): two partials
  ('9d4d9d40-4444-4d4e-af40-ddd000000001','7c3c8c30-3333-4c3d-9e30-ccc000000001',1500.00,'credit_card','2025-10-20T10:00:00+02'),
  ('9d4d9d40-4444-4d4e-af40-ddd000000002','7c3c8c30-3333-4c3d-9e30-ccc000000001',1350.00,'credit_card','2025-10-28T16:30:00+02'),

  -- Booking 2 (Ayo, City Pad): pending, deposit paid
  ('9d4d9d40-4444-4d4e-af40-ddd000000003','7c3c8c30-3333-4c3d-9e30-ccc000000002',400.00,'paypal','2025-11-15T09:00:00+02'),

  -- Booking 3 (Becky, Beach Hut): fully paid in one go
  ('9d4d9d40-4444-4d4e-af40-ddd000000004','7c3c8c30-3333-4c3d-9e30-ccc000000003',1600.00,'stripe','2025-10-20T12:10:00+02'),

  -- Booking 4 (Tumi, Garden Cottage): two partials
  ('9d4d9d40-4444-4d4e-af40-ddd000000005','7c3c8c30-3333-4c3d-9e30-ccc000000004',950.00,'credit_card','2025-12-10T14:20:00+02'),
  ('9d4d9d40-4444-4d4e-af40-ddd000000006','7c3c8c30-3333-4c3d-9e30-ccc000000004',1000.00,'credit_card','2026-01-02T08:45:00+02');

-- =========
-- REVIEWS
-- =========
INSERT INTO reviews (review_id, property_id, user_id, rating, comment, created_at)
VALUES
  ('ac5eae50-5555-4e5f-b050-eee000000001','5b2b7b20-2222-4b2c-8d20-bbb000000001','2f1a6a10-1111-4a1b-9c10-aaa000000001',5,'Amazing skyline views. Super clean.','2025-11-05T11:00:00+02'),
  ('ac5eae50-5555-4e5f-b050-eee000000002','5b2b7b20-2222-4b2c-8d20-bbb000000004','2f1a6a10-1111-4a1b-9c10-aaa000000004',4,'Rustic but cozy. Loved the beach access.','2025-10-28T09:10:00+02'),
  ('ac5eae50-5555-4e5f-b050-eee000000003','5b2b7b20-2222-4b2c-8d20-bbb000000003','2f1a6a10-1111-4a1b-9c10-aaa000000001',5,'Peaceful garden spot. Great host.','2026-01-09T10:00:00+02');

-- =========
-- MESSAGES
-- =========
INSERT INTO messages (message_id, sender_id, recipient_id, message_body, sent_at)
VALUES
  -- Guest to host about Sunny Loft
  ('bd6fbf60-6666-4f60-b160-fff000000001','2f1a6a10-1111-4a1b-9c10-aaa000000001','2f1a6a10-1111-4a1b-9c10-aaa000000005',
   'Hi Alex, can I check in at 2pm instead of 3pm?','2025-10-19T08:00:00+02'),

  -- Host reply
  ('bd6fbf60-6666-4f60-b160-fff000000002','2f1a6a10-1111-4a1b-9c10-aaa000000005','2f1a6a10-1111-4a1b-9c10-aaa000000001',
   'Hi Tumi, 2pm is perfectly fine. See you then!','2025-10-19T08:15:00+02'),

  -- Guest to host about Beach Hut
  ('bd6fbf60-6666-4f60-b160-fff000000003','2f1a6a10-1111-4a1b-9c10-aaa000000004','2f1a6a10-1111-4a1b-9c10-aaa000000003',
   'Hey Zee, is late checkout possible on Sunday?','2025-10-24T18:40:00+02');

COMMIT;
