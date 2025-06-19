-- =====================================================
-- MOTORCYCLE PARTS SALES DATA ANALYSIS
-- =====================================================

-- =====================================================
-- 1. FINANCIAL PERFORMANCE ANALYSIS
-- =====================================================

-- 1.1 Profitability by Segment (Retail vs Wholesale)
-- Shows profit margins and total revenue by product line and client type
SELECT 
    product_line,
    client_type,
    COUNT(*) as order_count,
    SUM(quantity) as total_quantity,
    SUM(total) as gross_revenue,
    SUM(total - payment_fee) as net_revenue,
    AVG(unit_price) as avg_unit_price,
    AVG(total) as avg_order_value,
    ROUND((SUM(total - payment_fee) / SUM(total))::numeric * 100, 2) AS net_margin_percent
FROM sales
GROUP BY product_line, client_type
ORDER BY product_line, net_revenue DESC;


-- 1.2 Payment Method Cost Analysis
-- Analyzes the true cost impact of different payment methods
SELECT 
    payment,
    client_type,
    COUNT(*) as transaction_count,
    SUM(total) as gross_revenue,
    SUM(payment_fee) as total_fees,
    SUM(total - payment_fee) as net_revenue,
    ROUND(AVG(payment_fee), 2) as avg_fee_per_transaction,
    ROUND((SUM(payment_fee) / SUM(total))::numeric * 100, 2) as fee_percentage,
    ROUND((SUM(total - payment_fee) / COUNT(*))::numeric, 2) as avg_net_per_transaction
FROM sales
GROUP BY payment, client_type
ORDER BY fee_percentage DESC;

-- 1.3 Monthly Revenue Trends
-- Shows seasonal patterns and growth trends
SELECT 
    CASE 
        WHEN EXTRACT(MONTH FROM date::timestamp) = 6 THEN 'June'
        WHEN EXTRACT(MONTH FROM date::timestamp) = 7 THEN 'July'
        WHEN EXTRACT(MONTH FROM date::timestamp) = 8 THEN 'August'
    END as month,
    client_type,
    COUNT(*) as order_count,
    SUM(total) as gross_revenue,
    SUM(total - payment_fee) as net_revenue,
    AVG(total) as avg_order_value,
    -- Month-over-month growth calculation
    LAG(SUM(total - payment_fee)) OVER (PARTITION BY client_type ORDER BY EXTRACT(MONTH FROM date)) as prev_month_revenue,
    ROUND(
        (SUM(total - payment_fee) - LAG(SUM(total - payment_fee)) OVER (PARTITION BY client_type ORDER BY EXTRACT(MONTH FROM date))) 
        / LAG(SUM(total - payment_fee)) OVER (PARTITION BY client_type ORDER BY EXTRACT(MONTH FROM date)) * 100, 2
    ) as month_over_month_growth_percent
FROM sales
GROUP BY EXTRACT(MONTH FROM date), client_type
ORDER BY EXTRACT(MONTH FROM date), client_type;


-- =====================================================
-- 2. OPERATIONAL EFFICIENCY ANALYSIS
-- =====================================================

-- 2.1 Warehouse Performance Benchmarking
-- Compares performance metrics across all warehouses
warehouse_performance AS (
SELECT 
    warehouse,
    COUNT(*) as total_orders,
    COUNT(DISTINCT product_line) as product_lines_sold,
    SUM(quantity) as total_units_sold,
    SUM(total) as gross_revenue,
    SUM(total - payment_fee) as net_revenue,
    AVG(total) as avg_order_value,
    AVG(quantity) as avg_units_per_order,
    -- Performance ranking
    RANK() OVER (ORDER BY SUM(total - payment_fee) DESC) as revenue_rank,
    RANK() OVER (ORDER BY AVG(total) DESC) as avg_order_value_rank,
    RANK() OVER (ORDER BY SUM(quantity) DESC) as volume_rank
FROM sales
GROUP BY warehouse
ORDER BY net_revenue DESC
);

-- 2.2 Product Line Performance by Warehouse
-- Shows which products perform best at each location
product_warehouse_performance AS (
SELECT 
    warehouse,
    product_line,
    COUNT(*) as order_count,
    SUM(quantity) as total_quantity,
    SUM(total - payment_fee) as net_revenue,
    AVG(total) as avg_order_value,
    -- Calculate percentage of warehouse revenue
    ROUND(SUM(total - payment_fee) / SUM(SUM(total - payment_fee)) OVER (PARTITION BY warehouse) * 100, 2) as percent_of_warehouse_revenue,
    -- Rank products within each warehouse
    RANK() OVER (PARTITION BY warehouse ORDER BY SUM(total - payment_fee) DESC) as product_rank_in_warehouse
FROM sales
GROUP BY warehouse, product_line
ORDER BY warehouse, net_revenue DESC
);

