## **Query 2: Product Category Performance Analysis**

### Business Question Addressed
*"Which product categories drive the most revenue and how has their performance changed over time?"*

### Current Query Strengths
- ✅ Effective use of cumulative window functions
- ✅ Proper ranking implementation with `RANK()`
- ✅ Percentage contribution calculations
- ✅ Multi-dimensional analysis (year, quarter, category)

### Enhancement Suggestions
```sql
-- Enhanced Query 2: Product Category Performance with Competitive Analysis
-- Business Question: Which product categories drive revenue with trend analysis?

SELECT 
    -- Time and category dimensions
    dd.year,
    dd.quarter,
    dp.category,
    dp.sub_category_name,
    
    -- Sales metrics
    SUM(fs.sales) AS quarterly_sales,
    SUM(fs.quantity) AS units_sold,
    SUM(fs.profit) AS quarterly_profit,
    
    -- Calculate cumulative sales by category within each year
    SUM(SUM(fs.sales)) OVER (
        PARTITION BY dd.year, dp.category 
        ORDER BY dd.quarter
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_yearly_sales,
    
    -- Rank categories by sales within each quarter
    RANK() OVER (
        PARTITION BY dd.year, dd.quarter 
        ORDER BY SUM(fs.sales) DESC
    ) AS sales_rank_in_quarter,
    
    -- Track rank changes using LAG
    LAG(RANK() OVER (
        PARTITION BY dd.year, dd.quarter 
        ORDER BY SUM(fs.sales) DESC
    ), 1) OVER (
        PARTITION BY dp.category 
        ORDER BY dd.year, dd.quarter
    ) AS prev_quarter_rank,
    
    -- Calculate percentage contribution to overall sales
    ROUND(
        (SUM(fs.sales) / SUM(SUM(fs.sales)) OVER (PARTITION BY dd.year, dd.quarter)) * 100, 
        2
    ) AS pct_of_quarterly_sales,
    
    -- Quarter-over-quarter growth
    CASE 
        WHEN LAG(SUM(fs.sales), 1) OVER (
            PARTITION BY dp.category 
            ORDER BY dd.year, dd.quarter
        ) IS NULL THEN NULL
        ELSE ROUND(((SUM(fs.sales) - LAG(SUM(fs.sales), 1) OVER (
            PARTITION BY dp.category 
            ORDER BY dd.year, dd.quarter
        )) / LAG(SUM(fs.sales), 1) OVER (
            PARTITION BY dp.category 
            ORDER BY dd.year, dd.quarter
        )) * 100, 2)
    END AS qoq_growth_percent
    
FROM 
    fact_sales fs
JOIN 
    dim_date dd ON fs.date_key = dd.date_key
JOIN 
    dim_product dp ON fs.product_key = dp.product_key
WHERE 
    dd.year IN (2019, 2020)
GROUP BY 
    dd.year, dd.quarter, dp.category, dp.sub_category_name
ORDER BY 
    dd.year, dd.quarter, sales_rank_in_quarter;
```

### Visualization Recommendations for Query 2
1. **Stacked Area Chart**: Cumulative sales by category over time
2. **Ranking Chart**: Category rankings with arrows showing movement
3. **Treemap**: Category contribution to total sales
4. **Heat Map**: Quarter-over-quarter growth by category

---
