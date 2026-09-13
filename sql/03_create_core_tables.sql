DROP TABLE IF EXISTS core.order_items CASCADE;
DROP TABLE IF EXISTS core.orders CASCADE;
DROP TABLE IF EXISTS core.lead_status_history CASCADE;
DROP TABLE IF EXISTS core.leads CASCADE;
DROP TABLE IF EXISTS core.products CASCADE;
DROP TABLE IF EXISTS core.sales_representatives CASCADE;
DROP TABLE IF EXISTS core.customers CASCADE;
DROP TABLE IF EXISTS quality.issue_log;

CREATE TABLE quality.issue_log (
    issue_id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(80) NOT NULL,
    record_id VARCHAR(40),
    issue_type VARCHAR(80) NOT NULL,
    raw_value TEXT,
    detected_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE core.customers (
    customer_id VARCHAR(12) PRIMARY KEY,
    company_name VARCHAR(150) NOT NULL,
    industry VARCHAR(80) NOT NULL,
    city VARCHAR(80) NOT NULL,
    country VARCHAR(50) NOT NULL,
    company_size VARCHAR(30) NOT NULL
        CHECK (company_size IN ('Micro', 'Small', 'Medium', 'Large')),
    contact_email VARCHAR(180),
    phone VARCHAR(30),
    created_date DATE NOT NULL
);

CREATE TABLE core.sales_representatives (
    sales_rep_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    region VARCHAR(30) NOT NULL,
    team VARCHAR(30) NOT NULL
        CHECK (team IN ('SMB', 'Mid-Market', 'Enterprise')),
    hire_date DATE NOT NULL
);

CREATE TABLE core.products (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category VARCHAR(80) NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price > 0),
    unit_cost NUMERIC(12,2) NOT NULL CHECK (unit_cost >= 0),
    CHECK (unit_price >= unit_cost)
);

CREATE TABLE core.leads (
    lead_id VARCHAR(15) PRIMARY KEY,
    customer_id VARCHAR(12) NOT NULL REFERENCES core.customers(customer_id),
    sales_rep_id VARCHAR(10) NOT NULL REFERENCES core.sales_representatives(sales_rep_id),
    lead_source VARCHAR(40) NOT NULL,
    lead_status VARCHAR(20) NOT NULL
        CHECK (lead_status IN ('New', 'Contacted', 'Qualified', 'Proposal', 'Won', 'Lost')),
    created_date DATE NOT NULL,
    closed_date DATE,
    estimated_value NUMERIC(14,2) NOT NULL CHECK (estimated_value >= 0),
    CHECK (closed_date IS NULL OR closed_date >= created_date)
);

CREATE TABLE core.lead_status_history (
    lead_history_id VARCHAR(20) PRIMARY KEY,
    lead_id VARCHAR(15) NOT NULL REFERENCES core.leads(lead_id),
    status VARCHAR(20) NOT NULL
        CHECK (status IN ('New', 'Contacted', 'Qualified', 'Proposal', 'Won', 'Lost')),
    status_date DATE NOT NULL,
    UNIQUE (lead_id, status, status_date)
);

CREATE TABLE core.orders (
    order_id VARCHAR(15) PRIMARY KEY,
    customer_id VARCHAR(12) NOT NULL REFERENCES core.customers(customer_id),
    sales_rep_id VARCHAR(10) NOT NULL REFERENCES core.sales_representatives(sales_rep_id),
    lead_id VARCHAR(15) REFERENCES core.leads(lead_id),
    order_date DATE NOT NULL,
    order_status VARCHAR(20) NOT NULL
        CHECK (order_status IN ('Completed', 'Pending', 'Cancelled')),
    discount NUMERIC(5,4) NOT NULL DEFAULT 0 CHECK (discount BETWEEN 0 AND 0.40)
);

CREATE TABLE core.order_items (
    order_item_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(15) NOT NULL REFERENCES core.orders(order_id),
    product_id VARCHAR(10) NOT NULL REFERENCES core.products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price > 0)
);
