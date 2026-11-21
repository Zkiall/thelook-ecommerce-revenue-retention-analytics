WITH clean_orders AS (
  SELECT
    oi.order_id,
    oi.user_id,
    DATE(oi.created_at) AS order_date,
    oi.sale_price,
    p.cost,
    (oi.sale_price - p.cost) AS gross_profit
  FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
    ON oi.product_id = p.id
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
    AND DATE(oi.created_at) <= DATE '2026-10-31'
),
rfm_base AS (
  SELECT
    c.user_id,
    u.country,
    u.gender,
    u.traffic_source,
    DATE_DIFF(DATE '2026-10-31', MAX(c.order_date), DAY) AS recency_days,
    COUNT(DISTINCT c.order_id) AS frequency,
    ROUND(SUM(c.sale_price), 2) AS monetary,
    ROUND(SUM(c.gross_profit), 2) AS total_profit
  FROM clean_orders AS c
  JOIN `bigquery-public-data.thelook_ecommerce.users` AS u
    ON c.user_id = u.id
  GROUP BY c.user_id, u.country, u.gender, u.traffic_source
),
rfm_scores AS (
  SELECT
    *,
    NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
    CASE
      WHEN frequency = 1 THEN 1
      WHEN frequency = 2 THEN 3
      WHEN frequency = 3 THEN 4
      ELSE 5
    END AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
  FROM rfm_base
),
rfm_labeled AS (
  SELECT
    *,
    CASE
      WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
      WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
      WHEN r_score >= 4 AND f_score <= 2 THEN 'New / Recent Customers'
      WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk (High Value)'
      WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk (Regular)'
      WHEN r_score = 3 AND f_score <= 2 THEN 'Need Attention'
      ELSE 'Hibernating / Lost'
    END AS rfm_segment
  FROM rfm_scores
)
SELECT
  rfm_segment,
  country,
  gender,
  traffic_source,
  COUNT(*) AS total_customers,
  SUM(frequency) AS total_orders,
  ROUND(SUM(monetary), 2) AS total_revenue,
  ROUND(SUM(total_profit), 2) AS total_profit,
  ROUND(AVG(recency_days), 1) AS avg_recency_days
FROM rfm_labeled
GROUP BY rfm_segment, country, gender, traffic_source
ORDER BY rfm_segment, total_revenue DESC;