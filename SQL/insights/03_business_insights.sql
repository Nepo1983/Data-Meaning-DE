-- =============================================================================
-- sql/insights/03_business_insights.sql
-- Business Requirement 5: completed bookings + revenue by property
-- Additional analytical queries for the review session.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 1 — Core Report: Completed Bookings & Revenue by Property  (BR-5)
--
-- Shows every property with at least one completed booking, alongside:
--   • Number of completed bookings
--   • Total revenue from those bookings
--   • Average revenue per booking
--   • Average length of stay in nights
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    p.property_id,
    p.property_name,
    p.location,
    p.property_type,
    COUNT(b.booking_id)                              AS completed_bookings,
    SUM(b.revenue)                                   AS total_revenue,
    ROUND(AVG(b.revenue), 2)                         AS avg_revenue_per_booking,
    ROUND(AVG(b.check_out_date - b.check_in_date), 1) AS avg_stay_nights
FROM properties p
INNER JOIN bookings b
    ON b.property_id = p.property_id
   AND b.status = 'completed'          -- BR-4: completed stays only
GROUP BY
    p.property_id,
    p.property_name,
    p.location,
    p.property_type
ORDER BY
    total_revenue DESC;

-- Expected output with sample data:
-- property_id | property_name            | completed_bookings | total_revenue
-- P001        | Grand Ocean Hotel        | 3                  | 3580.00
-- P005        | Palm Springs Resort      | 1                  | 2100.00
-- P003        | Sunset Villa Rentals     | 1                  | 1800.00
-- P002        | Mountain Breeze B&B      | 2                  |  840.00
-- P004        | City Centre Hostel       | 1                  |  210.00


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 2 — Booking Status Distribution by Property
-- Useful for assessing cancellation rates and revenue pipeline.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    p.property_name,
    b.status,
    COUNT(*)                              AS booking_count,
    COALESCE(SUM(b.revenue), 0)           AS status_revenue
FROM properties p
LEFT JOIN bookings b ON b.property_id = p.property_id
GROUP BY p.property_name, b.status
ORDER BY p.property_name, b.status;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 3 — Monthly Revenue Trend (completed bookings only)
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    TO_CHAR(DATE_TRUNC('month', b.check_in_date), 'YYYY-MM') AS stay_month,
    COUNT(*)                                                   AS completed_bookings,
    SUM(b.revenue)                                             AS monthly_revenue,
    ROUND(AVG(b.revenue), 2)                                   AS avg_booking_value
FROM bookings b
WHERE b.status = 'completed'
GROUP BY DATE_TRUNC('month', b.check_in_date)
ORDER BY stay_month;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 4 — Top Customers by Total Spend (completed bookings)
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name   AS customer_name,
    c.loyalty_tier,
    c.country,
    COUNT(b.booking_id)                  AS completed_stays,
    SUM(b.revenue)                       AS total_spend,
    ROUND(AVG(b.revenue), 2)             AS avg_spend_per_stay,
    RANK() OVER (ORDER BY SUM(b.revenue) DESC) AS spend_rank
FROM customers c
INNER JOIN bookings b
    ON b.customer_id = c.customer_id
   AND b.status = 'completed'
GROUP BY c.customer_id, c.first_name, c.last_name, c.loyalty_tier, c.country
ORDER BY total_spend DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 5 — Revenue at Risk (confirmed bookings — not yet completed)
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    p.property_name,
    COUNT(b.booking_id)         AS upcoming_bookings,
    SUM(b.revenue)              AS revenue_at_risk,
    MIN(b.check_in_date)        AS earliest_check_in,
    MAX(b.check_out_date)       AS latest_check_out
FROM bookings b
INNER JOIN properties p ON b.property_id = p.property_id
WHERE b.status = 'confirmed'
GROUP BY p.property_name
ORDER BY revenue_at_risk DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 6 — Cancellation Rate by Property
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    p.property_name,
    COUNT(*)                                                         AS total_bookings,
    COUNT(*) FILTER (WHERE b.status = 'completed')                   AS completed,
    COUNT(*) FILTER (WHERE b.status = 'cancelled')                   AS cancelled,
    COUNT(*) FILTER (WHERE b.status = 'confirmed')                   AS confirmed,
    ROUND(
        COUNT(*) FILTER (WHERE b.status = 'cancelled') * 100.0
        / NULLIF(COUNT(*), 0), 2
    )                                                                AS cancellation_rate_pct
FROM properties p
LEFT JOIN bookings b ON b.property_id = p.property_id
GROUP BY p.property_name
ORDER BY cancellation_rate_pct DESC;
