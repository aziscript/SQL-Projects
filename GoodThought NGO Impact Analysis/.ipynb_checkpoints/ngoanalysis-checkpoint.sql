-- highest_donation_assignments
WITH donation_totals AS (
    SELECT
        a.assignment_name,
        a.region,
        dnr.donor_type,
        SUM(dn.amount) AS total_donation_amount
    FROM assignments a
    JOIN donations dn ON a.assignment_id = dn.assignment_id
    JOIN donors dnr ON dn.donor_id = dnr.donor_id
    GROUP BY a.assignment_name, a.region, dnr.donor_type
),
highest_donation_assignments AS (
    SELECT
        assignment_name,
        region,
        ROUND(total_donation_amount::numeric, 2) AS rounded_total_donation_amount,
        donor_type
    FROM donation_totals
    ORDER BY rounded_total_donation_amount DESC
    LIMIT 5
)
SELECT * FROM highest_donation_assignments;



-- top_regional_impact_assignments
WITH assignment_donations AS (
    SELECT
        a.assignment_id,
        a.assignment_name,
        a.region,
        a.impact_score,
        COUNT(dn.donation_id) AS num_total_donations
    FROM assignments a
    JOIN donations dn ON a.assignment_id = dn.assignment_id
    GROUP BY a.assignment_id, a.assignment_name, a.region, a.impact_score
),
ranked_assignments AS (
    SELECT
        assignment_name,
        region,
        impact_score,
        num_total_donations,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY impact_score DESC) AS rn
    FROM assignment_donations
),
top_regional_impact_assignments AS (
    SELECT
        assignment_name,
        region,
        impact_score,
        num_total_donations
    FROM ranked_assignments
    WHERE rn = 1
)
SELECT * FROM top_regional_impact_assignments
ORDER BY region ASC;