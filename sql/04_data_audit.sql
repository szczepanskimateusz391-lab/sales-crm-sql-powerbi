TRUNCATE quality.issue_log RESTART IDENTITY;

-- Duplicate customer IDs
INSERT INTO quality.issue_log (table_name, record_id, issue_type, raw_value)
SELECT
    'customers_raw',
    TRIM(customer_id),
    'DUPLICATE_CUSTOMER_ID',
    COUNT(*)::TEXT
FROM staging.customers_raw
GROUP BY TRIM(customer_id)
HAVING COUNT(*) > 1;

-- Invalid customer emails
INSERT INTO quality.issue_log (table_name, record_id, issue_type, raw_value)
SELECT
    'customers_raw',
    TRIM(customer_id),
    'INVALID_EMAIL',
    contact_email
FROM staging.customers_raw
WHERE NULLIF(TRIM(contact_email), '') IS NOT NULL
  AND TRIM(contact_email) !~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$';

-- Missing phones
INSERT INTO quality.issue_log (table_name, record_id, issue_type, raw_value)
SELECT
    'customers_raw',
    TRIM(customer_id),
    'MISSING_PHONE',
    phone
FROM staging.customers_raw
WHERE NULLIF(TRIM(phone), '') IS NULL;

-- Invalid products
WITH product_check AS (
    SELECT
        TRIM(product_id) AS product_id,
        unit_price,
        unit_cost,
        CASE
            WHEN REPLACE(TRIM(unit_price), ',', '.') ~ '^[0-9]+(\.[0-9]+)?$'
                THEN REPLACE(TRIM(unit_price), ',', '.')::NUMERIC
            ELSE NULL
        END AS parsed_price,
        CASE
            WHEN REPLACE(TRIM(unit_cost), ',', '.') ~ '^[0-9]+(\.[0-9]+)?$'
                THEN REPLACE(TRIM(unit_cost), ',', '.')::NUMERIC
            ELSE NULL
        END AS parsed_cost
    FROM staging.products_raw
)
INSERT INTO quality.issue_log (table_name, record_id, issue_type, raw_value)
SELECT
    'products_raw',
    product_id,
    'INVALID_PRODUCT_PRICE_OR_MARGIN',
    CONCAT('price=', unit_price, '; cost=', unit_cost)
FROM product_check
WHERE parsed_price IS NULL
   OR parsed_cost IS NULL
   OR parsed_price <= 0
   OR parsed_cost < 0
   OR parsed_price < parsed_cost;

-- Orphan / malformed leads
INSERT INTO quality.issue_log (table_name, record_id, issue_type, raw_value)
SELECT
    'leads_raw',
    TRIM(lead_id),
    'MISSING_OR_INVALID_RELATION',
    CONCAT('customer=', customer_id, '; rep=', sales_rep_id)
FROM staging.leads_raw l
WHERE NULLIF(TRIM(l.sales_rep_id), '') IS NULL
   OR NOT EXISTS (
        SELECT 1
        FROM staging.customers_raw c
        WHERE TRIM(c.customer_id) = TRIM(l.customer_id)
   )
   OR NOT EXISTS (
        SELECT 1
        FROM staging.sales_representatives_raw s
        WHERE TRIM(s.sales_rep_id) = TRIM(l.sales_rep_id)
   );

-- Invalid order items
WITH item_check AS (
    SELECT
        TRIM(order_item_id) AS order_item_id,
        order_id,
        product_id,
        quantity,
        unit_price,
        CASE
            WHEN TRIM(quantity) ~ '^[0-9]+$'
                THEN TRIM(quantity)::INTEGER
            ELSE NULL
        END AS parsed_quantity,
        CASE
            WHEN REPLACE(TRIM(unit_price), ',', '.') ~ '^[0-9]+(\.[0-9]+)?$'
                THEN REPLACE(TRIM(unit_price), ',', '.')::NUMERIC
            ELSE NULL
        END AS parsed_unit_price
    FROM staging.order_items_raw
)
INSERT INTO quality.issue_log (table_name, record_id, issue_type, raw_value)
SELECT
    'order_items_raw',
    order_item_id,
    'INVALID_ORDER_ITEM',
    CONCAT('order=', order_id, '; product=', product_id, '; qty=', quantity, '; price=', unit_price)
FROM item_check
WHERE parsed_quantity IS NULL
   OR parsed_quantity <= 0
   OR parsed_unit_price IS NULL
   OR parsed_unit_price <= 0;

-- Audit summary
SELECT issue_type, COUNT(*) AS issue_count
FROM quality.issue_log
GROUP BY issue_type
ORDER BY issue_count DESC;
