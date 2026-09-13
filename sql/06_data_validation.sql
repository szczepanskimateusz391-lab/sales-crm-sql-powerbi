-- Row counts
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM core.customers
UNION ALL SELECT 'sales_representatives', COUNT(*) FROM core.sales_representatives
UNION ALL SELECT 'products', COUNT(*) FROM core.products
UNION ALL SELECT 'leads', COUNT(*) FROM core.leads
UNION ALL SELECT 'lead_status_history', COUNT(*) FROM core.lead_status_history
UNION ALL SELECT 'orders', COUNT(*) FROM core.orders
UNION ALL SELECT 'order_items', COUNT(*) FROM core.order_items
ORDER BY table_name;

-- Expected: no rows returned by the checks below.

-- Duplicate customer IDs
SELECT customer_id, COUNT(*)
FROM core.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Invalid lead relations
SELECT l.*
FROM core.leads l
LEFT JOIN core.customers c ON c.customer_id = l.customer_id
LEFT JOIN core.sales_representatives s ON s.sales_rep_id = l.sales_rep_id
WHERE c.customer_id IS NULL OR s.sales_rep_id IS NULL;

-- History records before lead creation
SELECT h.*
FROM core.lead_status_history h
JOIN core.leads l ON l.lead_id = h.lead_id
WHERE h.status_date < l.created_date;

-- Invalid product margins
SELECT *
FROM core.products
WHERE unit_price < unit_cost OR unit_price <= 0 OR unit_cost < 0;

-- Invalid order items
SELECT *
FROM core.order_items
WHERE quantity <= 0 OR unit_price <= 0;

-- Orders linked to leads belonging to another customer
SELECT o.*
FROM core.orders o
JOIN core.leads l ON l.lead_id = o.lead_id
WHERE o.customer_id <> l.customer_id;
