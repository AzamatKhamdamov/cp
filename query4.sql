-- Enhanced Query 4: Shipping Efficiency with Customer Impact Analysis
SELECT
    -- Shipping dimensions
    ds.ship_mode,
    -- Group by shipping duration ranges
    CASE 
        WHEN ds.days_to_ship = 0 THEN 'Same day'
        WHEN ds.days_to_ship BETWEEN 1 AND 2 THEN '1-2 days'
        WHEN ds.days_to_ship BETWEEN 3 AND 5 THEN '3-5 days'
        ELSE '6+ days'
    END AS shipping_duration,
    
    -- Order metrics
    COUNT(DISTINCT fs.order_id) AS order_count,
    COUNT(DISTINCT fs.customer_key) AS unique_customers,
    
    -- Sales and profit metrics
    SUM(fs.sales) AS total_sales,
    SUM(fs.profit) AS total_profit,
    
    -- Calculate profit margin
    ROUND((SUM(fs.profit) / SUM(fs.sales)) * 100, 2) AS profit_margin_pct,
    
    -- Compare with average profit margin for all shipping modes
    ROUND((SUM(fs.profit) / SUM(fs.sales)) * 100, 2) - 
        ROUND((SUM(SUM(fs.profit)) OVER() / SUM(SUM(fs.sales)) OVER()) * 100, 2) 
        AS margin_vs_overall_avg,
    
    -- Calculate average days to ship by mode
    AVG(ds.days_to_ship) AS avg_days_to_ship,
    
    -- Compare with previous shipping duration category using LAG
    LAG(ROUND((SUM(fs.profit) / SUM(fs.sales)) * 100, 2)) OVER (
        PARTITION BY ds.ship_mode 
        ORDER BY 
            CASE 
                WHEN ds.days_to_ship = 0 THEN 1
                WHEN ds.days_to_ship BETWEEN 1 AND 2 THEN 2
                WHEN ds.days_to_ship BETWEEN 3 AND 5 THEN 3
                ELSE 4
            END
    ) AS prev_duration_profit_margin,
    
    -- Additional enhancements
    -- Customer satisfaction proxy (orders per customer)
    ROUND(COUNT(DISTINCT fs.order_id) / COUNT(DISTINCT fs.customer_key), 2) AS orders_per_customer,
    
    -- Market share by shipping mode
    ROUND((COUNT(DISTINCT fs.order_id) / SUM(COUNT(DISTINCT fs.order_id)) OVER()) * 100, 2) AS market_share_pct,
    
    -- Average order value by shipping mode
    ROUND(SUM(fs.sales) / COUNT(DISTINCT fs.order_id), 2) AS avg_order_value,
    
    -- Efficiency score (profit per day)
    CASE 
        WHEN AVG(ds.days_to_ship) > 0 
        THEN ROUND(SUM(fs.profit) / AVG(ds.days_to_ship), 2)
        ELSE SUM(fs.profit)
    END AS profit_per_shipping_day,
    
    -- Compare efficiency with next faster shipping option using LEAD
    LEAD(CASE 
        WHEN AVG(ds.days_to_ship) > 0 
        THEN ROUND(SUM(fs.profit) / AVG(ds.days_to_ship), 2)
        ELSE SUM(fs.profit)
    END) OVER (
        PARTITION BY ds.ship_mode 
        ORDER BY 
            CASE 
                WHEN ds.days_to_ship = 0 THEN 1
                WHEN ds.days_to_ship BETWEEN 1 AND 2 THEN 2
                WHEN ds.days_to_ship BETWEEN 3 AND 5 THEN 3
                ELSE 4
            END DESC
    ) AS faster_option_efficiency

FROM 
    fact_sales fs
JOIN 
    dim_shipping ds ON fs.ship_key = ds.ship_key
GROUP BY 
    ds.ship_mode,
    CASE 
        WHEN ds.days_to_ship = 0 THEN 'Same day'
        WHEN ds.days_to_ship BETWEEN 1 AND 2 THEN '1-2 days'
        WHEN ds.days_to_ship BETWEEN 3 AND 5 THEN '3-5 days'
        ELSE '6+ days'
    END
ORDER BY 
    ds.ship_mode,
    CASE 
        WHEN shipping_duration = 'Same day' THEN 1
        WHEN shipping_duration = '1-2 days' THEN 2
        WHEN shipping_duration = '3-5 days' THEN 3
        ELSE 4
    END;
