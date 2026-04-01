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

> *This document is the complete setup guide for the Hospitality Industry Data Analytics PoC. It covers the architecture, the account information you need to collect before starting, a step-by-step deployment walkthrough, and a reference for all SQL deliverables.*

### ✍️ Authors

Fernando Rodrigues Nepomuceno

## 🧮 Logical Model
> *Three entities match the use case specification directly. A Customer makes one or more Bookings. Each Booking is for one Property. Revenue is tracked at the Booking level and is only counted for completed status.*

![screenshot](Blank_diagram.svg)


## 🏛️ Architecture Diagram 

![screenshot](Lambda.png)

## Physical Model Decisions


| Header 1 | Header 2 | Header 3 |
| -------- | -------- | -------- |
| Row 1, Col 1 | Row 1, Col 2 | Row 1, Col 3 |
| Row 2, Col 1 | Row 2, Col 2 | Row 2, Col 3 |


*Show off what your software looks like in action! Try to limit it to one-liners if possible and don't delve into API specifics.*


## ⬇️ Installation

Simple, understandable installation instructions!

```bash
pip install my-package
```

And be sure to specify any other minimum requirements, like Python versions or operating systems.

*You may be inclined to add development instructions here, don't.*


## 💭 Feedback and Contributing

Add a link to the Discussions tab in your repo and invite users to open issues for bugs/feature requests.

This is also a great place to invite others to contribute in any ways that make sense for your project. Point people to your DEVELOPMENT and/or CONTRIBUTING guides if you have them.
