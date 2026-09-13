CREATE OR REPLACE VIEW analytics.vw_sales_details AS
SELECT
    o.order_id,
    o.order_date,
    o.order_status,
    o.discount,
    c.customer_id,
    c.company_name,
    c.industry,
    c.city,
    c.company_size,
    s.sales_rep_id,
    s.first_name || ' ' || s.last_name AS sales_rep,
    s.region,
    s.team,
    l.lead_id,
    l.lead_source,
    p.product_id,
    p.product_name,
    p.category,
    oi.quantity,
    oi.unit_price,
    ROUND(oi.quantity * oi.unit_price * (1 - o.discount), 2) AS revenue,
    ROUND(oi.quantity * p.unit_cost, 2) AS total_cost,
    ROUND(oi.quantity * (oi.unit_price * (1 - o.discount) - p.unit_cost), 2) AS profit
FROM core.orders o
JOIN core.order_items oi ON oi.order_id = o.order_id
JOIN core.customers c ON c.customer_id = o.customer_id
JOIN core.sales_representatives s ON s.sales_rep_id = o.sales_rep_id
JOIN core.products p ON p.product_id = oi.product_id
LEFT JOIN core.leads l ON l.lead_id = o.lead_id;

CREATE OR REPLACE VIEW analytics.vw_monthly_sales AS
SELECT
    DATE_TRUNC('month', order_date)::DATE AS sales_month,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(total_cost), 2) AS total_cost,
    ROUND(SUM(profit), 2) AS profit,
    COUNT(DISTINCT order_id) AS orders
FROM analytics.vw_sales_details
WHERE order_status = 'Completed'
GROUP BY DATE_TRUNC('month', order_date);

CREATE OR REPLACE VIEW analytics.vw_sales_rep_performance AS
WITH lead_metrics AS (
    SELECT
        sales_rep_id,
        COUNT(*) AS assigned_leads,
        COUNT(*) FILTER (WHERE lead_status = 'Won') AS won_leads,
        ROUND(
            100.0 * COUNT(*) FILTER (WHERE lead_status = 'Won')
            / NULLIF(COUNT(*), 0),
            2
        ) AS lead_conversion_rate_pct
    FROM core.leads
    GROUP BY sales_rep_id
),
sales_metrics AS (
    SELECT
        o.sales_rep_id,
        COUNT(DISTINCT o.order_id)
            FILTER (WHERE o.order_status = 'Completed') AS completed_orders,
        ROUND(
            COALESCE(
                SUM(oi.quantity * oi.unit_price * (1 - o.discount))
                    FILTER (WHERE o.order_status = 'Completed'),
                0
            ),
            2
        ) AS revenue,
        ROUND(
            COALESCE(
                SUM(oi.quantity * (oi.unit_price * (1 - o.discount) - p.unit_cost))
                    FILTER (WHERE o.order_status = 'Completed'),
                0
            ),
            2
        ) AS profit
    FROM core.orders o
    JOIN core.order_items oi ON oi.order_id = o.order_id
    JOIN core.products p ON p.product_id = oi.product_id
    GROUP BY o.sales_rep_id
)
SELECT
    s.sales_rep_id,
    s.first_name || ' ' || s.last_name AS sales_rep,
    s.region,
    s.team,
    COALESCE(lm.assigned_leads, 0) AS assigned_leads,
    COALESCE(lm.won_leads, 0) AS won_leads,
    COALESCE(lm.lead_conversion_rate_pct, 0) AS lead_conversion_rate_pct,
    COALESCE(sm.completed_orders, 0) AS completed_orders,
    COALESCE(sm.revenue, 0) AS revenue,
    COALESCE(sm.profit, 0) AS profit
FROM core.sales_representatives s
LEFT JOIN lead_metrics lm ON lm.sales_rep_id = s.sales_rep_id
LEFT JOIN sales_metrics sm ON sm.sales_rep_id = s.sales_rep_id;

CREATE OR REPLACE VIEW analytics.vw_lead_source_performance AS
WITH lead_metrics AS (
    SELECT
        lead_source,
        COUNT(*) AS total_leads,
        COUNT(*) FILTER (WHERE lead_status = 'Won') AS won_leads,
        ROUND(
            100.0 * COUNT(*) FILTER (WHERE lead_status = 'Won')
            / NULLIF(COUNT(*), 0),
            2
        ) AS conversion_rate_pct,
        ROUND(
            AVG(closed_date - created_date)
                FILTER (WHERE lead_status = 'Won'),
            1
        ) AS average_days_to_win
    FROM core.leads
    GROUP BY lead_source
),
sales_metrics AS (
    SELECT
        l.lead_source,
        COUNT(DISTINCT o.order_id)
            FILTER (WHERE o.order_status = 'Completed') AS completed_first_orders,
        ROUND(
            COALESCE(
                SUM(oi.quantity * oi.unit_price * (1 - o.discount))
                    FILTER (WHERE o.order_status = 'Completed'),
                0
            ),
            2
        ) AS attributed_revenue
    FROM core.leads l
    LEFT JOIN core.orders o ON o.lead_id = l.lead_id
    LEFT JOIN core.order_items oi ON oi.order_id = o.order_id
    GROUP BY l.lead_source
)
SELECT
    lm.lead_source,
    lm.total_leads,
    lm.won_leads,
    lm.conversion_rate_pct,
    lm.average_days_to_win,
    COALESCE(sm.completed_first_orders, 0) AS completed_first_orders,
    COALESCE(sm.attributed_revenue, 0) AS attributed_revenue
FROM lead_metrics lm
LEFT JOIN sales_metrics sm ON sm.lead_source = lm.lead_source;

CREATE OR REPLACE VIEW analytics.vw_customer_value AS
SELECT
    c.customer_id,
    c.company_name,
    c.industry,
    c.city,
    c.company_size,
    COUNT(DISTINCT o.order_id)
        FILTER (WHERE o.order_status = 'Completed') AS completed_orders,
    MIN(o.order_date)
        FILTER (WHERE o.order_status = 'Completed') AS first_order_date,
    MAX(o.order_date)
        FILTER (WHERE o.order_status = 'Completed') AS last_order_date,
    ROUND(
        COALESCE(
            SUM(oi.quantity * oi.unit_price * (1 - o.discount))
                FILTER (WHERE o.order_status = 'Completed'),
            0
        ),
        2
    ) AS lifetime_revenue,
    ROUND(
        COALESCE(
            SUM(oi.quantity * (oi.unit_price * (1 - o.discount) - p.unit_cost))
                FILTER (WHERE o.order_status = 'Completed'),
            0
        ),
        2
    ) AS lifetime_profit
FROM core.customers c
LEFT JOIN core.orders o ON o.customer_id = c.customer_id
LEFT JOIN core.order_items oi ON oi.order_id = o.order_id
LEFT JOIN core.products p ON p.product_id = oi.product_id
GROUP BY c.customer_id, c.company_name, c.industry, c.city, c.company_size;

CREATE OR REPLACE VIEW analytics.vw_pipeline_stage_performance AS
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
)
SELECT
    status,
    leads_reaching_stage,
    stage_order,
    ROUND(
        100.0 * leads_reaching_stage
        / NULLIF(LAG(leads_reaching_stage) OVER (ORDER BY stage_order), 0),
        2
    ) AS conversion_from_previous_stage_pct
FROM ordered;

CREATE OR REPLACE VIEW analytics.vw_lead_stage_durations AS
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
    lead_id,
    status,
    status_date,
    next_status_date,
    next_status_date - status_date AS days_in_stage
FROM ordered_history;
