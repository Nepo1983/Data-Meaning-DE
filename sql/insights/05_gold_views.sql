-- =============================================================================
-- sql/insights/05_gold_views.sql
-- Business-facing views on the gold schema.
-- BI tools (Metabase, Superset) connect to these — never directly to silver.
-- =============================================================================

-- ── View 1: Property Revenue Report (Core BR-5 deliverable) ─────────────────
CREATE OR REPLACE VIEW gold.vw_property_revenue_report AS
SELECT
    p.property_id,
    p.property_name,
    p.location,
    p.property_type,
    p.star_rating,
    COUNT(b.booking_id)                                AS completed_bookings,
    SUM(b.revenue)                                     AS total_revenue,
    ROUND(AVG(b.revenue), 2)                           AS avg_revenue_per_booking,
    ROUND(AVG(b.check_out_date - b.check_in_date), 1)  AS avg_stay_nights,
    MIN(b.check_in_date)                               AS first_completed_stay,
    MAX(b.check_in_date)                               AS last_completed_stay
FROM silver.properties p
INNER JOIN silver.bookings b
    ON b.property_id = p.property_id
   AND b.status = 'completed'
GROUP BY
    p.property_id, p.property_name, p.location,
    p.property_type, p.star_rating
ORDER BY total_revenue DESC;

COMMENT ON VIEW gold.vw_property_revenue_report IS
    'BR-5: Completed bookings and total revenue by property';

-- ── View 2: Executive Summary ────────────────────────────────────────────────
CREATE OR REPLACE VIEW gold.vw_executive_summary AS
SELECT
    COUNT(*)                                                         AS total_bookings,
    COUNT(*) FILTER (WHERE b.status = 'completed')                   AS completed_bookings,
    COUNT(*) FILTER (WHERE b.status = 'cancelled')                   AS cancelled_bookings,
    COUNT(*) FILTER (WHERE b.status = 'confirmed')                   AS confirmed_bookings,
    COALESCE(SUM(b.revenue) FILTER (WHERE b.status = 'completed'), 0) AS realised_revenue,
    COALESCE(SUM(b.revenue) FILTER (WHERE b.status = 'confirmed'), 0) AS pipeline_revenue,
    ROUND(
        COUNT(*) FILTER (WHERE b.status = 'cancelled') * 100.0
        / NULLIF(COUNT(*), 0), 2
    )                                                                AS cancellation_rate_pct
FROM silver.bookings b;

COMMENT ON VIEW gold.vw_executive_summary IS
    'Single-row executive KPIs: total bookings, revenue realised, pipeline, cancellation rate';

-- ── View 3: Monthly Revenue Trend ───────────────────────────────────────────
CREATE OR REPLACE VIEW gold.vw_monthly_revenue AS
SELECT
    TO_CHAR(DATE_TRUNC('month', b.check_in_date), 'YYYY-MM') AS month,
    COUNT(*)                                                   AS completed_bookings,
    SUM(b.revenue)                                             AS total_revenue,
    ROUND(AVG(b.revenue), 2)                                   AS avg_booking_value
FROM silver.bookings b
WHERE b.status = 'completed'
GROUP BY DATE_TRUNC('month', b.check_in_date)
ORDER BY month;

-- ── View 4: Top Customers ────────────────────────────────────────────────────
CREATE OR REPLACE VIEW gold.vw_top_customers AS
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name                         AS customer_name,
    c.loyalty_tier,
    c.country,
    COUNT(b.booking_id)                                        AS completed_stays,
    SUM(b.revenue)                                             AS lifetime_spend,
    RANK() OVER (ORDER BY SUM(b.revenue) DESC)                 AS spend_rank
FROM silver.customers c
INNER JOIN silver.bookings b
    ON b.customer_id = c.customer_id
   AND b.status = 'completed'
GROUP BY c.customer_id, c.first_name, c.last_name, c.loyalty_tier, c.country;
