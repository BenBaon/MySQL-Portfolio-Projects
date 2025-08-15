/* 
	Clean "Products" Table
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
DROP TABLE IF EXISTS cleaned_products;

-- Create the table to work with from the backup
CREATE TABLE cleaned_products AS
SELECT * FROM backup_products;

-- Initial look at table
SELECT *
FROM cleaned_products;

-- Check table structure
DESCRIBE cleaned_products;

-- Set product_id as the key
ALTER TABLE cleaned_products
ADD PRIMARY KEY (product_id);

# Standardize Data

-- Chcked for all distinct categories
SELECT DISTINCT category
FROM cleaned_products;

-- Seeing what the collation is for all columns since categories didn't return expected results
-- Seeing categories column is case-insensitive, since it's not necessary however to change the collation, leaving as is
SHOW FULL COLUMNS FROM cleaned_products;

-- If I wanted to convert to case-sensitive though, I could run the following
/* ALTER TABLE cleaned_products
MODIFY category VARCHAR(255) COLLATE utf8mb4_bin; */

-- Verifying query cleans the casing for categories properly
SELECT CONCAT(UPPER(LEFT(category, 1)), LOWER(SUBSTRING(category, 2))) AS clean_cats
FROM cleaned_products;

-- Updating category data based on previous query
UPDATE cleaned_products
SET category = CONCAT(UPPER(LEFT(category, 1)), LOWER(SUBSTRING(category, 2)));

-- Final result
SELECT *
FROM cleaned_products;