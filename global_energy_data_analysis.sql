--- Create Database and Table
show databases;

Create database energy_data;
USE energy_data;
SHOW TABLES;

-- Electricity Data Analysis using SQL.
-- Solution of 10 Business Questions.

DESC energy_data;


-- 1. Which countries have had the highest growth in electricity production from renewable sources over the last 10 years?
WITH total_renew_last_year AS (
    SELECT Entity, 
           (Wind + Solar + Hydro + Bioenergy + `Other renewables`) AS total_end
    FROM energy_data
    WHERE Year = (SELECT MAX(Year) FROM energy_data)
), 
total_renew_10_years_ago AS (
    SELECT Entity, 
           (Wind + Solar + Hydro + Bioenergy + `Other renewables`) AS total_start
    FROM energy_data
    WHERE Year = (SELECT MAX(Year) - 10 FROM energy_data)
) 
SELECT lst.Entity, 
       ROUND(lst.total_end - ago.total_start, 2) AS energy_diff, 
       ROUND(((lst.total_end - ago.total_start) / NULLIF(ago.total_start, 0) * 100), 2) AS energy_diff_percentage
FROM total_renew_last_year lst
JOIN total_renew_10_years_ago ago USING (Entity)
WHERE lst.total_end > 0 AND ago.total_start > 0
ORDER BY energy_diff DESC;


-- 2. What is the share of each type of energy source in total electricity production in
-- each country for the last year in the dataset?

WITH total_cte AS (
    SELECT Entity, 
           Year, 
           Coal, 
           Gas, 
           Nuclear, 
           Hydro, 
           Solar, 
           Oil, 
           Wind, 
           Bioenergy, 
           `Other renewables`,
           (Coal + Gas + Nuclear + Hydro + Solar + Oil + Wind + Bioenergy + `Other renewables`) AS total_energy
    FROM energy_data
    WHERE Year = (SELECT MAX(Year) FROM energy_data)
)
SELECT Entity, 
       ROUND(Coal / total_energy * 100, 2) AS coal_portion,
       ROUND(Gas / total_energy * 100, 2) AS gas_portion,
       ROUND(Nuclear / total_energy * 100, 2) AS nuclear_portion,
       ROUND(Hydro / total_energy * 100, 2) AS hydro_portion,
       ROUND(Solar / total_energy * 100, 2) AS solar_portion,
       ROUND(Oil / total_energy * 100, 2) AS oil_portion,
       ROUND(Wind / total_energy * 100, 2) AS wind_portion,
       ROUND(Bioenergy / total_energy * 100, 2) AS bioenergy_portion,
       ROUND(`Other renewables` / total_energy * 100, 2) AS other_renewables_portion,
       ROUND(total_energy, 2) AS total_energy
FROM total_cte
WHERE total_energy > 0
ORDER BY total_energy DESC;




-- 3. Which year in the dataset was the most productive for global electricity production from nuclear energy?

SELECT year
	,SUM(nuclear) as total_nuclear
FROM energy_data
GROUP BY year
ORDER BY total_nuclear DESC
LIMIT 1
;



-- 4. Which countries experienced a decline in total electricity production over any period, despite the growth in global production?

WITH total_world_energy AS ( -- CTE for calculating total energy production at the global level by years.
    SELECT Year,
           SUM(Coal + Gas + Nuclear + Hydro + Solar + Oil + Wind + Bioenergy + `Other renewables`) AS total_energy
    FROM energy_data
    GROUP BY Year
    ORDER BY Year
),

world_diff_to_prev_year_cte AS ( -- CTE to calculate the difference in energy production between the current and previous year at the global level.
    SELECT Year,
           total_energy,
           LAG(total_energy) OVER (ORDER BY Year) AS prev_year_total,
           total_energy - COALESCE(LAG(total_energy) OVER (ORDER BY Year), 0) AS diff_to_prev_year
    FROM total_world_energy
),

country_total_energy AS ( -- CTE to calculate total energy production by country and year.
    SELECT Entity AS country, 
           Year,
           (Coal + Gas + Nuclear + Hydro + Solar + Oil + Wind + Bioenergy + `Other renewables`) AS total_energy
    FROM energy_data
    ORDER BY Year
),