-- 2.3 Order Size Analysis
-- Analyzes order patterns to identify bulk pricing opportunities
order_size_analysis AS (
SELECT 
    client_type,
    warehouse,
    CASE 
        WHEN quantity <= 5 THEN 'Small (1-5)'
        WHEN quantity <= 20 THEN 'Medium (6-20)'
        WHEN quantity <= 50 THEN 'Large (21-50)'
        ELSE 'Bulk (50+)'
    END as order_size_category,
    COUNT(*) as order_count,
    AVG(unit_price) as avg_unit_price,
    AVG(total) as avg_order_value,
    SUM(total - payment_fee) as net_revenue,
    -- Calculate average discount (if bulk orders have lower unit prices)
    AVG(unit_price) - MIN(AVG(unit_price)) OVER (PARTITION BY client_type) as price_variance_from_min
FROM sales
GROUP BY client_type, warehouse, 
    CASE 
        WHEN quantity <= 5 THEN 'Small (1-5)'
        WHEN quantity <= 20 THEN 'Medium (6-20)'
        WHEN quantity <= 50 THEN 'Large (21-50)'
        ELSE 'Bulk (50+)'
    END
ORDER BY client_type, warehouse, order_count DESC
);

-- =====================================================
-- 3. CUSTOMER INSIGHTS ANALYSIS
-- =====================================================

-- 3.1 Customer Behavior Profile
-- Profiles different customer segments
customer_behavior_profile AS (
SELECT 
    client_type,
    COUNT(DISTINCT order_number) as total_orders,
    COUNT(DISTINCT product_line) as unique_products_purchased,
    AVG(quantity) as avg_quantity_per_order,
    AVG(total) as avg_order_value,
    SUM(total - payment_fee) as total_net_revenue,
    -- Payment preferences
    MODE() WITHIN GROUP (ORDER BY payment) as preferred_payment_method,
    -- Most popular product line
    MODE() WITHIN GROUP (ORDER BY product_line) as most_popular_product,
    -- Seasonal behavior
    MODE() WITHIN GROUP (ORDER BY EXTRACT(MONTH FROM date)) as most_active_month
FROM sales
GROUP BY client_type
);

-- 3.2 Payment Method Preferences by Customer Type
-- Shows payment preferences across customer segments
payment_preferences AS (
SELECT 
    client_type,
    payment,
    COUNT(*) as usage_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY client_type), 2) as usage_percentage,
    AVG(total) as avg_order_value_for_payment,
    SUM(total - payment_fee) as net_revenue
FROM sales
GROUP BY client_type, payment
ORDER BY client_type, usage_count DESC
);

-- 3.3 Geographic Demand Patterns (by Warehouse Region)
-- Analyzes regional preferences
geographic_demand AS (
SELECT 
    warehouse,
    product_line,
    COUNT(*) as order_frequency,
    SUM(quantity) as total_demand,
    AVG(unit_price) as avg_price_point,
    SUM(total - payment_fee) as net_revenue,
    -- Market share within region
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY warehouse), 2) as market_share_percent,
    -- Demand intensity (orders per product line)
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT product_line) OVER (PARTITION BY warehouse), 2) as demand_intensity
FROM sales
GROUP BY warehouse, product_line
ORDER BY warehouse, order_frequency DESC
);

-- =====================================================
-- 4. STRATEGIC PLANNING ANALYSIS
-- =====================================================

-- 4.1 Growth Opportunity Matrix
-- Identifies high-potential and underperforming combinations
growth_opportunities AS (
SELECT 
    warehouse,
    product_line,
    client_type,
    COUNT(*) as current_orders,
    SUM(total - payment_fee) as current_net_revenue,
    AVG(total) as avg_order_value,
    -- Calculate potential based on top performer
    MAX(COUNT(*)) OVER (PARTITION BY product_line) as max_orders_for_product,
    MAX(SUM(total - payment_fee)) OVER (PARTITION BY product_line) as max_revenue_for_product,
    -- Gap analysis
    MAX(COUNT(*)) OVER (PARTITION BY product_line) - COUNT(*) as order_gap,
    MAX(SUM(total - payment_fee)) OVER (PARTITION BY product_line) - SUM(total - payment_fee) as revenue_gap,
    -- Opportunity score (higher = more opportunity)
    CASE 
        WHEN COUNT(*) < MAX(COUNT(*)) OVER (PARTITION BY product_line) * 0.5 
        THEN 'High Opportunity'
        WHEN COUNT(*) < MAX(COUNT(*)) OVER (PARTITION BY product_line) * 0.8 
        THEN 'Medium Opportunity'
        ELSE 'Market Leader'
    END as opportunity_level
FROM sales
GROUP BY warehouse, product_line, client_type
ORDER BY revenue_gap DESC
);

