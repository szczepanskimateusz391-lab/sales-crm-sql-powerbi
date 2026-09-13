TRUNCATE
    core.order_items,
    core.orders,
    core.lead_status_history,
    core.leads,
    core.products,
    core.sales_representatives,
    core.customers
CASCADE;

-- 1. Customers
WITH prepared AS (
    SELECT
        TRIM(customer_id) AS customer_id,
        INITCAP(TRIM(company_name)) AS company_name,
        INITCAP(TRIM(industry)) AS industry,
        INITCAP(TRIM(city)) AS city,
        CASE
            WHEN LOWER(TRIM(country)) IN ('poland', 'polska', 'pl') THEN 'Poland'
            ELSE INITCAP(TRIM(country))
        END AS country,
        CASE
            WHEN LOWER(TRIM(company_size)) = 'micro' THEN 'Micro'
            WHEN LOWER(TRIM(company_size)) = 'small' THEN 'Small'
            WHEN LOWER(TRIM(company_size)) = 'medium' THEN 'Medium'
            WHEN LOWER(TRIM(company_size)) = 'large' THEN 'Large'
            ELSE NULL
        END AS company_size,
        CASE
            WHEN TRIM(contact_email) ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'
                THEN LOWER(TRIM(contact_email))
            ELSE NULL
        END AS contact_email,
        CASE
            WHEN LENGTH(REGEXP_REPLACE(COALESCE(phone, ''), '[^0-9]', '', 'g')) >= 9
                THEN REGEXP_REPLACE(phone, '[^0-9+]', '', 'g')
            ELSE NULL
        END AS phone,
        CASE
            WHEN TRIM(created_date) ~ '^\d{4}-\d{2}-\d{2}$' THEN TRIM(created_date)::DATE
            WHEN TRIM(created_date) ~ '^\d{2}\.\d{2}\.\d{4}$' THEN TO_DATE(TRIM(created_date), 'DD.MM.YYYY')
            WHEN TRIM(created_date) ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(TRIM(created_date), 'DD/MM/YYYY')
            WHEN TRIM(created_date) ~ '^\d{4}/\d{2}/\d{2}$' THEN TO_DATE(TRIM(created_date), 'YYYY/MM/DD')
            ELSE NULL
        END AS created_date,
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(customer_id)
            ORDER BY
                CASE
                    WHEN TRIM(created_date) ~ '^\d{4}-\d{2}-\d{2}$' THEN TRIM(created_date)::DATE
                    WHEN TRIM(created_date) ~ '^\d{2}\.\d{2}\.\d{4}$' THEN TO_DATE(TRIM(created_date), 'DD.MM.YYYY')
                    WHEN TRIM(created_date) ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(TRIM(created_date), 'DD/MM/YYYY')
                    WHEN TRIM(created_date) ~ '^\d{4}/\d{2}/\d{2}$' THEN TO_DATE(TRIM(created_date), 'YYYY/MM/DD')
                    ELSE NULL
                END DESC NULLS LAST
        ) AS rn
    FROM staging.customers_raw
)
INSERT INTO core.customers (
    customer_id, company_name, industry, city, country,
    company_size, contact_email, phone, created_date
)
SELECT
    customer_id, company_name, industry, city, country,
    company_size, contact_email, phone, created_date
FROM prepared
WHERE rn = 1
  AND customer_id ~ '^C[0-9]{6}$'
  AND company_name IS NOT NULL
  AND industry IS NOT NULL
  AND city IS NOT NULL
  AND company_size IS NOT NULL
  AND created_date IS NOT NULL;

