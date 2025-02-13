-- Exploratory Data Analysis --

-- Source: layoffs.csv

-- GOAL --
-- Explore the data using different analysis functions

# Initial overview of the table we'll be analyzing
SELECT *
FROM layoffs_staging_2;

# Checking the date range of table
# This seems to be during the time when Covid first hit to 3 years after
# MIN: 2020-03-11 | MAX: 2023-03-06
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging_2;

# Lets see which industries were affected the most
# Consumer and Retail were most affected, which makes a lot of sense during Covid
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY industry
ORDER BY `SUM(total_laid_off)` DESC;

# Adding all layoffs from each company to see which company
# has the highest total layoffs
SELECT company, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY company
ORDER BY `SUM(total_laid_off)` DESC;

# Taking a quick look at the max values for the two number layed off columns
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging_2;

# Seeing which companies went under completely and how many were laid off
SELECT *
FROM layoffs_staging_2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

# Seeing which ones had the most funding that went under completely
SELECT *
FROM layoffs_staging_2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

# Checking which countries had the most total layoffs
# United States by far has more layoffs, 7.125 times the second highest being India
SELECT country, SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY country
ORDER BY SUM(total_laid_off) DESC;

# Checking which dates had the most total  layoffs
SELECT `date`, SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY `date`
ORDER BY SUM(total_laid_off) DESC;

# How many total layoffs each year
SELECT YEAR(`date`) AS years, SUM(total_laid_off) AS year_total_layoffs
FROM layoffs_staging_2
WHERE `date` IS NOT NULL
GROUP BY years
ORDER BY years DESC;

# Companies in which countries had the most toal layoffs
SELECT country, SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY country
ORDER BY SUM(total_laid_off) DESC;

# Checking business stage layoff totals
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY stage
ORDER BY stage DESC;

# Total of each month's layoffs of each year
SELECT SUBSTRING(`date`, 1, 7) AS `Month`, SUM(total_laid_off)
FROM layoffs_staging_2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `Month`
ORDER BY `Month` ASC;

# CTE for rolling total layoffs over each month
WITH rolling_total AS
(
	SELECT SUBSTRING(`date`, 1, 7) AS `Month`, SUM(total_laid_off) AS total_off
	FROM layoffs_staging_2
	WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
	GROUP BY `Month`
	ORDER BY `Month` ASC
)
SELECT `Month`, total_off, 
SUM(total_off) OVER (ORDER BY `Month`) AS Rolling_Total
FROM rolling_total;

# Company total layoffs each year in descending order
SELECT company, YEAR(`date`), SUM(total_laid_off) AS total_off
FROM layoffs_staging_2
GROUP BY company, YEAR(`date`)
ORDER BY total_off DESC;

# Sequential CTEs to retrieve 1-5 rankings of companies with most layoffs
# First CTE that aggregates layoffs by company and year
WITH company_year (company, years, total_laid_off) AS
(
	SELECT company, YEAR(`date`), SUM(total_laid_off) AS total_off
	FROM layoffs_staging_2
	GROUP BY company, YEAR(`date`)
),
# Second CTE bounces off the first, assigns rankings to each companies based on total layoffs,
# partitioning by years
company_year_rank AS
(
	SELECT *,
	DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
	FROM company_year
	WHERE years IS NOT NULL
)
# Returning companies rank 5 and above
SELECT *
FROM company_year_rank
WHERE Ranking <= 5;

-- END
