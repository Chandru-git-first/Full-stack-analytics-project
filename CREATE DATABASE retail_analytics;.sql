CREATE DATABASE retail_analytics;
SELECT current_database();

CREATE TABLE raw_retail (
    invoice TEXT,
    stock_code TEXT,
    description TEXT,
    quantity TEXT,
    invoice_date TEXT,
    price TEXT,
    customer_id TEXT,
    country TEXT,
    source_sheet TEXT
);

SELECT COUNT(*) FROM raw_retail;
SELECT * FROM raw_retail LIMIT 10;
SELECT * FROM raw_retail WHERE stock_code = 'B';

CREATE TABLE staging_retail AS
SELECT
    invoice,
    stock_code,
    description,
    CAST(quantity AS INTEGER) AS quantity,
    CAST(invoice_date AS TIMESTAMP) AS invoice_date,
    CAST(price AS NUMERIC(10,2)) AS price,
    CAST(NULLIF(customer_id, '') AS INTEGER) AS customer_id,
    country,
    source_sheet
FROM raw_retail;

CREATE TABLE staging_retail AS
SELECT
    invoice,
    stock_code,
    description,
    CAST(quantity AS INTEGER) AS quantity,
    CAST(invoice_date AS TIMESTAMP) AS invoice_date,
    CAST(price AS NUMERIC(10,2)) AS price,
    CAST(CAST(NULLIF(customer_id, '') AS NUMERIC) AS INTEGER) AS customer_id,
    country,
    source_sheet
FROM raw_retail;

SELECT COUNT(*) FROM staging_retail;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'staging_retail';

SELECT * FROM staging_retail WHERE invoice = '489434' LIMIT 5;

ALTER TABLE staging_retail ADD COLUMN transaction_type TEXT;

UPDATE staging_retail
SET transaction_type = CASE
    WHEN invoice LIKE 'C%' THEN 'Cancellation'
    WHEN invoice LIKE 'A%' THEN 'Bad Debt Adjustment'
    WHEN stock_code IN ('POST', 'DOT', 'C2') THEN 'Postage'
    WHEN stock_code = 'D' THEN 'Discount'
    WHEN stock_code IN ('BANK CHARGES', 'AMAZONFEE', 'CRUK') THEN 'Fee/Commission'
    WHEN stock_code IN ('M', 'm', 'S', 'ADJUST', 'ADJUST2') THEN 'Manual Adjustment'
    WHEN stock_code IN ('TEST001', 'TEST002') THEN 'Test Data'
    WHEN stock_code LIKE 'gift_0001%' THEN 'Gift Voucher'
    ELSE 'Product Sale'
END;

ALTER TABLE staging_retail ADD COLUMN transaction_type TEXT;

UPDATE staging_retail
SET transaction_type = CASE
    WHEN invoice LIKE 'C%' THEN 'Cancellation'
    WHEN invoice LIKE 'A%' THEN 'Bad Debt Adjustment'
    WHEN stock_code IN ('POST', 'DOT', 'C2') THEN 'Postage'
    WHEN stock_code = 'D' THEN 'Discount'
    WHEN stock_code IN ('BANK CHARGES', 'AMAZONFEE', 'CRUK') THEN 'Fee/Commission'
    WHEN stock_code IN ('M', 'm', 'S', 'ADJUST', 'ADJUST2') THEN 'Manual Adjustment'
    WHEN stock_code IN ('TEST001', 'TEST002') THEN 'Test Data'
    WHEN stock_code LIKE 'gift_0001%' THEN 'Gift Voucher'
    ELSE 'Product Sale'
END;

ALTER TABLE staging_retail ADD COLUMN transaction_type TEXT;

