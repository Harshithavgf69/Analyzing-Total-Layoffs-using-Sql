-- SQL Project - Data Cleaning

-- https://www.kaggle.com/datasets/swaptr/layoffs-2022






SELECT * 
FROM world_layoffs.layoffs;



-- first thing we want to do is create a staging table. This is the one we will work in and clean the data. We want a table with the raw data in case something happens
CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

INSERT layoffs_staging 
SELECT * FROM world_layoffs.layoffs;


-- now when we are data cleaning we usually follow a few steps
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values and see what 
-- 4. remove any columns and rows that are not necessary - few ways



-- 1. Remove Duplicates

# First let's check for duplicates



SELECT *
FROM world_layoffs.layoffs_staging
;

SELECT company, industry, total_laid_off,`date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off,`date`) AS row_num
	FROM 
		world_layoffs.layoffs_staging;



SELECT *
FROM (
	SELECT company, industry, total_laid_off,`date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off,`date`
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;
    
-- let's just look at oda to confirm
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = 'Oda'
;
-- it looks like these are all legitimate entries and shouldn't be deleted. We need to really look at every single row to be accurate

-- these are our real duplicates 
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;

-- these are the ones we want to delete where the row number is > 1 or 2or greater essentially

-- now you may want to write it like this:
WITH DELETE_CTE AS 
(
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1
)
DELETE
FROM DELETE_CTE
;


WITH DELETE_CTE AS (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, 
    ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM world_layoffs.layoffs_staging
)
DELETE FROM world_layoffs.layoffs_staging
WHERE (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num) IN (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num
	FROM DELETE_CTE
) AND row_num > 1;

-- one solution, which I think is a good one. Is to create a new column and add those row numbers in. Then delete where row numbers are over 2, then delete that column
-- so let's do it!!

ALTER TABLE world_layoffs.layoffs_staging ADD row_num INT;


SELECT *
FROM world_layoffs.layoffs_staging
;

CREATE TABLE `world_layoffs`.`layoffs_staging2` (
`company` text,
`location`text,
`industry`text,
`total_laid_off` INT,
`percentage_laid_off` text,
`date` text,
`stage`text,
`country` text,
`funds_raised_millions` int,
row_num INT
);

INSERT INTO `world_layoffs`.`layoffs_staging2`
(`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`)
SELECT `company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging;

-- now that we have this we can delete rows were row_num is greater than 2



SET SQL_SAFE_UPDATES = 0;

-- Delete rows where row_num is greater than or equal to 2
DELETE 
FROM world_layoffs.layoffs_staging2
WHERE row_num >= 2;

-- standardize the data 

# removing the spaces before and after the company name 
select company, trim(Company) from world_layoffs.layoffs_staging2;
-- now update the new compant column 

update world_layoffs.layoffs_staging2 set Company = trim(Company);

-- now we check for different industries and see if there is any with same name or some thing repeated twice 

select distinct  industry from world_layoffs.layoffs_staging2 order by 1;
select industry from world_layoffs.layoffs_staging2 where industry like 'crypto%';
update world_layoffs.layoffs_staging2 
set industry = 'crypto' where industry like 'crypto%';

update world_layoffs.layoffs_staging2 
set country = 'unitedstates' where industry like 'unitedsta%';
select distinct  country from world_layoffs.layoffs_staging2 order by 1;
select country, trim(trailing '.' from country) from world_layoffs.layoffs_staging2;

update world_layoffs.layoffs_staging2 
set country = trim(trailing '.' from country) where country like 'united stat%';

SELECT *
FROM world_layoffs.layoffs_staging2;

-- we can use str to date to update this field
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- now we can convert the data type properly
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- nulls and blank values 

select * from layoffs_staging2 where total_laid_off is null and percentage_laid_off is null;

select * from layoffs_staging2 where industry is null or industry = ' ';

-- 4. remove any columns and rows we need to

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL;


SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete Useless data we can't really use
DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM world_layoffs.layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


SELECT * 
FROM world_layoffs.layoffs_staging2;

-- explanatory data analysis

select max(total_laid_off), max(percentage_laid_off) from world_layoffs.layoffs_staging2;

select sum(total_laid_off), industry from world_layoffs.layoffs_staging2
group by industry order by 1 desc;

select sum(total_laid_off), country from world_layoffs.layoffs_staging2
group by country order by 1 desc;

select sum(total_laid_off), date from world_layoffs.layoffs_staging2
group by date order by 1 desc;

select sum(total_laid_off), year(date) from world_layoffs.layoffs_staging2
group by year(date) order by 1 desc;

-- Earlier we looked at Companies with the most Layoffs. Now let's look at that per year. It's a little more difficult.
-- I want to look at 

select substring(`date`,1,7) as month, sum(total_laid_off)  from layoffs_staging2 
where substring(`date`,1,7)  is not null
group by month
 order by 1 asc;
 
 with Rolling_Total as 
 (
 select substring(`date`,1,7) as month, sum(total_laid_off) as r_total  from layoffs_staging2 
where substring(`date`,1,7)  is not null
group by month
 order by 1 asc )
 select `month`, r_total, sum(r_total) over(order by `month`) as rolling_total  from Rolling_Total;
 

WITH Company_Year AS 
(
  SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY company, YEAR(date)
)
, Company_Year_Rank AS (
  SELECT company, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)
SELECT company, years, total_laid_off, ranking
FROM Company_Year_Rank
WHERE ranking <= 3
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;