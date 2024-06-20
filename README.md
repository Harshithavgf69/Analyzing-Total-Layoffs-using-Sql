The above files are the dataset and the analysis performed on the data set using sql 
Data Preparation:

Create a Staging Table: A copy of the raw data is made to work on, preserving the original dataset.
Data Cleaning:

Remove Duplicates: Duplicate records are identified and removed by adding row numbers and then deleting rows where the row number is greater than 1.
Standardize Data: Entries in the company, industry, and country columns are standardized by trimming whitespace and correcting inconsistencies.
Fix Date Formats: The date column is converted from text format to date format to ensure consistency and accuracy.
Handle Null Values:

Rows with null values in critical columns (total_laid_off and percentage_laid_off) are identified and removed, as they cannot be used in analysis.
Remove Unnecessary Columns:

The row_num column, used for identifying duplicates, is dropped from the table.
Data Analysis:

Aggregate Layoffs: Basic aggregations are performed to understand layoffs by industry, country, and over time.
Monthly and Rolling Totals: Layoff data is aggregated by month, and rolling totals are calculated to observe trends over time.
Yearly Top Companies: The top 3 companies with the most layoffs each year are identified using ranking functions.
Final Verification:

The cleaned and transformed data is verified through various SELECT queries to ensure the cleaning steps were executed correctly and the data is ready for further analysis or reporting.
This process ensures that the dataset is clean, consistent, and ready for detailed analysis to gain insights into layoffs trends and patterns
