-- 1. Executive KPIs
SELECT
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS total_revenue,
    ROUND(SUM(oi.quantity * p.unit_cost), 2) AS total_cost,
    ROUND(SUM(oi.quantity * (oi.unit_price * (1 - o.discount) - p.unit_cost)), 2) AS total_profit,
    ROUND(
        100.0 * SUM(oi.quantity * (oi.unit_price * (1 - o.discount) - p.unit_cost))
        / NULLIF(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 0),
        2
    ) AS profit_margin_pct,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - o.discount))
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS average_order_value
FROM core.orders o
JOIN core.order_items oi ON oi.order_id = o.order_id
JOIN core.products p ON p.product_id = oi.product_id
WHERE o.order_status = 'Completed';

-- 2. Monthly revenue
SELECT
    DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS revenue
FROM core.orders o
JOIN core.order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY sales_month;

-- 3. Revenue and profit by category
SELECT
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price * (1 - o.discount) - p.unit_cost)), 2) AS profit
FROM core.orders o
JOIN core.order_items oi ON oi.order_id = o.order_id
JOIN core.products p ON p.product_id = oi.product_id
WHERE o.order_status = 'Completed'
GROUP BY p.category
ORDER BY revenue DESC;

-- 4. Top products
SELECT
    p.product_name,
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS revenue,
    SUM(oi.quantity) AS units_sold
FROM core.orders o
JOIN core.order_items oi ON oi.order_id = o.order_id
JOIN core.products p ON p.product_id = oi.product_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;

-- 5. Conversion rate by lead source
SELECT
    lead_source,
    COUNT(*) AS total_leads,
    COUNT(*) FILTER (WHERE lead_status = 'Won') AS won_leads,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE lead_status = 'Won')
        / NULLIF(COUNT(*), 0),
        2
    ) AS conversion_rate_pct
FROM core.leads
GROUP BY lead_source
ORDER BY conversion_rate_pct DESC;

-- 6. Sales representative performance
SELECT
    s.sales_rep_id,
    s.first_name || ' ' || s.last_name AS sales_rep,
    s.region,
    s.team,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS revenue
FROM core.sales_representatives s
JOIN core.orders o ON o.sales_rep_id = s.sales_rep_id
JOIN core.order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY s.sales_rep_id, s.first_name, s.last_name, s.region, s.team
ORDER BY revenue DESC;

-- 7. Revenue by industry
SELECT
    c.industry,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS revenue
FROM core.customers c
JOIN core.orders o ON o.customer_id = c.customer_id
JOIN core.order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY c.industry
ORDER BY revenue DESC;

-- 8. Customers without an order
SELECT
    c.customer_id,
    c.company_name,
    c.industry,
    c.company_size
FROM core.customers c
LEFT JOIN core.orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.company_name;

-- 9. Average sales cycle by source
SELECT
    lead_source,
    ROUND(AVG(closed_date - created_date), 1) AS average_days_to_close
FROM core.leads
WHERE lead_status = 'Won'
  AND closed_date IS NOT NULL
GROUP BY lead_source
ORDER BY average_days_to_close;

-- 10. Current pipeline value
SELECT
    lead_status,
    COUNT(*) AS leads,
    ROUND(SUM(estimated_value), 2) AS estimated_pipeline_value
FROM core.leads
WHERE lead_status IN ('New', 'Contacted', 'Qualified', 'Proposal')
GROUP BY lead_status
ORDER BY
    CASE lead_status
        WHEN 'New' THEN 1
        WHEN 'Contacted' THEN 2
        WHEN 'Qualified' THEN 3
        WHEN 'Proposal' THEN 4
    END;
