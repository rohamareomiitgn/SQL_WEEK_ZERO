USE retail_events_db;


SELECT event_id, store_id, product_code, base_price, promo_type
FROM fact_events
WHERE base_price > 1000;

-- Q2
SELECT event_id, product_code, promo_type,
       `quantity_sold(before_promo)`, `quantity_sold(after_promo)`
FROM fact_events
WHERE `quantity_sold(after_promo)` > 100
ORDER BY `quantity_sold(after_promo)` DESC;

-- Q3
SELECT DISTINCT promo_type
FROM fact_events;

-- Q4
SELECT COUNT(*)                          AS total_events,
       SUM(`quantity_sold(before_promo)`) AS total_before,
       SUM(`quantity_sold(after_promo)`)  AS total_after,
       AVG(base_price)                    AS avg_price,
       MAX(base_price)                    AS max_price,
       MIN(base_price)                    AS min_price
FROM fact_events;

-- Q5



SELECT promo_type,
       COUNT(*)                           AS event_count,
       SUM(`quantity_sold(before_promo)`) AS total_before,
       SUM(`quantity_sold(after_promo)`)  AS total_after
FROM fact_events
GROUP BY promo_type
ORDER BY total_after DESC;



-- Q6


SELECT promo_type,
       SUM(`quantity_sold(before_promo)`) AS total_before,
       SUM(`quantity_sold(after_promo)`)  AS total_after,
       SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`) AS quantity_change
FROM fact_events
GROUP BY promo_type
ORDER BY quantity_change DESC;


-- Q7
SELECT product_code, product_name, category,
       SUM(`quantity_sold(after_promo)`) AS total_after
FROM fact_events f
JOIN dim_products p USING (product_code)
GROUP BY product_code, product_name, category
ORDER BY total_after DESC;

-- Q8
SELECT category,
       COUNT(*)                           AS event_count,
       SUM(`quantity_sold(before_promo)`) AS total_before,
       SUM(`quantity_sold(after_promo)`)  AS total_after,
       SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`) AS quantity_change
FROM fact_events f
JOIN dim_products p USING (product_code)
GROUP BY category
ORDER BY total_after DESC;

-- Q9
SELECT city,
       COUNT(*)                           AS event_count,
       SUM(`quantity_sold(before_promo)`) AS total_before,
       SUM(`quantity_sold(after_promo)`)  AS total_after
FROM fact_events f
JOIN dim_stores s USING (store_id)
GROUP BY city
ORDER BY total_after DESC;



-- Q10
SELECT campaign_name, start_date, end_date,
       COUNT(*)                           AS event_count,
       SUM(`quantity_sold(before_promo)`) AS total_before,
       SUM(`quantity_sold(after_promo)`)  AS total_after
FROM fact_events f
JOIN dim_campaigns c USING (campaign_id)
GROUP BY campaign_name, start_date, end_date
ORDER BY total_after DESC;


-- Q11
SELECT category,
       SUM(`quantity_sold(after_promo)`) AS total_after,
       AVG(base_price)                   AS avg_price
FROM fact_events f
JOIN dim_products p USING (product_code)
GROUP BY category
HAVING SUM(`quantity_sold(after_promo)`) > 1000
ORDER BY total_after DESC;


-- Q12


SELECT city, category,
       SUM(`quantity_sold(after_promo)`) AS total_after
FROM fact_events f
JOIN dim_stores   s USING (store_id)
JOIN dim_products p USING (product_code)
GROUP BY city, category
ORDER BY city, total_after DESC;

-- Q13
SELECT product_name, category,
       SUM(`quantity_sold(before_promo)`) AS total_before,
       SUM(`quantity_sold(after_promo)`)  AS total_after,
       SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`) AS quantity_change,
       ROUND((SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`))
             / NULLIF(SUM(`quantity_sold(before_promo)`), 0) * 100, 2) AS pct_change
FROM fact_events f
JOIN dim_products p USING (product_code)
GROUP BY product_code, product_name, category
ORDER BY pct_change DESC;

