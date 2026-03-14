--1)data cleaning (views for table clean as well as dedup )

--product 
CREATE OR ALTER VIEW dbo.vw_dim_product_clean AS
SELECT
    p.product_id,
    p.product_nk,
    p.product_name,
    CASE
        WHEN LOWER(p.category_raw) LIKE '%fashion%' THEN 'Fashion'
        WHEN LOWER(p.category_raw) LIKE '%home%' THEN 'Home & Living'
        WHEN LOWER(p.category_raw) LIKE '%electronic%' THEN 'Electronics'
        WHEN LOWER(p.category_raw) LIKE '%beauty%' THEN 'Beauty'
        WHEN LOWER(p.category_raw) LIKE '%grocery%' THEN 'Grocery'
        ELSE 'Accessories'
    END AS category,
    p.subcategory_raw AS subcategory,
    p.vendor_id,
    p.list_price,
    p.standard_cost,
    p.is_active
FROM dbo.products p;
GO;

--customers 
CREATE OR ALTER VIEW dbo.vw_dim_customer_clean AS
SELECT
    c.customer_id,
    c.customer_nk,
    c.full_name,
    c.email,
    c.phone,
    CASE
        WHEN c.city_raw IN (N'BLR',N'Bangalore',N'Bengaluru') THEN N'Bengaluru'
        WHEN c.city_raw IN (N'DEL',N'Delhi') THEN N'Delhi'
        WHEN c.city_raw IN (N'MUM',N'Mumbai') THEN N'Mumbai'
        WHEN c.city_raw IN (N'HYD',N'Hyderabad') THEN N'Hyderabad'
        WHEN c.city_raw IN (N'CHN',N'Chennai') THEN N'Chennai'
        WHEN c.city_raw =  N'Pune' THEN N'Pune'
        ELSE N'Other'
    END AS city,
    c.state,
    c.signup_date,
    c.is_active
FROM dbo.customers c;
GO;

--orders 
CREATE OR ALTER VIEW dbo.vw_orders_dedup AS
WITH ranked AS (
    SELECT
        o.*,
        ROW_NUMBER() OVER (
            PARTITION BY o.order_number
            ORDER BY o.order_date ASC, o.order_id ASC
        ) AS rn
    FROM dbo.orders o
    WHERE o.order_number IS NOT NULL and o.order_number IS NOT NULL
)
SELECT *
FROM ranked
WHERE rn = 1;
GO;

--order item
CREATE OR ALTER VIEW dbo.vw_order_items_dedup AS
WITH ranked AS (
    SELECT
        oi.*,
        ROW_NUMBER() OVER (
            PARTITION BY oi.order_item_number
            ORDER BY oi.unit_price DESC, oi.order_item_id ASC
        ) AS rn
    FROM dbo.order_items oi
    WHERE oi.order_item_number IS NOT NULL
)
SELECT *
FROM ranked
WHERE rn = 1;
GO;

-- returns 
CREATE OR ALTER VIEW dbo.vw_returns_dedup_clean AS
WITH ranked AS (
    SELECT
        r.*,
        ROW_NUMBER() OVER (
            PARTITION BY r.order_item_id
            ORDER BY
                COALESCE(r.refund_amount,0) DESC,   -- keep biggest refund (finance-safe)
                r.refund_completed DESC,            -- prefer most “final” record
                r.refund_initiated DESC,
                r.return_requested DESC,
                r.return_id DESC
        ) AS rn
    FROM dbo.returns r
    WHERE r.order_item_id IS NOT NULL
)
SELECT
    return_id,
    order_item_id,
    return_requested,
    return_received,
    refund_initiated,
    refund_completed,
    CASE
        WHEN LOWER(reason_raw) LIKE '%damage%'   THEN 'Damaged'
        WHEN LOWER(reason_raw) LIKE '%size%'     THEN 'Wrong Size'
        WHEN LOWER(reason_raw) LIKE '%describe%' THEN 'Not as Described'
        WHEN LOWER(reason_raw) LIKE '%delay%'    THEN 'Late Delivery'
        WHEN LOWER(reason_raw) LIKE '%quality%'  THEN 'Quality Issue'
        ELSE 'Other'
    END AS return_reason,
    refund_amount,
    refund_sla_days
