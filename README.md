# Global Electricity Production Analysis Using SQL
Overview
This project examines global electricity production, focusing on the growth and share of renewable energy sources over the past decade. The primary objective is to identify key trends and countries leading the transition to sustainable energy. Through SQL-based data analysis, the project uncovers insights into energy production patterns, highlighting the shift from fossil fuels to renewable sources and recognizing nations spearheading clean energy adoption.

Objectives
Analyze the growth of renewable energy production over the past decade.
Determine the share of different energy sources in total electricity production by country.
Identify countries with significant shifts towards renewable energy.
Compare global trends in energy production.
Highlight the leading countries in clean energy transitions.
Dataset
This analysis is based on the Electricity Dataset from Kaggle, which contains electricity production data by source for various countries over multiple years.

Schema & Data Processing
The dataset was structured using the following schema:

sql
Copy
Edit
CREATE TABLE energy_data (
    id SERIAL PRIMARY KEY,
    Country TEXT,
    Code TEXT,
    Year INT,
    Coal NUMERIC,
    Gas NUMERIC,
    Nuclear NUMERIC,
    Hydro NUMERIC,
    Solar NUMERIC,
    Oil NUMERIC,
    Wind NUMERIC,
    Bioenergy NUMERIC,
    Other_renewables NUMERIC
);
Data Loading & Cleaning
The dataset was loaded into the table and cleaned to replace NULL values with 0:

sql
Copy
Edit
UPDATE energy_data
SET
    Coal = COALESCE(Coal, 0),
    Gas = COALESCE(Gas, 0),
    Nuclear = COALESCE(Nuclear, 0),
    Hydro = COALESCE(Hydro, 0),
    Solar = COALESCE(Solar, 0),
    Oil = COALESCE(Oil, 0),
    Wind = COALESCE(Wind, 0),
    Bioenergy = COALESCE(Bioenergy, 0),
    Other_renewables = COALESCE(Other_renewables, 0);
Business Questions & Solutions
1. Countries with the Highest Growth in Renewable Energy (Last 10 Years)
This query identifies the countries that have significantly increased their renewable electricity production over the past decade.

sql
Copy
Edit
WITH total_renew_last_year AS (
    SELECT country, (wind + solar + hydro + bioenergy + other_renewables) AS total_end
    FROM energy_data
    WHERE year = (SELECT MAX(year) FROM energy_data)
),
total_renew_10_years_ago AS (
    SELECT country, (wind + solar + hydro + bioenergy + other_renewables) AS total_start
    FROM energy_data
    WHERE year = (SELECT MAX(year) - 10 FROM energy_data)
)
SELECT country,
       ROUND(lst.total_end - ago.total_start, 2) AS energy_diff,
       ROUND(((lst.total_end - ago.total_start)/ago.total_start*100), 2) AS energy_diff_percentage
FROM total_renew_last_year lst
JOIN total_renew_10_years_ago ago USING (country)
WHERE lst.total_end > 0 AND ago.total_start > 0
ORDER BY energy_diff DESC;
2. Energy Source Share in Electricity Production (Last Year)
This query calculates the percentage contribution of each energy source to total electricity production per country in the most recent year.

sql
Copy
Edit
WITH total_cte AS (
    SELECT country, year, coal, gas, nuclear, hydro, solar, oil, wind, bioenergy, other_renewables,
           (coal + gas + nuclear + hydro + solar + oil + wind + bioenergy + other_renewables) AS total_energy
    FROM energy_data
    WHERE year = (SELECT MAX(year) FROM energy_data)
)
SELECT country,
       ROUND(coal/total_energy*100, 2) AS coal_portion,
       ROUND(gas/total_energy*100, 2) AS gas_portion,
       ROUND(nuclear/total_energy*100, 2) AS nuclear_portion,
       ROUND(hydro/total_energy*100, 2) AS hydro_portion,
       ROUND(solar/total_energy*100, 2) AS solar_portion,
       ROUND(oil/total_energy*100, 2) AS oil_portion,
       ROUND(wind/total_energy*100, 2) AS wind_portion,
       ROUND(bioenergy/total_energy*100, 2) AS bioenergy_portion,
       ROUND(other_renewables/total_energy*100, 2) AS other_renewables_portion,
       ROUND(total_energy, 2)
FROM total_cte
WHERE total_energy > 0
ORDER BY total_energy DESC;
3. Most Productive Year for Nuclear Energy
This query identifies the year with the highest global electricity production from nuclear energy.

sql
Copy
Edit
SELECT year, SUM(nuclear) AS total_nuclear
FROM energy_data
GROUP BY year
ORDER BY total_nuclear DESC
LIMIT 1;
4. Countries with Declining Electricity Production Despite Global Growth
This query finds countries where electricity production declined in certain years, even as global production increased.

sql
Copy
Edit
WITH world_energy AS (
    SELECT year, SUM(coal + gas + nuclear + hydro + solar + oil + wind + bioenergy + other_renewables) AS total_energy
    FROM energy_data
    GROUP BY year
),
world_growth AS (
    SELECT year, total_energy, 
           total_energy - LAG(total_energy) OVER (ORDER BY year) AS diff_to_prev_year
    FROM world_energy
),
country_energy AS (
    SELECT country, year,
           coal + gas + nuclear + hydro + solar + oil + wind + bioenergy + other_renewables AS total_energy
    FROM energy_data
),
country_decline AS (
    SELECT country, year, total_energy, 
           total_energy - LAG(total_energy) OVER (PARTITION BY country ORDER BY year) AS diff_to_prev_year
    FROM country_energy
)
SELECT country, year, diff_to_prev_year
FROM country_decline
WHERE diff_to_prev_year < 0
AND year IN (SELECT year FROM world_growth WHERE diff_to_prev_year > 0)
ORDER BY diff_to_prev_year ASC;
5. Countries Producing More Electricity from Renewables than Coal (2023)
This query identifies countries that produced more electricity from renewable sources than coal in 2023.

sql
Copy
Edit
WITH renew_vs_coal AS (
    SELECT country, year, coal, 
           (wind + solar + hydro + bioenergy + other_renewables) AS total_renewables
    FROM energy_data
)
SELECT country, year, coal, total_renewables, total_renewables - coal AS difference
FROM renew_vs_coal
WHERE coal < total_renewables AND year = 2023
ORDER BY difference DESC;
Findings & Conclusion
Growth in Renewables: Several countries have significantly increased their renewable energy production in the last decade, with some leading in wind, solar, and hydroelectric power.
Energy Distribution: Renewable energy sources now contribute more electricity than traditional fossil fuels in several countries.
Challenges & Opportunities: While many nations are transitioning to clean energy, others remain dependent on fossil fuels, highlighting both challenges and investment opportunities for future energy policies.
Final Thoughts
This SQL-based analysis provides valuable insights into global energy trends, helping policymakers, researchers, and investors understand electricity production dynamics.

🔹 Thank you for exploring my SQL project! 🚀