-- Q14
SELECT campaign_name, promo_type,
       COUNT(*)                           AS event_count,
       SUM(`quantity_sold(before_promo)`) AS total_before,
       SUM(`quantity_sold(after_promo)`)  AS total_after,
       SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`) AS quantity_change
FROM fact_events f
JOIN dim_campaigns c USING (campaign_id)
GROUP BY campaign_name, promo_type
ORDER BY campaign_name, quantity_change DESC;

-- Q15
SELECT product_name, category,
       SUM(base_price * `quantity_sold(before_promo)`) AS revenue_before,
       SUM(base_price * `quantity_sold(after_promo)`)  AS revenue_after,
       SUM(base_price * `quantity_sold(after_promo)`)
         - SUM(base_price * `quantity_sold(before_promo)`) AS revenue_difference
FROM fact_events f
JOIN dim_products p USING (product_code)
GROUP BY product_code, product_name, category
ORDER BY revenue_difference DESC;

-- Q16
WITH t AS (
  SELECT promo_type,
         SUM(`quantity_sold(before_promo)`) AS total_before,
         SUM(`quantity_sold(after_promo)`)  AS total_after
  FROM fact_events
  GROUP BY promo_type
), pct AS (
  SELECT *, ROUND((total_after - total_before) / NULLIF(total_before, 0) * 100, 2) AS percentage_change
  FROM t
)
SELECT *,
       CASE WHEN percentage_change >= 50 THEN 'High Impact'
            WHEN percentage_change >= 20 THEN 'Medium Impact'
            ELSE 'Low Impact' END AS performance_category
FROM pct
ORDER BY percentage_change DESC;

-- Q17
WITH t AS (
  SELECT category, product_name,
         SUM(`quantity_sold(after_promo)`) AS total_quantity_after
  FROM fact_events f
  JOIN dim_products p USING (product_code)
  GROUP BY category, product_code, product_name
), r AS (
  SELECT *, DENSE_RANK() OVER (PARTITION BY category ORDER BY total_quantity_after DESC) AS category_rank
  FROM t
)
SELECT * FROM r WHERE category_rank <= 2;

-- Q18
WITH t AS (
  SELECT city, store_id,
         SUM(`quantity_sold(after_promo)`) AS total_quantity_after
  FROM fact_events f
  JOIN dim_stores s USING (store_id)
  GROUP BY city, store_id
), r AS (
  SELECT *, DENSE_RANK() OVER (PARTITION BY city ORDER BY total_quantity_after DESC) AS city_rank
  FROM t
)
SELECT * FROM r WHERE city_rank <= 2;

-- Q19
WITH t AS (
  SELECT campaign_name, product_name,
         SUM(`quantity_sold(before_promo)`) AS total_before,
         SUM(`quantity_sold(after_promo)`)  AS total_after,
         SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`) AS quantity_change,
         ROUND((SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`))
               / NULLIF(SUM(`quantity_sold(before_promo)`), 0) * 100, 2) AS percentage_change
  FROM fact_events f
  JOIN dim_campaigns c USING (campaign_id)
  JOIN dim_products  p USING (product_code)
  GROUP BY campaign_name, product_code, product_name
), r AS (
  SELECT *, DENSE_RANK() OVER (PARTITION BY campaign_name ORDER BY percentage_change DESC) AS campaign_rank
  FROM t
)
SELECT * FROM r WHERE campaign_rank <= 3;

-- Q20
WITH t AS (
  SELECT product_name, category,
         COUNT(*)                           AS event_count,
         SUM(`quantity_sold(before_promo)`) AS total_before,
         SUM(`quantity_sold(after_promo)`)  AS total_after,
         SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`) AS quantity_change,
         ROUND((SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`))
               / NULLIF(SUM(`quantity_sold(before_promo)`), 0) * 100, 2) AS percentage_change,
         SUM(base_price * `quantity_sold(before_promo)`) AS revenue_before,
         SUM(base_price * `quantity_sold(after_promo)`)  AS revenue_after,
         SUM(base_price * `quantity_sold(after_promo)`)
           - SUM(base_price * `quantity_sold(before_promo)`) AS revenue_change,
         ROUND(AVG(base_price), 2) AS avg_base_price
  FROM fact_events f
  JOIN dim_products p USING (product_code)
  GROUP BY product_code, product_name, category
), r AS (
  SELECT *, DENSE_RANK() OVER (PARTITION BY category ORDER BY revenue_change DESC) AS category_rank
  FROM t
)
SELECT * FROM r WHERE category_rank <= 2
ORDER BY category, category_rank;
