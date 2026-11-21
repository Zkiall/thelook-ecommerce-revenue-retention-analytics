SELECT
  status,
  COUNT(DISTINCT order_id) AS total_orders,
  COUNT(*) AS total_items,
  COUNT(DISTINCT user_id) AS unique_customers,
  MIN(DATE(created_at)) AS earliest_date,
  MAX(DATE(created_at)) AS latest_date,
  ROUND(SUM(sale_price), 2) AS total_gross_sales
FROM `bigquery-public-data.thelook_ecommerce.order_items`
GROUP BY status
ORDER BY total_orders DESC;

SELECT
  COUNT(*) AS total_rows,
  COUNTIF(oi.order_id IS NULL) AS null_order_id,
  COUNTIF(oi.user_id IS NULL) AS null_user_id,
  COUNTIF(oi.created_at IS NULL) AS null_date,
  COUNTIF(oi.sale_price <= 0 OR oi.sale_price IS NULL) AS invalid_price,
  COUNTIF(p.cost IS NULL OR p.cost <= 0) AS invalid_cost,
  COUNTIF(oi.sale_price < p.cost) AS negative_margin_items
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
  ON oi.product_id = p.id;