-- 2. Sales representatives
WITH prepared AS (
    SELECT
        TRIM(sales_rep_id) AS sales_rep_id,
        INITCAP(TRIM(first_name)) AS first_name,
        INITCAP(TRIM(last_name)) AS last_name,
        INITCAP(TRIM(region)) AS region,
        CASE
            WHEN LOWER(TRIM(team)) = 'smb' THEN 'SMB'
            WHEN LOWER(TRIM(team)) IN ('mid-market', 'mid market') THEN 'Mid-Market'
            WHEN LOWER(TRIM(team)) = 'enterprise' THEN 'Enterprise'
            ELSE NULL
        END AS team,
        CASE
            WHEN TRIM(hire_date) ~ '^\d{4}-\d{2}-\d{2}$' THEN TRIM(hire_date)::DATE
            WHEN TRIM(hire_date) ~ '^\d{2}\.\d{2}\.\d{4}$' THEN TO_DATE(TRIM(hire_date), 'DD.MM.YYYY')
            WHEN TRIM(hire_date) ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(TRIM(hire_date), 'DD/MM/YYYY')
            WHEN TRIM(hire_date) ~ '^\d{4}/\d{2}/\d{2}$' THEN TO_DATE(TRIM(hire_date), 'YYYY/MM/DD')
            ELSE NULL
        END AS hire_date
    FROM staging.sales_representatives_raw
)
INSERT INTO core.sales_representatives
SELECT *
FROM prepared
WHERE sales_rep_id ~ '^SR[0-9]{3}$'
  AND first_name IS NOT NULL
  AND last_name IS NOT NULL
  AND region IS NOT NULL
  AND team IS NOT NULL
  AND hire_date IS NOT NULL;

-- 3. Products
WITH prepared AS (
    SELECT
        TRIM(product_id) AS product_id,
        INITCAP(TRIM(product_name)) AS product_name,
        INITCAP(TRIM(category)) AS category,
        CASE
            WHEN REPLACE(TRIM(unit_price), ',', '.') ~ '^[0-9]+(\.[0-9]+)?$'
                THEN REPLACE(TRIM(unit_price), ',', '.')::NUMERIC(12,2)
            ELSE NULL
        END AS unit_price,
        CASE
            WHEN REPLACE(TRIM(unit_cost), ',', '.') ~ '^[0-9]+(\.[0-9]+)?$'
                THEN REPLACE(TRIM(unit_cost), ',', '.')::NUMERIC(12,2)
            ELSE NULL
        END AS unit_cost
    FROM staging.products_raw
)
INSERT INTO core.products
SELECT *
FROM prepared
WHERE product_id ~ '^P[0-9]{3}$'
  AND product_name IS NOT NULL
  AND category IS NOT NULL
  AND unit_price > 0
  AND unit_cost >= 0
  AND unit_price >= unit_cost;