FROM ranked
WHERE rn = 1;
GO;

--shipment 
CREATE OR ALTER VIEW dbo.vw_fact_shipments_clean AS
SELECT
    s.shipment_id,
    s.order_id,

    o.order_date,
    DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS month_start,
    o.is_campaign,
    o.channel,
    o.marketing_channel,

    s.warehouse_id,
    w.warehouse_code,
    w.warehouse_city,

    s.carrier,
    s.shipment_status,
    s.promised_days,
    s.shipped_date,
    s.delivered_date,

    -- derived but NOT KPI
    CASE
        WHEN s.shipped_date IS NULL OR s.delivered_date IS NULL THEN NULL
        ELSE DATEDIFF(DAY, s.shipped_date, s.delivered_date)
    END AS transit_days,

    CASE
        WHEN s.shipped_date IS NULL 
          OR s.delivered_date IS NULL 
          OR s.promised_days IS NULL THEN NULL
        WHEN DATEDIFF(DAY, s.shipped_date, s.delivered_date) > s.promised_days THEN 1
        ELSE 0
    END AS is_late

FROM dbo.shipments s
INNER JOIN dbo.vw_orders_dedup o
    ON o.order_id = s.order_id
LEFT JOIN dbo.vw_dim_warehouse_clean w
    ON w.warehouse_id = s.warehouse_id
WHERE
    s.order_id IS NOT NULL
    AND o.order_date IS NOT NULL;
GO ;

-- warehouse 
CREATE OR ALTER VIEW dbo.vw_dim_warehouse_clean AS
SELECT
    w.warehouse_id,
    w.warehouse_code,
    CASE
        WHEN w.warehouse_city_raw IN (N'BLR',N'Bangalore',N'Bengaluru') THEN N'Bengaluru'
        WHEN w.warehouse_city_raw IN (N'DEL',N'Delhi') THEN N'Delhi'
        WHEN w.warehouse_city_raw IN (N'MUM',N'Mumbai') THEN N'Mumbai'
        WHEN w.warehouse_city_raw IN (N'HYD',N'Hyderabad') THEN N'Hyderabad'
        WHEN w.warehouse_city_raw IN (N'CHN',N'Chennai') THEN N'Chennai'
        WHEN w.warehouse_city_raw =  N'Pune' THEN N'Pune'
        ELSE N'Other'
    END AS warehouse_city,
    w.capacity_units
FROM dbo.warehouses w;
GO;



--2) Golden fact Finance Table

CREATE OR ALTER VIEW dbo.vw_fact_order_item_finance AS
SELECT
    oi.order_item_id,
    o.order_id,
    o.order_date,
    DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS month_start,

    o.customer_id,
    o.is_campaign,
    o.channel,
    o.marketing_channel,

    p.product_id,
    p.category,
    p.subcategory,
    p.vendor_id,

    COALESCE(oi.quantity, 0) AS quantity,
    COALESCE(oi.unit_price, 0) AS unit_price,
    COALESCE(oi.discount_pct, 0) AS discount_pct,

    -- Gross Sales
    COALESCE(oi.quantity, 0) * COALESCE(oi.unit_price, 0) AS gross_sales,

    -- Discount
    (COALESCE(oi.quantity, 0) * COALESCE(oi.unit_price, 0)) * COALESCE(oi.discount_pct, 0) AS discount_amount,

    -- Post-discount revenue (pre-refund) == your net_revenue
    (COALESCE(oi.quantity, 0) * COALESCE(oi.unit_price, 0)) * (1 - COALESCE(oi.discount_pct, 0)) AS net_revenue,

    -- Refunds (deduped)
    COALESCE(r.refund_amount, 0) AS refund_amount,

    -- Net Sales (your first query definition)
    (COALESCE(oi.quantity, 0) * COALESCE(oi.unit_price, 0))
    - ((COALESCE(oi.quantity, 0) * COALESCE(oi.unit_price, 0)) * COALESCE(oi.discount_pct, 0))
    - COALESCE(r.refund_amount, 0) AS net_sales,

    -- Variable cost (your second query)
    COALESCE(oi.quantity, 0) * COALESCE(p.standard_cost, 0) AS variable_cost,

    -- Contribution profit (your second query logic)
    ((COALESCE(oi.quantity, 0) * COALESCE(oi.unit_price, 0)) * (1 - COALESCE(oi.discount_pct, 0))
      - COALESCE(r.refund_amount, 0))
    - (COALESCE(oi.quantity, 0) * COALESCE(p.standard_cost, 0)) AS contribution_profit

