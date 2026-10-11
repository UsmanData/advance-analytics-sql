-- 1. Change-Over-Time Trends Analysis

-- Analyze Sales Performance Over Time (Yearly).
SELECT
  EXTRACT(YEAR FROM order_date) AS order_year,
  SUM(sales_amount) AS total_sales,
  COUNT(DISTINCT customer_key) AS total_customers,
  SUM(quantity) AS total_quantity
FROM
  fact_sales
WHERE
  order_date IS NOT NULL
GROUP BY
  EXTRACT(YEAR FROM order_date)
ORDER BY
  EXTRACT(YEAR FROM order_date)
;

-- Analyze Sales Performance Over Time (Monthly).
SELECT
  EXTRACT(MONTH FROM order_date) AS order_month,
  SUM(sales_amount) AS total_sales,
  COUNT(DISTINCT customer_key) AS total_customers,
  SUM(quantity) AS total_quantity
FROM
  fact_sales
WHERE
  order_date IS NOT NULL
GROUP BY
  EXTRACT(MONTH FROM order_date)
ORDER BY
  EXTRACT(MONTH FROM order_date)
;


-- 2. Cumulative Analysis

-- Calculate the total sales per month and the running total of sales over time.
SELECT
  order_date,
  total_sales,
  SUM(total_sales) OVER(ORDER BY order_date ASC) AS running_total
FROM (
  SELECT
    DATE_TRUNC('month', order_date) AS order_date,
    SUM(sales_amount) AS total_sales
  FROM
    fact_sales
  WHERE
    order_date IS NOT NULL
  GROUP BY
    DATE_TRUNC('month', order_date)
) t
;

-- Calculate the total sales per month and the running total of sales over time but on yearly basis.
SELECT
  order_date,
  total_sales,
  SUM(total_sales) OVER(PARTITION BY DATE_TRUNC('year', order_date) ORDER BY order_date ASC) AS running_total
FROM (
  SELECT
    DATE_TRUNC('month', order_date) AS order_date,
    SUM(sales_amount) AS total_sales
  FROM
    fact_sales
  WHERE
    order_date IS NOT NULL
  GROUP BY
    DATE_TRUNC('month', order_date)
) t
;

-- Calculate the average price per month and the moving average price over time.
SELECT
  order_date,
  avg_price,
  ROUND(AVG(avg_price) OVER(ORDER BY order_date ASC), 2) AS moving_average_price
FROM (
  SELECT
    DATE_TRUNC('month', order_date) AS order_date,
    ROUND(AVG(price), 2) AS avg_price
  FROM
    fact_sales
  WHERE
    order_date IS NOT NULL
  GROUP BY
    DATE_TRUNC('month', order_date)
) t
;


-- 3. Performance Analysis

-- Analyze the yearly performance of products by comparing each product's sale to both its average sales performance and the previous year's sales.
 
WITH yearly_product_sales AS(
  SELECT
    EXTRACT(YEAR FROM order_date) AS order_year,
    p.product_name AS product_name,
    SUM(f.sales_amount) AS current_sales
  FROM
    fact_sales AS f
  LEFT JOIN
    dim_products AS p
    ON f.product_key = p.product_key
  WHERE
    f.order_date IS NOT NULL
  GROUP BY
    EXTRACT(YEAR FROM order_date),
    p.product_name 
)
SELECT
  order_year,
  product_name,
  current_sales,
  ROUND(AVG(current_sales) OVER(PARTITION BY product_name), 2) AS avg_sales,
  current_sales - ROUND(AVG(current_sales) OVER(PARTITION BY product_name), 2) AS diff_avg,
  CASE
    WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Avg'
    WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Avg'
    ELSE 'Avg'
  END AS avg_change,
 
  LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS pre_yr_sales, 
  current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_py_sales,
  
  CASE
    WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
    WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
    ELSE 'No Change'
  END AS py_change
FROM
  yearly_product_sales
ORDER BY
  product_name,
  order_year
;


-- 4. Part-to-Whole Analysis

-- Which categories contribute the most to overall sales?
WITH cte_category_sales AS (
  SELECT
    p.category AS category,
    SUM(f.sales_amount) AS total_sales
  FROM
    fact_sales AS f
  LEFT JOIN
    dim_products AS p
    ON f.product_key = p.product_key
  GROUP BY
    p.category
)
SELECT
  category,
  total_sales,
  SUM(total_sales) OVER() AS overall_sales,
  CONCAT(ROUND((total_sales / SUM(total_sales) OVER()) * 100, 2), '%') AS percentage_of_total
