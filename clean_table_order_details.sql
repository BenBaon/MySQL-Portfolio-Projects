/* 
	Clean "Order_Details" Table
*/

-- General Cleaning Steps --
-- 1. Remove unnecessary columns
-- 2. Set proper data types
-- 3. Handle null and empty values
-- 4. Standardize data
-- 5. Drop duplicates

-- Makes sure the query is always running for the correct DB
USE retail_orders;

# Drops table in case script needs to be re-run from the start

-- Drops the table
DROP TABLE IF EXISTS cleaned_order_details;

-- Create the table to work with from the backup
CREATE TABLE cleaned_order_details AS
SELECT * FROM backup_order_details;

-- Initial look at table
SELECT *
FROM cleaned_order_details;

# Handling duplicates

-- Checking for duplicates in which order_id and product_id combination appear more than once
WITH dupe_check AS (
	SELECT order_id, product_id,
		ROW_NUMBER() OVER (PARTITION BY order_id, product_id) AS rn
	FROM cleaned_order_details
)
SELECT *
FROM dupe_check;

# Handle NULL and empty values

-- Check for nulls or empty values
SELECT *
FROM cleaned_order_details
WHERE order_id IS NULL OR order_id = '';

-- Check for nulls or empty values
SELECT *
FROM cleaned_order_details
WHERE quantity IS NULL OR quantity = '';

-- Check for nulls or empty values
SELECT *
FROM cleaned_order_details
WHERE product_id IS NULL OR product_id = '';

-- Final Result
SELECT *
FROM cleaned_order_details;