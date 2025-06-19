
-- net_revenue by product_line
SELECT 
    product_line,
    month,
    warehouse,
    SUM(total) - SUM(payment_fee) AS net_revenue
FROM (
    SELECT 
        product_line,
        CASE 
            WHEN EXTRACT(MONTH FROM date::timestamp) = 6 THEN 'June'
            WHEN EXTRACT(MONTH FROM date::timestamp) = 7 THEN 'July'
            WHEN EXTRACT(MONTH FROM date::timestamp) = 8 THEN 'August'
        END AS month,
        warehouse,
        total,
        payment_fee
    FROM sales
    WHERE client_type = 'Wholesale'
) AS sub
GROUP BY product_line, month, warehouse
ORDER BY product_line, month, net_revenue DESC;

