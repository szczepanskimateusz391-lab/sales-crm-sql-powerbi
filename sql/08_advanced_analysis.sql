-- 1. Month-over-month revenue growth and running total
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
        SUM(oi.quantity * oi.unit_price * (1 - o.discount)) AS revenue
    FROM core.orders o
    JOIN core.order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', o.order_date)
),
with_previous AS (
    SELECT
        sales_month,
        revenue,
        LAG(revenue) OVER (ORDER BY sales_month) AS previous_month_revenue,
        SUM(revenue) OVER (ORDER BY sales_month) AS running_revenue
    FROM monthly_sales
)
SELECT
    sales_month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        100.0 * (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS month_over_month_growth_pct,
    ROUND(running_revenue, 2) AS running_revenue
FROM with_previous
ORDER BY sales_month;

-- 2. Ranking sales representatives
WITH rep_sales AS (
    SELECT
        s.sales_rep_id,
        s.first_name || ' ' || s.last_name AS sales_rep,
        SUM(oi.quantity * oi.unit_price * (1 - o.discount)) AS revenue
    FROM core.sales_representatives s
    JOIN core.orders o ON o.sales_rep_id = s.sales_rep_id
    JOIN core.order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY s.sales_rep_id, s.first_name, s.last_name
)
SELECT
    sales_rep_id,
    sales_rep,
    ROUND(revenue, 2) AS revenue,
    DENSE_RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2) AS revenue_share_pct
FROM rep_sales
ORDER BY revenue_rank;

-- 3. Top 3 products in each category
WITH product_sales AS (
    SELECT
        p.category,
        p.product_name,
        SUM(oi.quantity * oi.unit_price * (1 - o.discount)) AS revenue
    FROM core.products p
    JOIN core.order_items oi ON oi.product_id = p.product_id
    JOIN core.orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY p.category, p.product_name
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY revenue DESC
        ) AS category_rank
    FROM product_sales
)
SELECT
    category,
    product_name,
    ROUND(revenue, 2) AS revenue,
    category_rank
FROM ranked
WHERE category_rank <= 3
ORDER BY category, category_rank;

-- 4. Stage-to-stage conversion based on status history
WITH stage_counts AS (
    SELECT
        status,
        COUNT(DISTINCT lead_id) AS leads_reaching_stage
    FROM core.lead_status_history
    WHERE status IN ('New', 'Contacted', 'Qualified', 'Proposal', 'Won')
    GROUP BY status
),
ordered AS (
    SELECT
        status,
        leads_reaching_stage,
        CASE status
            WHEN 'New' THEN 1
            WHEN 'Contacted' THEN 2
            WHEN 'Qualified' THEN 3
            WHEN 'Proposal' THEN 4
            WHEN 'Won' THEN 5
        END AS stage_order
    FROM stage_counts
),
with_previous AS (
    SELECT
        *,
        LAG(leads_reaching_stage) OVER (ORDER BY stage_order) AS previous_stage_leads
    FROM ordered
)
SELECT
    status,
    leads_reaching_stage,
    ROUND(
        100.0 * leads_reaching_stage
        / NULLIF(previous_stage_leads, 0),
        2
    ) AS conversion_from_previous_stage_pct
FROM with_previous
ORDER BY stage_order;

-- 5. Average time spent in each funnel stage
WITH ordered_history AS (
    SELECT
        lead_id,
        status,
        status_date,
        LEAD(status_date) OVER (
            PARTITION BY lead_id
            ORDER BY status_date
        ) AS next_status_date
    FROM core.lead_status_history
)
SELECT
    status,
    ROUND(AVG(next_status_date - status_date), 1) AS average_days_in_stage
FROM ordered_history
WHERE next_status_date IS NOT NULL
  AND status NOT IN ('Won', 'Lost')
GROUP BY status
ORDER BY
    CASE status
        WHEN 'New' THEN 1
        WHEN 'Contacted' THEN 2
        WHEN 'Qualified' THEN 3
        WHEN 'Proposal' THEN 4
    END;

-- 6. Discount bands and profitability
SELECT
    CASE
        WHEN o.discount = 0 THEN '0%'
        WHEN o.discount <= 0.05 THEN '1-5%'
        WHEN o.discount <= 0.10 THEN '6-10%'
        WHEN o.discount <= 0.15 THEN '11-15%'
        ELSE '16%+'
    END AS discount_band,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price * (1 - o.discount) - p.unit_cost)), 2) AS profit,
    ROUND(
        100.0 * SUM(oi.quantity * (oi.unit_price * (1 - o.discount) - p.unit_cost))
        / NULLIF(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 0),
        2
    ) AS margin_pct
FROM core.orders o
JOIN core.order_items oi ON oi.order_id = o.order_id
JOIN core.products p ON p.product_id = oi.product_id
WHERE o.order_status = 'Completed'
GROUP BY discount_band
ORDER BY MIN(o.discount);

-- 7. Repeat customer analysis
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(*) FILTER (WHERE order_status = 'Completed') AS completed_orders
    FROM core.orders
    GROUP BY customer_id
)
SELECT
    COUNT(*) FILTER (WHERE completed_orders = 1) AS one_time_customers,
    COUNT(*) FILTER (WHERE completed_orders >= 2) AS repeat_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE completed_orders >= 2)
        / NULLIF(COUNT(*) FILTER (WHERE completed_orders >= 1), 0),
        2
    ) AS repeat_customer_rate_pct
FROM customer_orders;

-- 8. Customer lifetime value ranking
WITH customer_value AS (
    SELECT
        c.customer_id,
        c.company_name,
        c.industry,
        COUNT(DISTINCT o.order_id) AS completed_orders,
        SUM(oi.quantity * oi.unit_price * (1 - o.discount)) AS lifetime_revenue,
        SUM(oi.quantity * (oi.unit_price * (1 - o.discount) - p.unit_cost)) AS lifetime_profit
    FROM core.customers c
    JOIN core.orders o ON o.customer_id = c.customer_id
    JOIN core.order_items oi ON oi.order_id = o.order_id
    JOIN core.products p ON p.product_id = oi.product_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.company_name, c.industry
)
SELECT
    *,
    DENSE_RANK() OVER (ORDER BY lifetime_revenue DESC) AS value_rank
FROM customer_value
ORDER BY value_rank
LIMIT 25;
