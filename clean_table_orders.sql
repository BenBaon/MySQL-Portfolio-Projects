/* 
	Clean "Orders" Table
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
DROP TABLE IF EXISTS cleaned_orders;

-- Create the table to work with from the backup
CREATE TABLE cleaned_orders AS
SELECT * FROM backup_orders;

-- Initial look at table
SELECT *
FROM cleaned_orders;

-- Check table structure
DESCRIBE cleaned_orders;

# Set Proper Data Types

-- Change order_date column to a DATE data type
ALTER TABLE cleaned_orders
MODIFY COLUMN order_date DATE;

# Handling Duplicates

-- Since order_id isn't unique currently, we need to set a different id column as the Primary Key
ALTER TABLE cleaned_orders
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- Verifying id column
SHOW FULL COLUMNS FROM cleaned_orders;

-- This returns a single row of each duplicate
SELECT *
FROM (
	SELECT id, order_id, customer_id, order_date, order_status,
		ROW_NUMBER() OVER (PARTITION BY order_id, customer_id, order_date, order_status) AS row_num
	FROM cleaned_orders
) AS dupe_check
WHERE row_num > 1;

-- This returns all rows that have more than 1 count for a complete overview
SELECT *
FROM (
	SELECT id, order_id, customer_id, order_date, order_status,
		COUNT(*) OVER (PARTITION BY order_id, customer_id, order_date, order_status) AS count_rows
	FROM cleaned_orders
) AS dupe_check
WHERE count_rows > 1;

-- Create temporary table for deleting duplicates
CREATE TEMPORARY TABLE IF NOT EXISTS temp_dupes AS
SELECT id
FROM (
	-- Doing by row_num since this returns just the duplicated rows
	SELECT id, order_id, customer_id, order_date, order_status,
		ROW_NUMBER() OVER (PARTITION BY order_id, customer_id, order_date, order_status) AS row_num
	FROM cleaned_orders
) AS temp_table
WHERE row_num > 1;

-- Verifying temp_dupes table, rows to be deleted
SELECT *
FROM temp_dupes;

-- Delete from original table based on identified rows
DELETE FROM cleaned_orders
WHERE id IN (SELECT id FROM temp_dupes);

-- Clean up temporary table after use
DROP TEMPORARY TABLE IF EXISTS temp_dupes;

ALTER TABLE cleaned_orders
DROP COLUMN id;

-- Verification that order_id and customer_id have no duplicates
SELECT order_id, customer_id, COUNT(*)
FROM cleaned_orders
GROUP BY order_id, customer_id
HAVING COUNT(*) > 1;

-- Verifying there's no duplicate order_id
SELECT order_id, COUNT(order_id) AS dupe
FROM cleaned_orders
GROUP BY order_id
HAVING dupe > 1;

-- Making order_id the Primary Key
ALTER TABLE cleaned_orders
ADD PRIMARY KEY (order_id);

-- Verification of Primary Key
DESCRIBE cleaned_orders;

-- Final Result
SELECT *
FROM cleaned_orders;