Sales & CRM Analytics – PostgreSQL + Power BI

This project is an end-to-end sales and CRM analytics project built with PostgreSQL and Power BI.

The goal was to create a complete workflow starting from raw and imperfect data, then clean and validate it in SQL, prepare an analytical layer and finally build a Power BI report that could be used to monitor sales performance and CRM pipeline efficiency.

The dataset is synthetic and was created for portfolio purposes.

Project workflow

Raw CSV data
PostgreSQL staging layer
Data quality checks
Data cleaning and validation
Core relational tables
Analytics views
Power BI dashboard

Tools used

PostgreSQL 18
pgAdmin 4
SQL
Power BI Desktop
Power Query
DAX

Database structure

The database is divided into four main schemas.

staging

Contains the raw imported data before cleaning.

Tables include:

customers_raw
sales_representatives_raw
products_raw
leads_raw
lead_status_history_raw
orders_raw
order_items_raw

core

Contains cleaned and validated data used for analysis.

Tables include:

customers
sales_representatives
products
leads
lead_status_history
orders
order_items

quality

Used to identify and store data quality problems found in the raw dataset.

The checks include duplicate records, missing values, invalid emails, incorrect relationships between tables and invalid numeric values.

analytics

Contains views created specifically for analysis and Power BI.

Main views:

vw_sales_details
vw_sales_rep_performance
vw_customer_value
vw_lead_source_performance
vw_pipeline_stage_performance
vw_lead_stage_durations
vw_monthly_sales

Data cleaning

The raw dataset contains several realistic data quality issues.

I used SQL to identify and clean problems such as duplicate IDs, missing values, inconsistent text formatting, invalid email addresses, incorrect relationships between tables, invalid dates and incorrect numeric values.

After the cleaning process, validation queries were used to check primary keys, foreign key relationships and required fields before the data was used for reporting.

SQL structure

The SQL part of the project is divided into separate scripts:

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

The project uses joins, CTEs, window functions, LAG, LEAD, ROW_NUMBER, DENSE_RANK, CASE, FILTER, conditional aggregation, date calculations, running totals, funnel analysis and customer value analysis.

Indexes were also added to frequently used columns and EXPLAIN ANALYZE was used to review query performance.

Main business results

Total Revenue: 74.7 mln zł

Total Profit: 48.1 mln zł

Profit Margin: 64.3%

Completed Orders: 2 369

Average Order Value: 31 536 zł

CRM pipeline

Total Leads: 5 000

Contacted: 4 940

Qualified: 3 616

Proposal: 2 091

Won: 918

Overall lead conversion rate: 18.4%

Lead source conversion

Referral: 32.2%

Trade Show: 25.7%

Google Ads: 19.4%

LinkedIn: 15.4%

Website: 13.9%

Cold Email: 11.1%

Average time in funnel stages

New: 3.0 days

Contacted: 8.0 days

Qualified: 10.6 days

Proposal: 15.1 days

Main insights

Referral is the strongest lead source with a conversion rate of 32.2%.

Cold Email performs the weakest with a conversion rate of 11.1%.

The Proposal stage is the longest part of the sales process and takes around 15 days on average.

Only 18.4% of all leads reach the Won stage, which shows that improving conversion between Qualified, Proposal and Won could have a significant impact on results.

The Analytics product category generates the highest revenue and profit in the dataset.

Power BI report

The final Power BI report contains two pages.

Executive Overview

This page focuses on overall sales performance.

It includes Total Revenue, Total Profit, Profit Margin, Completed Orders, Average Order Value, Monthly Revenue Trend, Top Sales Representatives and Revenue vs Profit by Product Category.

CRM Pipeline & Lead Analysis

This page focuses on lead performance and the sales funnel.

It includes Total Leads, Won Leads, Lead Conversion, Average Days to Win, Lead Funnel, Conversion by Lead Source, Lead Source Performance and Average Time in Funnel Stage.

What I wanted to show with this project

The main goal was not only to build a dashboard.

I wanted to show the full process behind it: importing raw data, finding quality problems, cleaning the data, building a structured PostgreSQL model, creating analytical SQL views and connecting the final reporting layer to Power BI.

This project demonstrates how I approach a complete analytics workflow rather than only the visualization part.

Author

MS Analytics

Data. Insights. Growth.
