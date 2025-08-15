/* 
	Clean "Customers" Table
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

-- Drop table
DROP TABLE IF EXISTS cleaned_customers;

-- Create the table to work with from the backup
CREATE TABLE cleaned_customers AS
SELECT * FROM backup_customers;

-- Initial look at the table
SELECT *
FROM cleaned_customers;

-- Check column data types
DESCRIBE cleaned_customers;

-- Change signup_date column to DATE data type
ALTER TABLE cleaned_customers
MODIFY COLUMN signup_date DATE;

-- Add Primary Key column
ALTER TABLE cleaned_customers
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- Locate all first names with an 'x' in it
SELECT *
FROM cleaned_customers
WHERE first_name LIKE '%x%';

-- Checking if they have any duplicates in which only customer_id 85 does
SELECT *
FROM cleaned_customers
WHERE customer_id IN (11, 21, 24, 64, 85);

-- Updating three first names where the 'a' should be an 'x'
UPDATE cleaned_customers
SET first_name = REPLACE(first_name, 'x', 'a')
WHERE first_name IN ('Mxria', 'Sxmuel', 'Jxson');

-- Update the 'x' to an 'r'
UPDATE cleaned_customers
SET first_name = 'Kristen'
WHERE first_name = 'Kxisten';

-- Update customer_id 85 anyway to make it a true duplicate for removing later
UPDATE cleaned_customers
SET first_name = 'George'
WHERE first_name = 'Gxorge';

SELECT customer_id, first_name, last_name, email, COUNT(customer_id)
FROM cleaned_customers
GROUP BY customer_id, first_name, last_name, email;

-- Finds all the customer_id that has 2 counts or more appearing 
-- (should be a unique column but currently isn't)
SELECT *
FROM (
	SELECT customer_id, COUNT(customer_id) AS count
	FROM cleaned_customers
	GROUP BY customer_id
) AS dupe_check
WHERE count > 1;

-- Bouncing off the previous query, want to return the complete rows
-- This returns all the customer_id rows counted as duplicates
SELECT *
FROM (
	SELECT *,
		COUNT(*) OVER (PARTITION BY customer_id) AS count
	FROM cleaned_customers
) AS dupe_check
WHERE count > 1;

-- Here's just another method to do the same as the above
-- Not as clean but good to be aware of
SELECT *
FROM cleaned_customers
WHERE customer_id IN (
	SELECT customer_id
    FROM cleaned_customers
    GROUP BY customer_id
	HAVING count(*) > 1
)
ORDER BY customer_id ASC;

-- Fill in the empty email for customer_id 82
-- I can do this direct update, but practicing scalability for larger datasets below
/*
UPDATE cleaned_customers
SET email = 'kmiller@hotmail.com'
WHERE customer_id = 82 AND email = '';
*/

-- This is to have scalable code that checks for duplicates that have an email value then populates it
-- in the blank versions of the duplicates, so then we can properly make sure we're deleting actual duplicates

-- Retrieves all the emails available
SELECT customer_id, first_name, last_name, MAX(email) AS filled_email
FROM cleaned_customers
WHERE email IS NOT NULL AND email != ''
GROUP BY customer_id, first_name, last_name;

-- Finds the rows where email is blank, and joins the two tables on that point
SELECT cc.*, src.filled_email
FROM cleaned_customers AS cc
JOIN (
	SELECT customer_id, first_name, last_name, MAX(email) AS filled_email
	FROM cleaned_customers
	WHERE email IS NOT NULL AND email != ''
	GROUP BY customer_id, first_name, last_name
) src
	ON cc.customer_id = src.customer_id
    AND cc.first_name = src.first_name
    AND cc.last_name = src.last_name
    AND (cc.email IS NULL OR cc.email = '');
    
-- On the rows that are duplicates but the email is blank for one of them, fill in with the found email value
UPDATE cleaned_customers AS cc
JOIN (
	SELECT customer_id, first_name, last_name, MAX(email) AS filled_email
	FROM cleaned_customers
	WHERE email IS NOT NULL AND email != ''
	GROUP BY customer_id, first_name, last_name
) src
	ON cc.customer_id = src.customer_id
    AND cc.first_name = src.first_name
    AND cc.last_name = src.last_name
	AND (cc.email IS NULL or cc.email = '')
SET cc.email = src.filled_email;

-- Verify updates took place (in this case, only customer_id 82 fits this)
SELECT *
FROM cleaned_customers
WHERE customer_id = 82;

-- Other blank emails don't have a duplicate with an email value to fill in, that's fine
SELECT *
FROM cleaned_customers
WHERE email = '';

# Handling Duplicates

-- Finding all the duplicates
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY customer_id, first_name, last_name, email, signup_date) AS dup_count
FROM cleaned_customers;

-- Making sure the query selects the correct rows to remove (using CTE here for practice)
WITH remove_dups AS (
	SELECT *,
		ROW_NUMBER() OVER (PARTITION BY customer_id, first_name, last_name, email, signup_date) AS dup_count
	FROM cleaned_customers
)
SELECT *
FROM remove_dups
WHERE dup_count > 1;

-- Making sure the query selects the correct rows to remove (using subquery here for practice)
SELECT id
FROM (
	SELECT *,
    ROW_NUMBER() OVER (PARTITION BY customer_id, first_name, last_name, email, signup_date) AS dup_count
    FROM cleaned_customers
) AS temp_table
WHERE dup_count > 1;

-- Creating a temporary table with IDs of the duplicates
-- Cannot filter directly inside the DELETE operation
CREATE TEMPORARY TABLE temp_dupes AS
SELECT id
FROM (
	SELECT *,
    ROW_NUMBER() OVER (PARTITION BY customer_id, first_name, last_name, email, signup_date) AS dup_count
    FROM cleaned_customers
) AS temp_table
WHERE dup_count > 1;

-- Delete those duplicates from the original table
DELETE FROM cleaned_customers
WHERE id IN (SELECT id FROM temp_dupes);

SELECT *
FROM cleaned_customers;

-- Clean up temp table
DROP TEMPORARY TABLE IF EXISTS temp_dupes;

# I want to reset my id to be 1-100 since 81 id was removed and I want it as ids 1-100

-- Drop the id column first
ALTER TABLE cleaned_customers DROP COLUMN id;

-- Create a temporary table with the same structure and sorted data
CREATE TEMPORARY TABLE temp_cleaned_customers AS
SELECT *
FROM cleaned_customers
ORDER BY customer_id ASC;

-- Truncate the original table (removes all rows)
TRUNCATE TABLE cleaned_customers;

-- Insert sorted data back into original table
INSERT INTO cleaned_customers
SELECT *
FROM temp_cleaned_customers;

-- Clean up temp table
DROP TEMPORARY TABLE IF EXISTS temp_cleaned_customers;

-- Making customer_id the primary key now as this shouldn't have any duplicates
-- anything added later will be uniquely imcremented
ALTER TABLE cleaned_customers
ADD PRIMARY KEY (customer_id);

-- Final Result
SELECT *
FROM cleaned_customers;