UPDATE staging_retail
SET transaction_type = CASE
    WHEN invoice LIKE 'C%' THEN 'Cancellation'
    WHEN invoice LIKE 'A%' THEN 'Bad Debt Adjustment'
    WHEN stock_code IN ('POST', 'DOT', 'C2') THEN 'Postage'
    WHEN stock_code = 'D' THEN 'Discount'
    WHEN stock_code IN ('BANK CHARGES', 'AMAZONFEE', 'CRUK') THEN 'Fee/Commission'
    WHEN stock_code IN ('M', 'm', 'S', 'ADJUST', 'ADJUST2') THEN 'Manual Adjustment'
    WHEN stock_code IN ('TEST001', 'TEST002') THEN 'Test Data'
    WHEN stock_code LIKE 'gift_0001%' THEN 'Gift Voucher'
    ELSE 'Product Sale'
END;

SELECT transaction_type, COUNT(*) 
FROM staging_retail 
GROUP BY transaction_type 
ORDER BY COUNT(*) DESC;

SELECT COUNT(*) 
FROM staging_retail 
WHERE quantity < 0 
  AND price = 0 
  AND transaction_type = 'Product Sale';

  SELECT description, COUNT(*) 
FROM staging_retail 
WHERE quantity < 0 
  AND price = 0 
  AND transaction_type = 'Product Sale'
GROUP BY description
ORDER BY COUNT(*) DESC
LIMIT 30;

UPDATE staging_retail
SET transaction_type = 'Stock Write-off'
WHERE quantity < 0 
  AND price = 0 
  AND transaction_type = 'Product Sale';

  SELECT transaction_type, COUNT(*) 
FROM staging_retail 
GROUP BY transaction_type 
ORDER BY COUNT(*) DESC;

SELECT COUNT(*) 
FROM staging_retail 
WHERE quantity < 0 
  AND transaction_type = 'Product Sale';

  DELETE FROM staging_retail WHERE transaction_type = 'Test Data';

SELECT transaction_type, COUNT(*) as duplicate_group_count
FROM (
    SELECT *, COUNT(*) OVER (PARTITION BY invoice, stock_code, quantity, invoice_date, price, customer_id) as dup_count
    FROM staging_retail
) sub
WHERE dup_count > 1
GROUP BY transaction_type
ORDER BY duplicate_group_count DESC;


SELECT transaction_type, COUNT(*) as rows_in_duplicate_groups
FROM (
    SELECT *, COUNT(*) OVER (
        PARTITION BY invoice, stock_code, description, quantity, invoice_date, price, customer_id, country
    ) as dup_count
    FROM staging_retail
) sub
WHERE dup_count > 1
GROUP BY transaction_type
ORDER BY rows_in_duplicate_groups DESC;

SELECT SUM(dup_count - 1) as excess_duplicate_rows
FROM (
    SELECT DISTINCT invoice, stock_code, description, quantity, invoice_date, price, customer_id, country,
        COUNT(*) OVER (
            PARTITION BY invoice, stock_code, description, quantity, invoice_date, price, customer_id, country
        ) as dup_count
    FROM staging_retail
) sub
WHERE dup_count > 1;


ALTER TABLE staging_retail ADD COLUMN is_possible_duplicate BOOLEAN DEFAULT FALSE;

UPDATE staging_retail t
SET is_possible_duplicate = TRUE
FROM (
    SELECT ctid,
        ROW_NUMBER() OVER (
            PARTITION BY invoice, stock_code, description, quantity, invoice_date, price, customer_id, country
            ORDER BY ctid
        ) as rn
    FROM staging_retail
) sub
WHERE t.ctid = sub.ctid AND sub.rn > 1;

SELECT is_possible_duplicate, COUNT(*) 
FROM staging_retail 
GROUP BY is_possible_duplicate;


SELECT 
    DATE_TRUNC('month', invoice_date) AS month,
    SUM(quantity * price) AS total_revenue,
    COUNT(DISTINCT invoice) AS num_orders
FROM staging_retail
WHERE transaction_type = 'Product Sale'
GROUP BY DATE_TRUNC('month', invoice_date)
ORDER BY month;

