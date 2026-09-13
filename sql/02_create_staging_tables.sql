DROP TABLE IF EXISTS staging.order_items_raw;
DROP TABLE IF EXISTS staging.orders_raw;
DROP TABLE IF EXISTS staging.lead_status_history_raw;
DROP TABLE IF EXISTS staging.leads_raw;
DROP TABLE IF EXISTS staging.products_raw;
DROP TABLE IF EXISTS staging.sales_representatives_raw;
DROP TABLE IF EXISTS staging.customers_raw;

CREATE TABLE staging.customers_raw (
    customer_id TEXT,
    company_name TEXT,
    industry TEXT,
    city TEXT,
    country TEXT,
    company_size TEXT,
    contact_email TEXT,
    phone TEXT,
    created_date TEXT
);

CREATE TABLE staging.sales_representatives_raw (
    sales_rep_id TEXT,
    first_name TEXT,
    last_name TEXT,
    region TEXT,
    team TEXT,
    hire_date TEXT
);

CREATE TABLE staging.leads_raw (
    lead_id TEXT,
    customer_id TEXT,
    sales_rep_id TEXT,
    lead_source TEXT,
    lead_status TEXT,
    created_date TEXT,
    closed_date TEXT,
    estimated_value TEXT
);

CREATE TABLE staging.lead_status_history_raw (
    lead_history_id TEXT,
    lead_id TEXT,
    status TEXT,
    status_date TEXT
);

CREATE TABLE staging.products_raw (
    product_id TEXT,
    product_name TEXT,
    category TEXT,
    unit_price TEXT,
    unit_cost TEXT
);

CREATE TABLE staging.orders_raw (
    order_id TEXT,
    customer_id TEXT,
    sales_rep_id TEXT,
    lead_id TEXT,
    order_date TEXT,
    order_status TEXT,
    discount TEXT
);

CREATE TABLE staging.order_items_raw (
    order_item_id TEXT,
    order_id TEXT,
    product_id TEXT,
    quantity TEXT,
    unit_price TEXT
);
