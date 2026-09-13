# Sales & CRM Analytics — PostgreSQL + Power BI

This is an end-to-end sales and CRM analytics project built with PostgreSQL and Power BI.

I wanted to go beyond creating a dashboard, so I built the project from raw data through cleaning, validation, SQL analysis and data modeling, all the way to the final Power BI report.

The dataset is synthetic and was created for portfolio purposes.

## Project overview

The project focuses on sales performance and CRM pipeline analysis.

The main questions I wanted to answer were:

- How much revenue and profit is being generated?
- Which sales representatives and product categories perform best?
- Which lead sources convert best?
- Where do leads drop out of the funnel?
- Which sales stages take the longest?
- Which customers generate the most value?

## Workflow

Raw CSV data → PostgreSQL staging → Data quality checks → Cleaning and validation → Core relational tables → Analytics views → Power BI

## Tools used

- PostgreSQL 18
- pgAdmin 4
- SQL
- Power BI Desktop
- Power Query
- DAX

## Database structure

I divided the PostgreSQL database into four schemas:

- `staging` — raw imported data
- `quality` — detected data quality issues
- `core` — cleaned and validated relational tables
- `analytics` — views prepared for reporting and Power BI

The core layer includes customers, sales representatives, products, leads, lead status history, orders and order items.

## Data quality work

The raw data contains realistic issues such as:

- duplicate IDs
- missing values
- invalid email addresses
- inconsistent text formatting
- broken relationships between tables
- invalid dates
- incorrect numeric values

I used SQL to identify and clean these issues before loading the data into the core layer.

I then ran validation queries to check primary keys, foreign key relationships and required fields before using the data for analysis.

## SQL workflow

The SQL part of the project is split into separate scripts:

```text
01_create_schemas.sql
02_create_staging_tables.sql
03_create_core_tables.sql
04_data_audit.sql
05_clean_and_load.sql
06_data_validation.sql
07_basic_analysis.sql
08_advanced_analysis.sql
09_create_power_bi_views.sql
10_indexes_and_performance.sql
