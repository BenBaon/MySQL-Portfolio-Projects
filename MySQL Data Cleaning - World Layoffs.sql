-- MySQL Data Cleaning Project

-- Source: layoffs.csv

-- GOAL --
-- 1. Create staging table (don't change raw data table)
-- 2. Remove duplicates
-- 3. Standardize the data
-- 4. Handle NULL values or blank data
-- 5. Remove unnecessary columns

# Checking imported table from .csv file
SELECT *
FROM layoffs;


-- Create Staging Table --

## Create staging table in which we can manipulate the data without worry
CREATE TABLE layoffs_staging
LIKE layoffs;

# Insert the data from original into staging table
INSERT layoffs_staging
SELECT *
FROM layoffs;

# Verify data is in staging table
SELECT *
FROM layoffs_staging;


-- REMOVE DUPLICATES --

## Query for any duplicate rows in which row_num > 1
# Partition by every column just to be safe as there's very similar rows
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, 
stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

# CTE for filtering row_num > 1
WITH duplicate_cte AS
(
	SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, 
	stage, country, funds_raised_millions) AS row_num
	FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

# Verify companies that show duplicates to verify there are in fact duplicate rows
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

SELECT *
FROM layoffs_staging
WHERE company = 'Cazoo';

SELECT *
FROM layoffs_staging
WHERE company = 'Hibob';

SELECT *
FROM layoffs_staging
WHERE company = 'Wildlife Studios';

SELECT *
FROM layoffs_staging
WHERE company = 'Yahoo';

# Create another table based off CTE query | layoffs_staging - Copy to clipboard - Create statement
# This table is the one we'll be deleting the extra rows since we can't delete directly from CTE
CREATE TABLE `layoffs_staging_2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

# Verify table has been created
SELECT *
FROM layoffs_staging_2;

# Insert the data from partition previously
INSERT INTO layoffs_staging_2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, 
stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

# Verify previous company and row_num duplicates
SELECT *
FROM layoffs_staging_2
WHERE company = 'Casper';

# Identify the extra rows
# Filter table where row_num > 1
SELECT *
FROM layoffs_staging_2
WHERE row_num > 1;

# Delete duplicate rows
# Verified with SELECT statement that these rows are removed
DELETE
FROM layoffs_staging_2
WHERE row_num > 1;


-- Standardizing Data

## View table
SELECT *
FROM layoffs_staging_2;

# Company needs to be trimmed	
SELECT DISTINCT company, TRIM(company)
FROM layoffs_staging_2;

# Trim company column
UPDATE layoffs_staging_2
SET company = TRIM(company);

# Checking industry column
# NULL, blank, and similar values (Crypto) that need to be consolidated
SELECT DISTINCT industry
FROM layoffs_staging_2
ORDER BY industry;

# Identify Crypto rows that need to be consolidated
SELECT *
FROM layoffs_staging_2
WHERE industry LIKE 'Crypto%';

# Update the rows to singular Crypto
UPDATE layoffs_staging_2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

# Check industry column again to verify the changes went through
SELECT *
FROM layoffs_staging_2
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT industry
FROM layoffs_staging_2
ORDER BY industry;


## Check overall table
SELECT *
FROM layoffs_staging_2;

# Checking country column
# Extra 'United States.' with a period at the end
SELECT DISTINCT country
FROM layoffs_staging_2
ORDER BY country;

# Checking TRIM function to remove period
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging_2
WHERE country LIKE 'United States%'
ORDER BY country;

# Implement the TRIM to table
UPDATE layoffs_staging_2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';


## Date data type format conversion test
# Str-to-date conversion 2nd parameter is to specify column value format
# Since we have it as mm/dd/yyyy, it has to be %m/%d/%Y
# SQL date type format is yyyy-mm-dd
SELECT `date`,
str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging_2;

# Update the date column values to proper date format | yyyy-mm-dd
UPDATE layoffs_staging_2
SET `date` = str_to_date(`date`, '%m/%d/%Y');

# Verify the updates went through accordingly
SELECT `date`
FROM layoffs_staging_2;

# Change the date column data type to DATE
ALTER TABLE layoffs_staging_2
MODIFY COLUMN `date` DATE;


-- Handle NULL and Blank Data

## Checking industry column for NULLs and blanks
SELECT *
FROM layoffs_staging_2
WHERE industry IS NULL
OR industry = '';

# Looking at one of the companies populated previously
# We can fill in the blanks so these rows are included in the report for accurate analysis
SELECT *
FROM layoffs_staging_2
WHERE company = 'Airbnb';

# Testing JOIN logic for a self join
# Looks in t2 for values to populate in blanks for t1
# Based of matching company and industry values
SELECT t1.industry, t2.industry
FROM layoffs_staging_2 t1
JOIN layoffs_staging_2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
	AND t2.industry IS NOT NULL
	AND t2.industry != '';

# Update the blanks for industry column
UPDATE layoffs_staging_2 t1
JOIN layoffs_staging_2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
	AND t2.industry IS NOT NULL
    AND t2.industry <> '';
    
# Verify industry column no longer has NULL or blanks
# There's still one more NULL
SELECT DISTINCT industry
FROM layoffs_staging_2
ORDER BY industry;

# Check the NULL row
SELECT *
FROM layoffs_staging_2
WHERE industry IS NULL
OR industry = '';

# Check rows with Bally's Interactive
# There's only one row so comparison update query didn't apply earlier
# Can't update this with anything similar
SELECT *
FROM layoffs_staging_2
WHERE company = "Bally's Interactive";


## Checking location column
# Seeing a few strange characters in some values
SELECT DISTINCT location, country
FROM layoffs_staging_2
ORDER BY location;

# Checking the locations with incorrect symbols
SELECT *
FROM layoffs_staging_2
WHERE location = 'DÃ¼sseldorf'
	OR location = 'FlorianÃ³polis'
    OR location = 'MalmÃ¶';

# Update the locations values to appropriate naming
UPDATE layoffs_staging_2
SET location = 'Dusseldorf'
WHERE location = 'DÃ¼sseldorf';

UPDATE layoffs_staging_2
SET location = 'Florianopolis'
WHERE location = 'FlorianÃ³polis';

UPDATE layoffs_staging_2
SET location = 'Malmo'
WHERE location = 'MalmÃ¶';


## Checking NULL data rows to be removed
# Can't fill in this data so in this scenario we can remove it
SELECT *
FROM layoffs_staging_2
WHERE total_laid_off IS NULL
	AND percentage_laid_off IS NULL;
    
# Remove rows with NULL data for total_laid_off and percentage_laid_off
DELETE
FROM layoffs_staging_2
WHERE total_laid_off IS NULL
	AND percentage_laid_off IS NULL;
    
    
-- Remove unnecessary columns

## Remove columns that aren't needed
# No longer needing row_num
ALTER TABLE layoffs_staging_2
DROP COLUMN row_num;
