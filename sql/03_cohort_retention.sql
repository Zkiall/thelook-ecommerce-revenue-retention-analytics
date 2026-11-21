WITH valid_orders AS (
  SELECT
    user_id,
    DATE_TRUNC(DATE(created_at), MONTH) AS order_month
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
    AND DATE(created_at) <= DATE '2026-10-31'
  GROUP BY user_id, order_month
),
user_cohorts AS (
  SELECT
    user_id,
    MIN(order_month) AS cohort_month
  FROM valid_orders
  GROUP BY user_id
),
cohort_activity AS (
  SELECT
    uc.cohort_month,
    DATE_DIFF(vo.order_month, uc.cohort_month, MONTH) AS month_index,
    COUNT(DISTINCT vo.user_id) AS active_users
  FROM user_cohorts AS uc
  JOIN valid_orders AS vo
    ON uc.user_id = vo.user_id
  WHERE uc.cohort_month >= DATE '2025-11-01'
  GROUP BY uc.cohort_month, month_index
),
cohort_sizes AS (
  SELECT
    cohort_month,
    active_users AS cohort_size
  FROM cohort_activity
  WHERE month_index = 0
)
SELECT
  ca.cohort_month,
  cs.cohort_size,
  ca.month_index,
  ca.active_users,
  ROUND(SAFE_DIVIDE(ca.active_users, cs.cohort_size) * 100, 2) AS retention_rate_pct
FROM cohort_activity AS ca
JOIN cohort_sizes AS cs
  ON ca.cohort_month = cs.cohort_month
ORDER BY ca.cohort_month, ca.month_index;