FROM dbo.vw_order_items_dedup oi
INNER JOIN dbo.vw_orders_dedup o
    ON o.order_id = oi.order_id
INNER JOIN dbo.vw_dim_product_clean p
    ON p.product_id = oi.product_id
LEFT JOIN dbo.vw_returns_dedup_clean r
    ON r.order_item_id = oi.order_item_id
WHERE
    oi.item_status = 'Sold'
    AND o.order_date IS NOT NULL
    AND o.payment_status IN ('Paid','COD')
    AND o.order_status IN ('Shipped','Delivered');
GO

--3) EDA and Root Cause Analysis
  
--1) Monthly profit analysis 

-- a)Monthly trend decomposition 
SELECT
    month_start,
    sold_items,
    gross_sales,
    discount_amount,
    refunds,
    net_sales,
    variable_cost,
    contribution_profit,
    contribution_margin_pct
FROM dbo.vw_kpi_monthly_profit
ORDER BY month_start;

-- b)Leak share vs baseline 
;WITH m AS (
    SELECT *
    FROM dbo.vw_kpi_monthly_profit
), baseline AS (

    SELECT
        AVG(gross_sales)      AS gross_base,
        AVG(discount_amount)  AS discount_base,
        AVG(refunds)          AS refunds_base,
        AVG(net_sales)        AS net_sales_base,
        AVG(variable_cost)    AS var_cost_base,
        AVG(contribution_profit) AS profit_base
    FROM m
    WHERE month_start BETWEEN '2025-06-01' AND '2025-12-01'
) 
SELECT
    m.month_start,
    m.contribution_profit,
    b.profit_base,
    (m.contribution_profit - b.profit_base) AS profit_delta_vs_base,

    (m.discount_amount - b.discount_base) AS discount_delta,
    (m.refunds - b.refunds_base)          AS refunds_delta,
    (m.variable_cost - b.var_cost_base)   AS var_cost_delta,
    (m.net_sales - b.net_sales_base)      AS net_sales_delta
FROM m
CROSS JOIN baseline b
ORDER BY m.month_start;

--2) Why did refunds increase?

-- a)Refund ratio by month
SELECT
    month_start,
    refunds,
    net_sales,
    CAST(100.0 * refunds / NULLIF(net_sales,0) AS DECIMAL(8,2)) AS refunds_pct_of_net_sales
FROM dbo.vw_kpi_monthly_profit
ORDER BY month_start;

--b)refund rate by discount band 
SELECT 
    Month_start,
    CASE 
        WHEN discount_amount / NULLIF(gross_sales,0) < 0.10 THEN '0-10%'
        WHEN discount_amount / NULLIF(gross_sales,0) < 0.20 THEN '10-20%'
        WHEN discount_amount / NULLIF(gross_sales,0) < 0.30 THEN '20-30%'
        ELSE '30%+'
    END AS discount_band,

    COUNT(*) AS orders,
    
    SUM(refund_amount) AS total_refunds,
    
    SUM(net_sales) AS total_net_sales,
    
    ROUND(
        100.0 * SUM(refund_amount) / NULLIF(SUM(net_sales),0),
        2
    ) AS refund_rate_pct

FROM vw_fact_order_item_finance

