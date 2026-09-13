CREATE INDEX IF NOT EXISTS idx_leads_customer_id
    ON core.leads(customer_id);

CREATE INDEX IF NOT EXISTS idx_leads_sales_rep_id
    ON core.leads(sales_rep_id);

CREATE INDEX IF NOT EXISTS idx_leads_source_status
    ON core.leads(lead_source, lead_status);

CREATE INDEX IF NOT EXISTS idx_leads_created_date
    ON core.leads(created_date);

CREATE INDEX IF NOT EXISTS idx_history_lead_date
    ON core.lead_status_history(lead_id, status_date);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id
    ON core.orders(customer_id);

CREATE INDEX IF NOT EXISTS idx_orders_sales_rep_id
    ON core.orders(sales_rep_id);

CREATE INDEX IF NOT EXISTS idx_orders_order_date
    ON core.orders(order_date);

CREATE INDEX IF NOT EXISTS idx_orders_status
    ON core.orders(order_status);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id
    ON core.order_items(order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id
    ON core.order_items(product_id);

ANALYZE core.customers;
ANALYZE core.sales_representatives;
ANALYZE core.products;
ANALYZE core.leads;
ANALYZE core.lead_status_history;
ANALYZE core.orders;
ANALYZE core.order_items;

-- Example performance check
EXPLAIN ANALYZE
SELECT
    o.order_date,
    o.order_id,
    o.customer_id
FROM core.orders o
WHERE o.order_status = 'Completed'
  AND o.order_date >= DATE '2026-01-01';