country_diff_to_prev_year_cte AS ( -- CTE to calculate the difference in energy production for a country between the current and previous year.
    SELECT country,
           Year,
           total_energy,
           LAG(total_energy) OVER (PARTITION BY country ORDER BY Year) AS prev_year_total,
           total_energy - COALESCE(LAG(total_energy) OVER (PARTITION BY country ORDER BY Year), 0) AS diff_to_prev_year
    FROM country_total_energy
)

SELECT country, -- Main query answering our business question.
       Year,
       diff_to_prev_year
FROM country_diff_to_prev_year_cte
WHERE diff_to_prev_year < 0
AND Year IN (SELECT Year 
             FROM world_diff_to_prev_year_cte
             WHERE diff_to_prev_year > 0)
ORDER BY diff_to_prev_year ASC;



-- 5. Which 5 countries have the largest difference between the minimum and
-- maximum electricity production from natural gas over the entire period?

SELECT Entity AS country, 
       MAX(Gas) - MIN(Gas) AS gas_diff_max_min
FROM energy_data
GROUP BY Entity
ORDER BY gas_diff_max_min DESC;


-- 6. Which country was the first to start producing electricity from solar energy, and in which year did it happen?

WITH first_year_cte AS (
    SELECT Entity AS country,
           MIN(Year) AS first_year
    FROM energy_data
    WHERE Solar <> 0
    GROUP BY Entity
)
SELECT * 
FROM first_year_cte
WHERE first_year = (SELECT MIN(first_year) FROM first_year_cte);


-- 7. Which countries in 2023 produced more electricity from renewable sources than from coal?

SELECT country
FROM (
    SELECT Entity AS country, 
           Coal, 
           Year, 
           (Wind + Solar + Hydro + Bioenergy + `Other renewables`) AS total_renewables
    FROM energy_data
) AS coal_and_renew
WHERE Coal < total_renewables AND Year = 2023;


-- 8. Which countries over the last 10 years produced more electricity from
-- renewable sources compared to coal by a factor of 2 or more?

SELECT Entity AS country,
       SUM(Coal) AS total_coal,
       SUM(Wind + Solar + Hydro + Bioenergy + `Other renewables`) AS total_renewables
FROM energy_data
WHERE Year BETWEEN 2014 AND 2023
GROUP BY Entity
HAVING SUM(Coal) > 0 
   AND (SUM(Wind + Solar + Hydro + Bioenergy + `Other renewables`) / SUM(Coal)) > 2;


-- 9. Which type of energy (coal or renewable sources) dominated in each country in 
-- terms of production volume over the entire period (from 1965 to 2023)?

SELECT Entity AS country,
       CASE 
           WHEN SUM(Coal) > SUM(Wind + Solar + Hydro + Bioenergy + `Other renewables`) THEN 'Coal'
           ELSE 'Renewables' 
       END AS dominant_energy_type
FROM energy_data
GROUP BY Entity;


-- 10. Which countries over the last 10 years have produced more than 60% of their electricity from renewable sources?

WITH renew_and_total_cte AS (
    SELECT Entity AS country,
           SUM(Coal + Gas + Nuclear + Hydro + Solar + Oil + Wind + Bioenergy + `Other renewables`) AS total_energy,
           SUM(Wind + Solar + Hydro + Bioenergy + `Other renewables`) AS total_renewables,
           CASE 
               WHEN SUM(Wind + Solar + Hydro + Bioenergy + `Other renewables`) / 
                    SUM(Coal + Gas + Nuclear + Hydro + Solar + Oil + Wind + Bioenergy + `Other renewables`) > 0.6
               THEN 'Above 60%'
               ELSE 'Below 60%' 
           END AS renew_total_proportion
    FROM energy_data
    WHERE Year BETWEEN 2014 AND 2023
    GROUP BY Entity
    HAVING SUM(Coal + Gas + Nuclear + Hydro + Solar + Oil + Wind + Bioenergy + `Other renewables`) > 0
)

SELECT * FROM renew_and_total_cte
WHERE renew_total_proportion = 'Above 60%';

