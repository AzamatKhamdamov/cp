-- Enhanced Query 3: Customer Segment Value with Retention Analysis
SELECT
    -- Customer dimensions
    dc.segment,
    dc.customer_id,
    dc.customer_name,
    -- Total customer value
    SUM(fs.sales) AS total_sales,
    SUM(fs.profit) AS total_profit,
    COUNT(DISTINCT fs.order_id) AS order_count,
    -- Calculate average order value
    ROUND(SUM(fs.sales) / COUNT(DISTINCT fs.order_id), 2) AS avg_order_value,
    
    -- Calculate customer ranking within segment
    ROW_NUMBER() OVER (
        PARTITION BY dc.segment 
        ORDER BY SUM(fs.sales) DESC
    ) AS customer_rank_in_segment,
    
    -- Calculate moving average of sales (last 3 customers in ranking)
    ROUND(AVG(SUM(fs.sales)) OVER (
        PARTITION BY dc.segment 
        ORDER BY SUM(fs.sales) DESC
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_sales_3_customers,
    
    -- Additional enhancements using window functions
    -- Compare customer value with next ranked customer using LEAD
    LEAD(SUM(fs.sales), 1) OVER (
        PARTITION BY dc.segment 
        ORDER BY SUM(fs.sales) DESC
    ) AS next_customer_sales,
    
    -- Calculate gap to next customer (shows value concentration)
    SUM(fs.sales) - LEAD(SUM(fs.sales), 1) OVER (
        PARTITION BY dc.segment 
        ORDER BY SUM(fs.sales) DESC
    ) AS sales_gap_to_next,
    
    -- Percentile ranking within segment
    PERCENT_RANK() OVER (
        PARTITION BY dc.segment 
        ORDER BY SUM(fs.sales)
    ) AS sales_percentile_rank,
    
    -- Customer lifetime analysis
    MIN(dd.full_date) AS first_purchase_date,
    MAX(dd.full_date) AS last_purchase_date,
    DATEDIFF(MAX(dd.full_date), MIN(dd.full_date)) + 1 AS customer_lifetime_days
    
FROM 
    fact_sales fs
JOIN 
    dim_customer dc ON fs.customer_key = dc.customer_key
JOIN 
    dim_date dd ON fs.date_key = dd.date_key
WHERE 
    dd.year IN (2019, 2020)
GROUP BY 
    dc.segment, dc.customer_id, dc.customer_name
-- Only show top 10 customers per segment
HAVING 
    ROW_NUMBER() OVER (
        PARTITION BY dc.segment 
        ORDER BY SUM(fs.sales) DESC
    ) <= 10
ORDER BY 
    dc.segment, customer_rank_in_segment;