-- 4. Leads
WITH prepared AS (
    SELECT
        TRIM(lead_id) AS lead_id,
        TRIM(customer_id) AS customer_id,
        TRIM(sales_rep_id) AS sales_rep_id,
        CASE
            WHEN LOWER(TRIM(lead_source)) IN ('linkedin', 'linked in') THEN 'LinkedIn'
            WHEN LOWER(TRIM(lead_source)) IN ('google ads', 'google', 'adwords') THEN 'Google Ads'
            WHEN LOWER(TRIM(lead_source)) IN ('website', 'web', 'organic') THEN 'Website'
            WHEN LOWER(TRIM(lead_source)) IN ('referral', 'recommendation', 'polecenie') THEN 'Referral'
            WHEN LOWER(TRIM(lead_source)) IN ('cold email', 'outbound') THEN 'Cold Email'
            WHEN LOWER(TRIM(lead_source)) IN ('trade show', 'event', 'conference') THEN 'Trade Show'
            ELSE NULL
        END AS lead_source,
        CASE
            WHEN LOWER(TRIM(lead_status)) = 'new' THEN 'New'
            WHEN LOWER(TRIM(lead_status)) = 'contacted' THEN 'Contacted'
            WHEN LOWER(TRIM(lead_status)) = 'qualified' THEN 'Qualified'
            WHEN LOWER(TRIM(lead_status)) = 'proposal' THEN 'Proposal'
            WHEN LOWER(TRIM(lead_status)) = 'won' THEN 'Won'
            WHEN LOWER(TRIM(lead_status)) = 'lost' THEN 'Lost'
            ELSE NULL
        END AS lead_status,
        CASE
            WHEN TRIM(created_date) ~ '^\d{4}-\d{2}-\d{2}$' THEN TRIM(created_date)::DATE
            WHEN TRIM(created_date) ~ '^\d{2}\.\d{2}\.\d{4}$' THEN TO_DATE(TRIM(created_date), 'DD.MM.YYYY')
            WHEN TRIM(created_date) ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(TRIM(created_date), 'DD/MM/YYYY')
            WHEN TRIM(created_date) ~ '^\d{4}/\d{2}/\d{2}$' THEN TO_DATE(TRIM(created_date), 'YYYY/MM/DD')
            ELSE NULL
        END AS created_date,
        CASE
            WHEN NULLIF(TRIM(closed_date), '') IS NULL THEN NULL
            WHEN TRIM(closed_date) ~ '^\d{4}-\d{2}-\d{2}$' THEN TRIM(closed_date)::DATE
            WHEN TRIM(closed_date) ~ '^\d{2}\.\d{2}\.\d{4}$' THEN TO_DATE(TRIM(closed_date), 'DD.MM.YYYY')
            WHEN TRIM(closed_date) ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(TRIM(closed_date), 'DD/MM/YYYY')
            WHEN TRIM(closed_date) ~ '^\d{4}/\d{2}/\d{2}$' THEN TO_DATE(TRIM(closed_date), 'YYYY/MM/DD')
            ELSE NULL
        END AS closed_date,
        CASE
            WHEN REPLACE(TRIM(estimated_value), ',', '.') ~ '^[0-9]+(\.[0-9]+)?$'
                THEN REPLACE(TRIM(estimated_value), ',', '.')::NUMERIC(14,2)
            ELSE NULL
        END AS estimated_value
    FROM staging.leads_raw
)
INSERT INTO core.leads (
    lead_id, customer_id, sales_rep_id, lead_source, lead_status,
    created_date, closed_date, estimated_value
)
SELECT
    p.lead_id, p.customer_id, p.sales_rep_id, p.lead_source, p.lead_status,
    p.created_date, p.closed_date, p.estimated_value
FROM prepared p
JOIN core.customers c ON c.customer_id = p.customer_id
JOIN core.sales_representatives s ON s.sales_rep_id = p.sales_rep_id
WHERE p.lead_id ~ '^L[0-9]{7}$'
  AND p.lead_source IS NOT NULL
  AND p.lead_status IS NOT NULL
  AND p.created_date IS NOT NULL
  AND p.estimated_value IS NOT NULL
  AND (p.closed_date IS NULL OR p.closed_date >= p.created_date);

-- 5. Lead status history
WITH prepared AS (
    SELECT
        TRIM(lead_history_id) AS lead_history_id,
        TRIM(lead_id) AS lead_id,
        CASE
            WHEN LOWER(TRIM(status)) = 'new' THEN 'New'
            WHEN LOWER(TRIM(status)) = 'contacted' THEN 'Contacted'
            WHEN LOWER(TRIM(status)) = 'qualified' THEN 'Qualified'
            WHEN LOWER(TRIM(status)) = 'proposal' THEN 'Proposal'
            WHEN LOWER(TRIM(status)) = 'won' THEN 'Won'
            WHEN LOWER(TRIM(status)) = 'lost' THEN 'Lost'
            ELSE NULL
        END AS status,
        CASE
            WHEN TRIM(status_date) ~ '^\d{4}-\d{2}-\d{2}$' THEN TRIM(status_date)::DATE
            WHEN TRIM(status_date) ~ '^\d{2}\.\d{2}\.\d{4}$' THEN TO_DATE(TRIM(status_date), 'DD.MM.YYYY')
            WHEN TRIM(status_date) ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(TRIM(status_date), 'DD/MM/YYYY')
            WHEN TRIM(status_date) ~ '^\d{4}/\d{2}/\d{2}$' THEN TO_DATE(TRIM(status_date), 'YYYY/MM/DD')
            ELSE NULL
        END AS status_date
    FROM staging.lead_status_history_raw
)
INSERT INTO core.lead_status_history
SELECT p.*
FROM prepared p
JOIN core.leads l ON l.lead_id = p.lead_id
WHERE p.lead_history_id ~ '^LH[0-9]{8}$'
  AND p.status IS NOT NULL
  AND p.status_date IS NOT NULL;

