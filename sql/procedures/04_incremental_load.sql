-- =============================================================================
-- sql/procedures/04_incremental_load.sql
-- Stored Procedure: sp_incremental_load_bookings
--
-- Implements the full incremental load pattern from the use case PDF:
--   a) Load data into a temporary staging table
--   b) COPY command from S3/MinIO (commented out — insert sample data instead)
--   c) Compare staging vs existing to identify new vs updated bookings
--   d) UPDATE status of existing bookings
--   e) INSERT new bookings from staging
--   f) Error handling with EXCEPTION block
-- =============================================================================

-- Drop and recreate for idempotency
DROP PROCEDURE IF EXISTS sp_incremental_load_bookings(TEXT, TEXT);

CREATE OR REPLACE PROCEDURE sp_incremental_load_bookings(
    p_s3_bucket     TEXT DEFAULT 'hospitality-bronze',
    p_s3_key        TEXT DEFAULT 'raw/bookings_incremental.csv'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_updated  INTEGER := 0;
    v_rows_inserted INTEGER := 0;
    v_rows_staged   INTEGER := 0;
    v_start_time    TIMESTAMPTZ := clock_timestamp();
    v_error_msg     TEXT;
BEGIN

    RAISE NOTICE '[sp_incremental_load_bookings] Started at %', v_start_time;

    -- =========================================================================
    -- STEP 1: Create a temporary staging table for this load session.
    --         Dropped automatically when the session/transaction ends.
    -- =========================================================================
    CREATE TEMP TABLE IF NOT EXISTS temp_bookings_staging (
        booking_id      TEXT,
        property_id     TEXT,
        customer_id     TEXT,
        booking_date    DATE,
        check_in_date   DATE,
        check_out_date  DATE,
        status          TEXT,
        revenue         NUMERIC(12,2)
    ) ON COMMIT DELETE ROWS;

    TRUNCATE temp_bookings_staging;

    -- =========================================================================
    -- STEP 2: Load data from S3/MinIO into the staging table.
    --
    --         In a real AWS environment this would be the aws_s3 extension:
    --         SELECT aws_s3.table_import_from_s3(
    --             'temp_bookings_staging', '',
    --             '(FORMAT CSV, HEADER TRUE)',
    --             aws_commons.create_s3_uri(p_s3_bucket, p_s3_key, 'us-east-1')
    --         );
    --
    --         For MinIO / self-hosted Postgres, use COPY FROM PROGRAM:
    -- =========================================================================

    /*
    -- ── COPY command (commented out as per PDF requirements) ─────────────────
    EXECUTE format(
        $copy$
        COPY temp_bookings_staging (
            booking_id, property_id, customer_id, booking_date,
            check_in_date, check_out_date, status, revenue
        )
        FROM PROGRAM
            'aws s3 cp s3://%s/%s - --endpoint-url http://minio:9000 --region us-east-1'
        WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',' );
        $copy$,
        p_s3_bucket, p_s3_key
    );
    */

    -- ── Simulation: direct insert to emulate what the COPY would load ─────────
    -- Represents a typical incremental file: 2 status updates + 2 new bookings.
    INSERT INTO temp_bookings_staging
        (booking_id, property_id, customer_id, booking_date, check_in_date, check_out_date, status, revenue)
    VALUES
        -- Existing booking B009: status update confirmed → completed
        ('B009', 'P001', 'C001', '2024-03-10', '2024-05-01', '2024-05-07', 'completed', 1500.00),
        -- Existing booking B012: status update cancelled → refund waived (keep cancelled)
        ('B012', 'P002', 'C005', '2024-01-25', '2024-03-05', '2024-03-08', 'cancelled',    0.00),
        -- New booking arriving in this file (not in the bookings table yet)
        ('B015', 'P005', 'C007', '2024-04-01', '2024-06-10', '2024-06-15', 'confirmed', 1750.00),
        ('B016', 'P003', 'C008', '2024-04-02', '2024-07-01', '2024-07-07', 'confirmed', 2200.00);

    GET DIAGNOSTICS v_rows_staged = ROW_COUNT;
    RAISE NOTICE '[sp_incremental_load_bookings] Staged % rows', v_rows_staged;

    -- =========================================================================
    -- STEP 3 + 4: Update existing bookings whose status has changed.
    --             Only status and revenue are allowed to change post-creation.
    -- =========================================================================
    UPDATE bookings b
    SET
        status     = s.status,
        revenue    = s.revenue,
        updated_at = now()
    FROM temp_bookings_staging s
    WHERE b.booking_id = s.booking_id          -- match on PK
      AND (b.status <> s.status                -- only write if something changed
           OR b.revenue <> s.revenue);

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
    RAISE NOTICE '[sp_incremental_load_bookings] Updated % existing bookings', v_rows_updated;

    -- =========================================================================
    -- STEP 5: Insert new bookings — those in staging not yet in the main table.
    -- =========================================================================
    INSERT INTO bookings
        (booking_id, property_id, customer_id, booking_date,
         check_in_date, check_out_date, status, revenue)
    SELECT
        s.booking_id,
        s.property_id,
        s.customer_id,
        s.booking_date,
        s.check_in_date,
        s.check_out_date,
        s.status,
        s.revenue
    FROM temp_bookings_staging s
    WHERE NOT EXISTS (
        SELECT 1 FROM bookings b WHERE b.booking_id = s.booking_id
    );

    GET DIAGNOSTICS v_rows_inserted = ROW_COUNT;
    RAISE NOTICE '[sp_incremental_load_bookings] Inserted % new bookings', v_rows_inserted;

    -- =========================================================================
    -- STEP 6: Persist a load summary to the bookings_staging audit table.
    -- =========================================================================
    INSERT INTO bookings_staging
        (booking_id, property_id, customer_id, booking_date,
         check_in_date, check_out_date, status, revenue)
    SELECT * FROM temp_bookings_staging;

    RAISE NOTICE '[sp_incremental_load_bookings] Completed in %ms. Updated=%, Inserted=%',
        EXTRACT(MILLISECONDS FROM clock_timestamp() - v_start_time)::INTEGER,
        v_rows_updated, v_rows_inserted;

-- =========================================================================
-- STEP 7: Error handling (PDF requirement f)
-- =========================================================================
EXCEPTION
    WHEN foreign_key_violation THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RAISE WARNING '[sp_incremental_load_bookings] Foreign key violation — unknown property_id or customer_id: %', v_error_msg;
        ROLLBACK;

    WHEN check_violation THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RAISE WARNING '[sp_incremental_load_bookings] CHECK constraint violated (invalid status or negative revenue): %', v_error_msg;
        ROLLBACK;

    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RAISE EXCEPTION '[sp_incremental_load_bookings] Unexpected error — transaction rolled back: %', v_error_msg;
END;
$$;

COMMENT ON PROCEDURE sp_incremental_load_bookings IS
  'Incremental load: stage from MinIO S3 → update existing bookings → insert new bookings. Error-safe.';


-- =============================================================================
-- EXECUTION
-- Run:  CALL sp_incremental_load_bookings();
-- Then verify with:
-- =============================================================================

-- Verify updates applied:
-- SELECT booking_id, status, revenue, updated_at FROM bookings WHERE booking_id IN ('B009','B012');

-- Verify new insertions:
-- SELECT booking_id, status, revenue, created_at FROM bookings WHERE booking_id IN ('B015','B016');

-- Verify audit trail:
-- SELECT * FROM bookings_staging ORDER BY loaded_at DESC LIMIT 10;