-- 4.2 Price Sensitivity Analysis
-- Analyzes how quantity responds to price changes
price_sensitivity AS (
SELECT 
    product_line,
    client_type,
    warehouse,
    MIN(unit_price) as min_price,
    MAX(unit_price) as max_price,
    AVG(unit_price) as avg_price,
    STDDEV(unit_price) as price_variance,
    -- Correlation between price and quantity (simplified)
    CORR(unit_price, quantity) as price_quantity_correlation,
    -- Elasticity indicator
    CASE 
        WHEN CORR(unit_price, quantity) < -0.5 THEN 'Highly Price Sensitive'
        WHEN CORR(unit_price, quantity) < -0.2 THEN 'Moderately Price Sensitive'
        WHEN CORR(unit_price, quantity) > 0.2 THEN 'Premium Product'
        ELSE 'Price Neutral'
    END as price_sensitivity_level
FROM sales
WHERE unit_price > 0  -- Exclude any zero prices
GROUP BY product_line, client_type, warehouse
HAVING COUNT(*) >= 10  -- Ensure sufficient data points
ORDER BY price_quantity_correlation
);

-- 4.3 Capacity Planning Analysis
-- Projects future capacity needs based on growth trends
capacity_planning AS (
WITH monthly_growth AS (
    SELECT 
        warehouse,
        EXTRACT(MONTH FROM date) as month_num,
        COUNT(*) as monthly_orders,
        SUM(quantity) as monthly_units,
        AVG(COUNT(*)) OVER (PARTITION BY warehouse) as avg_monthly_orders
    FROM sales
    GROUP BY warehouse, EXTRACT(MONTH FROM date)
)
SELECT 
    warehouse,
    MAX(monthly_orders) as peak_monthly_orders,
    MIN(monthly_orders) as min_monthly_orders,
    AVG(monthly_orders) as avg_monthly_orders,
    MAX(monthly_units) as peak_monthly_units,
    -- Growth rate calculation
    (MAX(monthly_orders) - MIN(monthly_orders)) / MIN(monthly_orders) * 100 as growth_rate_percent,
    -- Projected capacity needs (assuming 20% growth)
    CEIL(MAX(monthly_orders) * 1.2) as projected_peak_orders,
    CEIL(MAX(monthly_units) * 1.2) as projected_peak_units,
    -- Capacity utilization
    CASE 
        WHEN (MAX(monthly_orders) - MIN(monthly_orders)) / MIN(monthly_orders) > 0.5 
        THEN 'High Seasonality - Need Flexible Capacity'
        WHEN MAX(monthly_orders) > AVG(monthly_orders) * 1.3 
        THEN 'Peak Capacity Constraints'
        ELSE 'Stable Capacity Requirements'
    END as capacity_recommendation
FROM monthly_growth
GROUP BY warehouse
ORDER BY growth_rate_percent DESC
);

-- =====================================================
-- 5. EXECUTIVE SUMMARY QUERIES
-- =====================================================

-- 5.1 Key Performance Indicators Dashboard
kpi_dashboard AS (
SELECT 
    'Total Revenue' as metric,
    CONCAT('$', FORMAT(SUM(total - payment_fee), 2)) as value,
    'All Operations' as segment
FROM sales
UNION ALL
SELECT 
    'Total Orders',
    FORMAT(COUNT(*), 0),
    'All Operations'
FROM sales
UNION ALL
SELECT 
    'Average Order Value',
    CONCAT('$', FORMAT(AVG(total), 2)),
    'All Operations'
FROM sales
UNION ALL
SELECT 
    'Best Performing Warehouse',
    warehouse,
    CONCAT('$', FORMAT(SUM(total - payment_fee), 2))
FROM sales
GROUP BY warehouse
ORDER BY SUM(total - payment_fee) DESC
LIMIT 1
);

-- 5.2 Top Performers Summary
top_performers AS (
SELECT 
    'Product Line' as category,
    product_line as name,
    SUM(total - payment_fee) as revenue
FROM sales
GROUP BY product_line
ORDER BY revenue DESC
LIMIT 3

UNION ALL

SELECT 
    'Warehouse',
    warehouse,
    SUM(total - payment_fee)
FROM sales
GROUP BY warehouse
ORDER BY SUM(total - payment_fee) DESC
LIMIT 3

UNION ALL

SELECT 
    'Payment Method',
    payment,
    SUM(total - payment_fee)
FROM sales
GROUP BY payment
ORDER BY SUM(total - payment_fee) DESC
LIMIT 3
);



