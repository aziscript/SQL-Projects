-- top_five_products_each_category
SELECT *
FROM (
    SELECT 
        products.category, 
        products.product_name,
        ROUND(SUM(CAST(ord.sales AS NUMERIC)), 2) AS product_total_sales,
        ROUND(SUM(CAST(ord.profit AS NUMERIC)), 2) AS product_total_profit,
        RANK() OVER (
            PARTITION BY products.category 
            ORDER BY SUM(ord.sales) DESC
        ) AS product_rank
    FROM orders AS ord
    INNER JOIN products
        ON ord.product_id = products.product_id
    GROUP BY 
        products.category, 
        products.product_name
) AS tmp
WHERE product_rank < 6;


-- impute_missing_values
WITH missing AS (
    SELECT 
        product_id,
        discount, 
        market,
        region,
        sales,
        quantity
    FROM orders 
    WHERE quantity IS NULL
), 
unit_prices AS (
    SELECT 
        o.product_id,
        CAST(o.sales / o.quantity AS NUMERIC) AS unit_price
    FROM orders o
    RIGHT JOIN missing AS m 
        ON o.product_id = m.product_id
        AND o.discount = m.discount
    WHERE o.quantity IS NOT NULL
)
SELECT DISTINCT 
    m.*,
    ROUND(CAST(m.sales AS NUMERIC) / up.unit_price, 0) AS calculated_quantity
FROM missing AS m
INNER JOIN unit_prices AS up
    ON m.product_id = up.product_id;

