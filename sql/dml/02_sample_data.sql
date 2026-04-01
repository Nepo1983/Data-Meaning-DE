-- =============================================================================
-- sql/dml/02_sample_data.sql
-- Populates tables with a small representative dataset.
-- Covers: confirmed, cancelled, and completed booking statuses.
-- =============================================================================

-- ── Customers ──────────────────────────────────────────────────────────────────
INSERT INTO customers (customer_id, first_name, last_name, email, phone, country, loyalty_tier) VALUES
  ('C001', 'James',   'Sullivan',  'james.sullivan@email.com',   '+1-212-555-0101', 'US', 'gold'),
  ('C002', 'Maria',   'Gonzalez',  'maria.gonzalez@email.com',   '+1-305-555-0102', 'US', 'silver'),
  ('C003', 'Luca',    'Ferrari',   'luca.ferrari@email.com',     '+39-02-555-0103', 'IT', 'bronze'),
  ('C004', 'Sophie',  'Dubois',    'sophie.dubois@email.com',    '+33-1-555-0104',  'FR', 'platinum'),
  ('C005', 'Carlos',  'Mendoza',   'carlos.mendoza@email.com',   '+52-55-555-0105', 'MX', 'none'),
  ('C006', 'Emma',    'Williams',  'emma.williams@email.com',    '+44-20-555-0106', 'GB', 'gold'),
  ('C007', 'Hiroshi', 'Tanaka',    'hiroshi.tanaka@email.com',   '+81-3-555-0107',  'JP', 'silver'),
  ('C008', 'Isabela', 'Oliveira',  'isabela.oliveira@email.com', '+55-11-555-0108', 'BR', 'bronze')
ON CONFLICT (customer_id) DO NOTHING;

-- ── Properties ────────────────────────────────────────────────────────────────
INSERT INTO properties (property_id, property_name, location, property_type, capacity, star_rating) VALUES
  ('P001', 'Grand Ocean Hotel',     'Miami Beach, FL',      'hotel',          200, 5.0),
  ('P002', 'Mountain Breeze B&B',   'Asheville, NC',        'b&b',             12, 4.0),
  ('P003', 'Sunset Villa Rentals',  'Malibu, CA',           'vacation_rental',  6, 4.5),
  ('P004', 'City Centre Hostel',    'New York, NY',         'hostel',          80, 3.0),
  ('P005', 'Palm Springs Resort',   'Palm Springs, CA',     'resort',         150, 4.5)
ON CONFLICT (property_id) DO NOTHING;

-- ── Bookings ──────────────────────────────────────────────────────────────────
-- Mix of completed (revenue counted), confirmed (upcoming), and cancelled (excluded)
INSERT INTO bookings (booking_id, property_id, customer_id, booking_date, check_in_date, check_out_date, status, revenue) VALUES
  -- Completed stays (revenue recognised)
  ('B001', 'P001', 'C001', '2024-01-05', '2024-01-15', '2024-01-20', 'completed',  1250.00),
  ('B002', 'P001', 'C002', '2024-01-10', '2024-02-01', '2024-02-05', 'completed',   980.00),
  ('B003', 'P002', 'C003', '2024-01-12', '2024-02-10', '2024-02-14', 'completed',   560.00),
  ('B004', 'P003', 'C004', '2024-01-20', '2024-02-20', '2024-02-25', 'completed',  1800.00),
  ('B005', 'P004', 'C005', '2024-02-01', '2024-03-01', '2024-03-04', 'completed',   210.00),
  ('B006', 'P005', 'C006', '2024-02-15', '2024-03-10', '2024-03-17', 'completed',  2100.00),
  ('B007', 'P001', 'C007', '2024-02-20', '2024-03-15', '2024-03-20', 'completed',  1350.00),
  ('B008', 'P002', 'C008', '2024-03-01', '2024-04-01', '2024-04-03', 'completed',   280.00),
  -- Confirmed (future / current stays)
  ('B009', 'P001', 'C001', '2024-03-10', '2024-05-01', '2024-05-07', 'confirmed',  1500.00),
  ('B010', 'P003', 'C002', '2024-03-15', '2024-05-15', '2024-05-22', 'confirmed',  2100.00),
  ('B011', 'P005', 'C004', '2024-03-20', '2024-06-01', '2024-06-08', 'confirmed',  2450.00),
  -- Cancelled (revenue = 0, excluded from reports)
  ('B012', 'P002', 'C005', '2024-01-25', '2024-03-05', '2024-03-08', 'cancelled',     0.00),
  ('B013', 'P004', 'C006', '2024-02-05', '2024-04-10', '2024-04-12', 'cancelled',     0.00),
  ('B014', 'P001', 'C003', '2024-02-28', '2024-04-20', '2024-04-25', 'cancelled',     0.00)
ON CONFLICT (booking_id) DO NOTHING;