GROUP BY month_start,
    CASE 
        WHEN discount_amount / NULLIF(gross_sales,0) < 0.10 THEN '0-10%'
        WHEN discount_amount / NULLIF(gross_sales,0) < 0.20 THEN '10-20%'
        WHEN discount_amount / NULLIF(gross_sales,0) < 0.30 THEN '20-30%'
        ELSE '30%+'
    END

ORDER BY month_start DESC;

--c)Refund Rate by Product Category
SELECT 
    category,

    COUNT(Distinct order_item_id) AS sold_items,

    SUM(refund_amount) AS refunds,

    SUM(net_revenue) AS net_revenue,

    CAST(
        100.0 * SUM(refund_amount) 
        / NULLIF(SUM(net_revenue),0)
    AS DECIMAL(8,2)) AS refund_rate_pct

FROM vw_fact_order_item_finance

WHERE month_start = '2026-01-01'

GROUP BY category

ORDER BY refund_rate_pct DESC;

--3) operation failure
 -- a) late delivery percentage my month 
;WITH ship_one AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (
            PARTITION BY s.order_id
            ORDER BY s.shipped_date DESC, s.shipment_id DESC
        ) AS rn
    FROM dbo.vw_fact_shipments_clean s
    WHERE s.shipment_status = 'Delivered'         
)
SELECT
    month_start,
    COUNT(*) AS delivered_shipments,
    SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) AS late_shipments,
    CAST(
        100.0 * SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*),0)
    AS DECIMAL(8,2)) AS late_delivery_pct
FROM ship_one
WHERE rn = 1 
GROUP BY month_start
ORDER BY month_start;


--4) Warehouse analysis
--a)warehouse load in campaign(late dellivery )
;WITH ship_one AS (
    SELECT
      s.*
    FROM dbo.vw_fact_shipments_clean s
    WHERE s.shipment_status = 'Delivered'
      AND s.month_start = '2026-01-01'
)
SELECT
    COALESCE(w.warehouse_id, -1) AS warehouse_id,
    COALESCE(w.warehouse_code, 'Unknown') AS warehouse_code,
    COALESCE(w.warehouse_city, 'Unknown') AS warehouse_city,
    COUNT(*) AS delivered_shipments,
    SUM(CASE WHEN so.is_late = 1 THEN 1 ELSE 0 END) AS late_shipments,
    CAST(
        100.0 * SUM(CASE WHEN so.is_late = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*),0)
    AS DECIMAL(8,2)) AS late_delivery_pct
FROM ship_one so
LEFT JOIN dbo.vw_dim_warehouse_clean w
    ON w.warehouse_id = so.warehouse_id

GROUP BY
    COALESCE(w.warehouse_id, -1),
    COALESCE(w.warehouse_code, 'Unknown'),
    COALESCE(w.warehouse_city, 'Unknown')
ORDER BY late_delivery_pct DESC;

--b)late delivery vs on time (profitability)
SELECT
    CASE 
        WHEN s.shipment_status = 'Delivered'
         AND s.delivered_date > DATEADD(DAY, s.promised_days, s.shipped_date)
        THEN 'Late Delivery'
        ELSE 'On Time'
    END AS delivery_type,

    COUNT(*) AS items,
    SUM(f.net_sales) AS net_sales,
    SUM(f.refund_amount) AS refunds,

    CAST(
        100.0 * SUM(f.refund_amount) /
        NULLIF(SUM(f.net_sales),0)
    AS DECIMAL(8,2)) AS refund_pct,

    SUM(f.contribution_profit) AS profit,

    CAST(
        100.0 * SUM(f.contribution_profit) /
        NULLIF(SUM(f.net_sales),0)
    AS DECIMAL(8,2)) AS margin_pct

FROM vw_fact_order_item_finance f
LEFT JOIN dbo.vw_fact_shipments_clean s
    ON s.order_id = f.order_id
GROUP BY
    CASE 
        WHEN s.shipment_status = 'Delivered'
         AND s.delivered_date > DATEADD(DAY, s.promised_days, s.shipped_date)
        THEN 'Late Delivery'
        ELSE 'On Time'
    END;

