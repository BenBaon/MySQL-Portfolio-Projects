/* 
	Create Backup Tables
*/

# Create backup tables so the scripts later don't touch the raw datasets as an extra safety net

-- Makes sure we're always using the correct database
USE retail_orders;

-- ======================
-- Customers Backup Table
-- ======================

-- 1. Drop the old backup version if it exists
DROP TABLE IF EXISTS backup_customers;

-- 2. Create a new backup version by selecting from the original
CREATE TABLE backup_customers AS
SELECT *
FROM raw_customers;

-- ======================
-- Order_Details Backup Table
-- ======================

-- 1. Drop the old backup version if it exists
DROP TABLE IF EXISTS backup_order_details;

-- 2. Create a new backup version by selecting from the original
CREATE TABLE backup_order_details AS
SELECT *
FROM raw_order_details;

-- ======================
-- Orders Backup Table
-- ======================

-- 1. Drop the old backup version if it exists
DROP TABLE IF EXISTS backup_orders;

-- 2. Create a new backup version by selecting from the original
CREATE TABLE backup_orders AS
SELECT *
FROM raw_orders;

-- ======================
-- Order_Details Backup Table
-- ======================

-- 1. Drop the old cleaned version if it exists
DROP TABLE IF EXISTS backup_products;

-- 2. Create a new backup version by selecting from the original
CREATE TABLE backup_products AS
SELECT *
FROM raw_products;