## **Additional Query 5: Seasonal Trends and Forecasting**

```sql
-- Query 5: Seasonal Trends Analysis with Forecasting
-- Business Question: What are the seasonal patterns and how can we forecast future performance?

SELECT
    -- Time dimensions for seasonal analysis
    dd.year,
    dd.month,
    dd.month_name,
    dd.quarter,
    dd.is_weekend,
    dd.is_holiday,
    
    -- Sales metrics
    SUM(fs.sales) AS monthly_sales,
    SUM(fs.profit) AS monthly_profit,
    AVG(fs.sales) AS avg_daily_sales,
    
    -- Seasonal trend analysis using 12-month window
    AVG(SUM(fs.sales)) OVER (
        ORDER BY dd.year, dd.month
        ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
    ) AS sales_12month_moving_avg,
    
    -- Seasonal comparison with same month in different years
    LAG(SUM(fs.sales), 12) OVER (ORDER BY dd.year, dd.month) AS same_month_prev_year,
    
    -- Calculate seasonal index (current month vs 12-month average)
    CASE 
        WHEN AVG(SUM(fs.sales)) OVER (
            ORDER BY dd.year, dd.month
            ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
        ) > 0 
        THEN ROUND(SUM(fs.sales) / AVG(SUM(fs.sales)) OVER (
            ORDER BY dd.year, dd.month
            ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
        ), 3)
        ELSE NULL
    END AS seasonal_index,
    
    -- Trend analysis using LEAD for forecasting validation
    LEAD(SUM(fs.sales), 1) OVER (ORDER BY dd.year, dd.month) AS next_month_actual,
    LEAD(SUM(fs.sales), 2) OVER (ORDER BY dd.year, dd.month) AS two_months_ahead,
    
    -- Weekend vs weekday performance impact
    CASE 
        WHEN dd.is_weekend = TRUE 
        THEN SUM(fs.sales) 
        ELSE NULL 
    END AS weekend_sales,
    
    -- Holiday impact analysis
    CASE 
        WHEN dd.is_holiday = TRUE 
        THEN SUM(fs.sales) 
        ELSE NULL 
    END AS holiday_sales,
    
    -- Volatility measurement using standard deviation
    STDDEV(SUM(fs.sales)) OVER (
        ORDER BY dd.year, dd.month
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
    ) AS sales_volatility_6month

FROM 
    fact_sales fs
JOIN 
    dim_date dd ON fs.date_key = dd.date_key
WHERE 
    dd.year IN (2019, 2020)
GROUP BY 
    dd.year, dd.month, dd.month_name, dd.quarter, dd.is_weekend, dd.is_holiday
ORDER BY 
    dd.year, dd.month;
```

---