-- 6. Orders
WITH prepared AS (
    SELECT
        TRIM(order_id) AS order_id,
        TRIM(customer_id) AS customer_id,
        TRIM(sales_rep_id) AS sales_rep_id,
        NULLIF(TRIM(lead_id), '') AS lead_id,
        CASE
            WHEN TRIM(order_date) ~ '^\d{4}-\d{2}-\d{2}$' THEN TRIM(order_date)::DATE
            WHEN TRIM(order_date) ~ '^\d{2}\.\d{2}\.\d{4}$' THEN TO_DATE(TRIM(order_date), 'DD.MM.YYYY')
            WHEN TRIM(order_date) ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(TRIM(order_date), 'DD/MM/YYYY')
            WHEN TRIM(order_date) ~ '^\d{4}/\d{2}/\d{2}$' THEN TO_DATE(TRIM(order_date), 'YYYY/MM/DD')
            ELSE NULL
        END AS order_date,
        CASE
            WHEN LOWER(TRIM(order_status)) IN ('completed', 'complete', 'done') THEN 'Completed'
            WHEN LOWER(TRIM(order_status)) = 'pending' THEN 'Pending'
            WHEN LOWER(TRIM(order_status)) IN ('cancelled', 'canceled') THEN 'Cancelled'
            ELSE NULL
        END AS order_status,
        CASE
            WHEN REPLACE(REPLACE(TRIM(discount), '%', ''), ',', '.') ~ '^[0-9]+(\.[0-9]+)?$'
            THEN
                CASE
                    WHEN POSITION('%' IN TRIM(discount)) > 0
                        THEN REPLACE(REPLACE(TRIM(discount), '%', ''), ',', '.')::NUMERIC / 100
                    WHEN REPLACE(TRIM(discount), ',', '.')::NUMERIC > 1
                        THEN REPLACE(TRIM(discount), ',', '.')::NUMERIC / 100
                    ELSE REPLACE(TRIM(discount), ',', '.')::NUMERIC
                END
            ELSE NULL
        END AS discount
    FROM staging.orders_raw
)
INSERT INTO core.orders (
    order_id, customer_id, sales_rep_id, lead_id,
    order_date, order_status, discount
)
SELECT
    p.order_id, p.customer_id, p.sales_rep_id, p.lead_id,
    p.order_date, p.order_status, p.discount
FROM prepared p
JOIN core.customers c ON c.customer_id = p.customer_id
JOIN core.sales_representatives s ON s.sales_rep_id = p.sales_rep_id
LEFT JOIN core.leads l ON l.lead_id = p.lead_id
WHERE p.order_id ~ '^O[0-9]{7}$'
  AND p.order_date IS NOT NULL
  AND p.order_status IS NOT NULL
  AND p.discount BETWEEN 0 AND 0.40
  AND (p.lead_id IS NULL OR l.lead_id IS NOT NULL);

-- 7. Order items
WITH prepared AS (
    SELECT
        TRIM(order_item_id) AS order_item_id,
        TRIM(order_id) AS order_id,
        TRIM(product_id) AS product_id,
        CASE
            WHEN TRIM(quantity) ~ '^[0-9]+$' THEN TRIM(quantity)::INTEGER
            ELSE NULL
        END AS quantity,
        CASE
            WHEN REPLACE(TRIM(unit_price), ',', '.') ~ '^[0-9]+(\.[0-9]+)?$'
                THEN REPLACE(TRIM(unit_price), ',', '.')::NUMERIC(12,2)
            ELSE NULL
        END AS unit_price
    FROM staging.order_items_raw
)
INSERT INTO core.order_items (
    order_item_id, order_id, product_id, quantity, unit_price
)
SELECT
    p.order_item_id, p.order_id, p.product_id, p.quantity, p.unit_price
FROM prepared p
JOIN core.orders o ON o.order_id = p.order_id
JOIN core.products pr ON pr.product_id = p.product_id
WHERE p.order_item_id ~ '^OI[0-9]{8}$'
  AND p.quantity > 0
  AND p.unit_price > 0;