SELECT MIN(invoice_date), MAX(invoice_date)
FROM staging_retail
WHERE transaction_type = 'Product Sale';

SELECT MAX(invoice_date) 
FROM staging_retail 
WHERE transaction_type = 'Product Sale' 
  AND invoice_date >= '2011-12-01';


  SELECT 
    DATE_TRUNC('month', invoice_date) AS month,
    SUM(quantity * price) AS total_revenue,
    COUNT(DISTINCT invoice) AS num_orders,
    CASE 
        WHEN DATE_TRUNC('month', invoice_date) = '2011-12-01' THEN TRUE 
        ELSE FALSE 
    END AS is_partial_month
FROM staging_retail
WHERE transaction_type = 'Product Sale'
GROUP BY DATE_TRUNC('month', invoice_date)
ORDER BY month;


SELECT 
    stock_code,
    description,
    SUM(quantity) AS total_quantity,
    SUM(quantity * price) AS total_revenue
FROM staging_retail
WHERE transaction_type = 'Product Sale'
GROUP BY stock_code, description
ORDER BY total_revenue DESC
LIMIT 20;

SELECT invoice, quantity, price, invoice_date, customer_id
FROM staging_retail
WHERE stock_code = '23843' AND transaction_type = 'Product Sale'
ORDER BY quantity DESC
LIMIT 5;

ALTER TABLE staging_retail ADD COLUMN is_extreme_quantity BOOLEAN DEFAULT FALSE;

UPDATE staging_retail
SET is_extreme_quantity = TRUE
WHERE quantity > 5000 AND transaction_type = 'Product Sale';

SELECT COUNT(*) FROM staging_retail WHERE is_extreme_quantity = TRUE;

SELECT 
    stock_code,
    description,
    SUM(quantity) AS total_quantity,
    SUM(quantity * price) AS total_revenue
FROM staging_retail
WHERE transaction_type = 'Product Sale' AND is_extreme_quantity = FALSE
GROUP BY stock_code, description
ORDER BY total_revenue DESC
LIMIT 20;


  SELECT 
    country,
    COUNT(DISTINCT invoice) AS num_orders,
    SUM(quantity) AS total_quantity,
    SUM(quantity * price) AS total_revenue
FROM staging_retail
WHERE transaction_type = 'Product Sale' AND is_extreme_quantity = FALSE
GROUP BY country
ORDER BY total_revenue DESC
LIMIT 20;

WITH customer_orders AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT invoice) AS num_orders,
        SUM(quantity * price) AS total_revenue
    FROM staging_retail
    WHERE transaction_type = 'Product Sale' 
      AND is_extreme_quantity = FALSE
      AND customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT 
    CASE WHEN num_orders = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,
    COUNT(*) AS num_customers,
    SUM(total_revenue) AS total_revenue,
    ROUND(AVG(total_revenue), 2) AS avg_revenue_per_customer
FROM customer_orders
GROUP BY CASE WHEN num_orders = 1 THEN 'One-time' ELSE 'Repeat' END;


SELECT 
    customer_id,
    country,
    COUNT(DISTINCT invoice) AS num_orders,
    SUM(quantity * price) AS total_revenue
FROM staging_retail
WHERE transaction_type = 'Product Sale' 
  AND is_extreme_quantity = FALSE
  AND customer_id IS NOT NULL
GROUP BY customer_id, country
ORDER BY total_revenue DESC
LIMIT 10;



SELECT 
    (SELECT SUM(quantity * price) FROM staging_retail WHERE transaction_type = 'Cancellation') AS cancelled_value,
    (SELECT SUM(quantity * price) FROM staging_retail WHERE transaction_type = 'Product Sale' AND is_extreme_quantity = FALSE) AS gross_sales_value;


SELECT COUNT(*) AS writeoff_line_items, SUM(ABS(quantity)) AS total_units_written_off
FROM staging_retail
WHERE transaction_type = 'Stock Write-off';












