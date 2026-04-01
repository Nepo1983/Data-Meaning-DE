-- =============================================================================
-- sql/insights/business_insights.sql
-- Task 3 from the use case: SQL Queries for Insights
--
-- Run these against the hospitality_dw database.
-- =============================================================================

-- ── Query 1: Completed bookings count + revenue by property (MAIN REPORT) ─────
-- This directly satisfies Business Requirement 5 from the use case.
SELECT
    p.property_id,
    p.name                           AS property_name,
    p.type                           AS property_type,
    p.location,
    COUNT(b.booking_id)              AS completed_bookings,
    COALESCE(SUM(b.revenue), 0)      AS total_revenue,
    COALESCE(AVG(b.revenue), 0)      AS avg_revenue_per_booking
FROM silver.properties p
LEFT JOIN silver.bookings b
    ON  b.property_id = p.property_id
    AND b.status = 'completed'          -- Revenue Requirement: exclude canceled
GROUP BY
    p.property_id, p.name, p.type, p.location
ORDER BY
    total_revenue DESC;

-- ── Query 2: All bookings with customer + property detail ─────────────────────
SELECT
    b.booking_id,
    p.name          AS property_name,
    c.full_name     AS customer_name,
    b.booking_date,
    b.check_in,
    b.check_out,
    (b.check_out - b.check_in) AS nights,
    b.status,
    b.revenue
FROM silver.bookings b
JOIN silver.properties p ON p.property_id = b.property_id
JOIN silver.customers  c ON c.customer_id  = b.customer_id
ORDER BY b.booking_date DESC;

-- ── Query 3: Revenue summary — completed vs canceled ──────────────────────────
SELECT
    status,
    COUNT(*)            AS booking_count,
    SUM(revenue)        AS total_revenue,
    AVG(revenue)        AS avg_revenue
FROM silver.bookings
GROUP BY status
ORDER BY status;

-- ── Query 4: Pre-aggregated Gold table (faster for dashboards) ────────────────
SELECT
    property_name,
    property_type,
    location,
    completed_bookings,
    total_revenue,
    computed_at
FROM gold.bookings_by_property
ORDER BY total_revenue DESC;

-- ── Query 5: Customer booking history ─────────────────────────────────────────
SELECT
    c.customer_id,
    c.full_name,
    c.nationality,
    COUNT(b.booking_id)              AS total_bookings,
    COUNT(b.booking_id) FILTER (WHERE b.status = 'completed')   AS completed,
    COUNT(b.booking_id) FILTER (WHERE b.status = 'canceled')    AS canceled,
    COALESCE(SUM(b.revenue), 0)      AS lifetime_revenue
FROM silver.customers c
LEFT JOIN silver.bookings b ON b.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name, c.nationality
ORDER BY lifetime_revenue DESC;