FROM
  cte_category_sales
ORDER BY
  total_sales DESC
;


-- 5. Data Segmentation

-- Segment products into cost ranges and count how many products fall into each segment.
WITH cte_product_segments AS (
  SELECT
    product_key,
    product_name,
    cost,
    CASE
      WHEN cost < 100 THEN 'Below 100'
      WHEN cost BETWEEN 100 AND 500 THEN '100-500'
      WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
      ELSE 'Above 1000'
    END AS cost_range
  FROM
    dim_products
)
SELECT
  cost_range,
  COUNT(product_key) AS total_products
FROM
  cte_product_segments
GROUP BY
  cost_range
ORDER BY
  cost_range
;

-- Group customers into three segments based on their spending behavior:
  -- VIP: at least 12 months of history and spending more than $5000.
  -- Regular: at least 12 months of history but spending $5000 or less.
  -- New: lifespan less than 12 months.
-- And find the total number of customers by each group.

WITH cte_customer_spending AS (
  SELECT
    c.customer_key,
    SUM(f.sales_amount) AS total_spending,
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order,
    EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) * 12 + EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date))) AS lifespan
  FROM
    fact_sales AS f
  LEFT JOIN
    dim_customers AS c
    ON f.customer_key = c.customer_key
  GROUP BY
    c.customer_key
),
cte_customer_segments AS(
  SELECT
    customer_key,
    total_spending,
    lifespan,
    CASE
      WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP' 
      WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
      ELSE 'NEW' 
    END AS customer_segment
  FROM
    cte_customer_spending
)
SELECT
  customer_segment,
  COUNT(customer_key) AS total_customers
FROM
  cte_customer_segments
GROUP BY
  customer_segment
ORDER BY
  total_customers DESC
;


-- 6. Reporting – Customer Analytics Report

-- This is a report that consolidates key customer metrics and behaviors:

CREATE VIEW report_customers AS
(
WITH cte_base_query AS (
-- 1) Base Query: Retrieves core columns from tables
  SELECT
    f.order_number,
    f.product_key,
    f.order_date,
    f.sales_amount,
    f.quantity,
    c.customer_key,
    c.customer_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    DATE_PART('year', AGE(NOW(), c.birthdate)) AS age
  FROM
    fact_sales AS f
  LEFT JOIN
    dim_customers AS c
    ON f.customer_key = c.customer_key
  WHERE
    order_date IS NOT NULL
), cte_customer_aggregation AS (
-- 2) Customer Aggregations: Summarizes key metrics at the customer level
  SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT product_key) AS total_products,
    MAX(order_date) AS last_order_date,
    EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) * 12 + EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date))) AS lifespan
  FROM
    cte_base_query
  GROUP BY
    customer_key,
    customer_number,
    customer_name,
    age
)
SELECT
  customer_key,
  customer_number,
  customer_name,
  age,
 
  CASE
    WHEN age < 20 THEN 'Under 20'
    WHEN age BETWEEN 20 AND 29 THEN '20-29'
    WHEN age BETWEEN 30 AND 39 THEN '30-39'
    WHEN age BETWEEN 40 AND 49 THEN '40-49'
    ELSE '50 and above'
  END AS age_group,
 
  CASE
    WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP' 
    WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
    ELSE 'NEW' 
  END AS customer_segment,
 
  total_orders,
  total_sales,
  total_quantity,
  total_products,
  last_order_date,
  EXTRACT(YEAR FROM AGE(NOW(), last_order_date)) * 12 + EXTRACT(MONTH FROM AGE(NOW(), last_order_date)) AS recency,
 
  -- Compute average Order Value
  CASE 
    WHEN total_sales = 0 THEN 0
    WHEN total_orders = 0 THEN 0
    ELSE total_sales / total_orders 
  END AS avg_order_value,
 
  -- Compute average monthly spend
  CASE 
    WHEN lifespan = 0 THEN total_sales
    ELSE ROUND(total_sales / lifespan, 2)
  END AS avg_monthly_spend
FROM
  cte_customer_aggregation
)
;
