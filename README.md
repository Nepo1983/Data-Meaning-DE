# 📦 Hospitality Data Platform

## 🌟 Highlights

- Track bookings, properties, and customers.
- Revenue tracking.
- Insight report: completed bookings + revenue by property.
- Incremental load from S3 with upsert.
- Error handling in the load process.
- S3 ingestion.
- Medallion architecture.
- Airflow orchestration.

## ℹ️ Overview

> *This document is the complete setup guide for the Hospitality Industry Data Analytics PoC. It covers the logical model, architecture, and a reference for all SQL deliverables.*

### ✍️ Authors

Fernando Rodrigues Nepomuceno

## 🧮 Logical Model
> *Three entities match the use case specification directly. A Customer makes one or more Bookings. Each Booking is for one Property. Revenue is tracked at the Booking level and is only counted for completed status.*

![screenshot](Blank_diagram.svg)


## 🏛️ Architecture Diagram 

![screenshot](Lambda.png)

## Physical Model Decisions


| Decision | Rationale |
| -------- | --------- |
| TEXT primary keys (booking_id, property_id, customer_id) | Match source system IDs; avoids sequence mismatches on incremental loads |
| CHECK constraint on status | Enforces valid enum values at DB level: confirmed/canceled/completed |
| CHECK constraint on revenue >= 0 | Revenue cannot be negative; canceled bookings default to 0 |
| CHECK constraint on check_out > check_in | Prevents logically invalid stay date ranges |
| Indexes on bookings.property_id, customer_id, status, check_in | Speeds up the primary insight query and date-range filtering |
| Bronze schema uses TEXT-only columns | Avoids type errors on raw data; casting happens in silver layer |
| gold.bookings_by_property uses UPSERT | Idempotent refresh — safe to re-run without duplicates |

*Show off what your software looks like in action! Try to limit it to one-liners if possible and don't delve into API specifics.*


## ⬇️ SQL Reference

### Incremental Load Stored Procedure Flow

| Step | Action | SQL construct |
| ---- | ------ | ------------- |
| 1 | Simulate S3 COPY into bronze.raw_bookings | COPY ... FROM PROGRAM (commented) + INSERT simulation |
| 2 | Update existing bookings (status + revenue) | UPDATE silver.bookings ... FROM bronze.raw_bookings WHERE booking_id matches |
| 3 | Insert new bookings not yet in silver | INSERT ... WHERE NOT EXISTS (SELECT 1 FROM silver.bookings ...) |
| 4 | Refresh gold KPI table | CALL gold.refresh_bookings_by_property() |
| 5 | Error handling | EXCEPTION WHEN OTHERS → RAISE WARNING + re-raise |

## 💡 Possible Enhancements

| Priority | Enhancement | Description |
| -------- | ----------- | ----------- |
| High | dbt for silver/gold transforms | Replace raw SQL in stored procedures with dbt models — adds lineage, docs, testing, and incremental materializations |
| High | Great Expectations | Add a data quality check task between bronze and silver — catches schema drift and column-level anomalies before they reach the DWH |
| High | Alembic schema migrations | Replace CREATE TABLE IF NOT EXISTS with versioned migration scripts — safe for production schema evolution |
| High | Airflow S3 sensor | Replace the fixed daily schedule with an S3KeySensor that triggers the pipeline when a new file lands in the bronze bucket |
| Medium | MinIO bucket notifications | Configure MinIO to send S3-compatible events to a webhook or SQS, enabling event-driven rather than schedule-driven ingestion |
| Medium | rejected_rows audit table | Persist rows that fail silver validation to an audit.rejected_rows table for inspection and replay |
| Medium | Secrets Manager integration | Replace .env file with AWS Secrets Manager or HashiCorp Vault — credentials injected at runtime, never stored in files |
| Medium | Celery executor + Redis | Replace LocalExecutor with CeleryExecutor to allow parallel task execution across multiple workers |
| Medium | BI layer (Metabase / Superset) | Add a Metabase or Apache Superset container connected to the gold schema for self-serve dashboards |
| Low | Terraform for AWS migration | Provision real AWS S3 + RDS + MWAA when moving from PoC to cloud — the Python code needs only a connection string change |
| Low | Docker image with aws CLI | Build a custom Postgres image with aws CLI installed so the COPY FROM PROGRAM S3 command in the stored procedure runs for real |
| Low | CI/CD pipeline | Add GitHub Actions to run unit tests on every push and lint SQL with sqlfluff |
