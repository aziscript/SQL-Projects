WITH top_industries AS (
  SELECT i.industry
  FROM industries i
  INNER JOIN dates d ON i.company_id = d.company_id
  WHERE EXTRACT(YEAR FROM d.date_joined::DATE) IN (2019, 2020, 2021)
  GROUP BY i.industry
  ORDER BY COUNT(*) DESC
  LIMIT 3
),
yearly_stats AS (
  SELECT 
    ti.industry,
    EXTRACT(YEAR FROM d.date_joined::DATE) AS year,
    COUNT(*) AS num_unicorns,
    AVG(f.valuation) AS avg_valuation
  FROM top_industries ti
  INNER JOIN industries i ON ti.industry = i.industry
  INNER JOIN dates d ON i.company_id = d.company_id
  INNER JOIN funding f ON d.company_id = f.company_id
  WHERE EXTRACT(YEAR FROM d.date_joined::DATE) BETWEEN 2019 AND 2021
  GROUP BY ti.industry, EXTRACT(YEAR FROM d.date_joined::DATE)
)
SELECT 
  industry,
  year,
  num_unicorns,
  ROUND(avg_valuation / 1000000000, 2) AS average_valuation_billions
FROM yearly_stats
ORDER BY year DESC, num_unicorns DESC;


