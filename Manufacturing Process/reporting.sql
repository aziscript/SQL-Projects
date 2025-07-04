-- Flag whether the height of a product is within the control limits
SELECT
	b.*,
	CASE
		WHEN 
			b.height NOT BETWEEN b.lcl AND b.ucl
		THEN TRUE
		ELSE FALSE
	END as alert
FROM (
	SELECT
		a.*, 
		a.avg_height + 3*a.stddev_height/SQRT(5) AS ucl, 
		a.avg_height - 3*a.stddev_height/SQRT(5) AS lcl  
	FROM (
		SELECT 
			operator,
			ROW_NUMBER() OVER w AS row_number, 
			height, 
			AVG(height) OVER w AS avg_height, 
			STDDEV(height) OVER w AS stddev_height
		FROM parts 
		WINDOW w AS (
			PARTITION BY operator 
			ORDER BY item_no 
			ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
		)
	) AS a
	WHERE a.row_number >= 5
) AS b;




-- Alternative: Different CTE structure but same logic
WITH rolling_calculations AS (
    SELECT 
        operator,
        height,
        ROW_NUMBER() OVER (PARTITION BY operator ORDER BY item_no) AS row_number,
        AVG(height) OVER (
            PARTITION BY operator 
            ORDER BY item_no 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS avg_height,
        STDDEV(height) OVER (
            PARTITION BY operator 
            ORDER BY item_no 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS stddev_height
    FROM parts
)
SELECT 
    *,
    avg_height + 3 * stddev_height / SQRT(5) AS ucl,
    avg_height - 3 * stddev_height / SQRT(5) AS lcl,
    CASE 
        WHEN height NOT BETWEEN 
            (avg_height - 3 * stddev_height / SQRT(5)) AND 
            (avg_height + 3 * stddev_height / SQRT(5))
        THEN TRUE 
        ELSE FALSE 
    END AS alert
FROM rolling_calculations
WHERE row_number >= 5;



