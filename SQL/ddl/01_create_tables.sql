-- =============================================================================
-- sql/ddl/01_create_tables.sql
-- Standalone DDL — can be pasted directly into sqlfiddle.com (PostgreSQL)
-- or executed against the Dockerised DWH.
-- =============================================================================

-- ── Customers ──────────────────────────────────────────────────────────────────
CREATE TABLE customers (
    customer_id     VARCHAR(20)  PRIMARY KEY,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(200) UNIQUE NOT NULL,
    phone           VARCHAR(30),
    country         VARCHAR(60),
    loyalty_tier    VARCHAR(20)  DEFAULT 'none'
                                 CHECK (loyalty_tier IN ('none','bronze','silver','gold','platinum')),
    created_at      TIMESTAMPTZ  DEFAULT now()
);
COMMENT ON TABLE customers IS 'Customer master — one row per unique customer';

-- ── Properties ────────────────────────────────────────────────────────────────
CREATE TABLE properties (
    property_id     VARCHAR(20)  PRIMARY KEY,
    property_name   VARCHAR(200) NOT NULL,
    location        VARCHAR(200) NOT NULL,
    property_type   VARCHAR(30)  NOT NULL
                                 CHECK (property_type IN ('hotel','b&b','vacation_rental','hostel','resort')),
    capacity        INTEGER      NOT NULL CHECK (capacity > 0),
    star_rating     NUMERIC(2,1) CHECK (star_rating BETWEEN 1 AND 5),
    is_active       BOOLEAN      DEFAULT TRUE,
    created_at      TIMESTAMPTZ  DEFAULT now()
);
COMMENT ON TABLE properties IS 'Property master — hotels, B&Bs, vacation rentals';

-- ── Bookings ──────────────────────────────────────────────────────────────────
CREATE TABLE bookings (
    booking_id      VARCHAR(20)  PRIMARY KEY,
    property_id     VARCHAR(20)  NOT NULL REFERENCES properties(property_id),
    customer_id     VARCHAR(20)  NOT NULL REFERENCES customers(customer_id),
    booking_date    DATE         NOT NULL,
    check_in_date   DATE         NOT NULL,
    check_out_date  DATE         NOT NULL,
    status          VARCHAR(20)  NOT NULL
                                 CHECK (status IN ('confirmed','cancelled','completed')),
    revenue         NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (revenue >= 0),
    created_at      TIMESTAMPTZ  DEFAULT now(),
    updated_at      TIMESTAMPTZ  DEFAULT now(),
    CONSTRAINT chk_dates CHECK (check_out_date > check_in_date)
);
COMMENT ON TABLE bookings IS
  'Booking fact — status: confirmed | cancelled | completed; revenue excluded for cancelled';

-- ── Staging table for incremental load ────────────────────────────────────────
CREATE TABLE bookings_staging (
    booking_id      VARCHAR(20),
    property_id     VARCHAR(20),
    customer_id     VARCHAR(20),
    booking_date    DATE,
    check_in_date   DATE,
    check_out_date  DATE,
    status          VARCHAR(20),
    revenue         NUMERIC(12,2),
    loaded_at       TIMESTAMPTZ  DEFAULT now()
);
COMMENT ON TABLE bookings_staging IS
  'Temporary staging area for incremental booking loads from S3/MinIO';

-- ── Indexes ────────────────────────────────────────────────────────────────────
CREATE INDEX idx_bookings_property ON bookings (property_id);
CREATE INDEX idx_bookings_customer ON bookings (customer_id);
CREATE INDEX idx_bookings_status   ON bookings (status);
CREATE INDEX idx_bookings_checkin  ON bookings (check_in_date);
CREATE INDEX idx_staging_booking   ON bookings_staging (booking_id);
