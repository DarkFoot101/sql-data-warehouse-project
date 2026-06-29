-- ====================================================
-- loading the data into the tables 
-- loading the data from scatch and adding the data from csv fiels to the table in a bulk
-- its called as bulk insert or load data 
-- WARNING - Data loaded will be appended , unless truncated first 
-- ====================================================

-- cust_info
LOAD DATA LOCAL INFILE '/Users/akhi/Desktop/cust_info.csv'
INTO TABLE bronze.crm_cust_info
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM bronze.crm_cust_info;

-- prd_info
LOAD DATA LOCAL INFILE '/Users/akhi/Desktop/prd_info.csv'
INTO TABLE bronze.crm_prd_info
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM bronze.crm_prd_info;

-- sales_details
LOAD DATA LOCAL INFILE '/Users/akhi/Desktop/sales_details.csv'
INTO TABLE bronze.crm_sales_details
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM bronze.crm_sales_details;

-- cust_az12
LOAD DATA LOCAL INFILE '/Users/akhi/Desktop/CUST_AZ12.csv'
INTO TABLE bronze.erp_cust_az12
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM bronze.erp_cust_az12;

-- loc_a101
LOAD DATA LOCAL INFILE '/Users/akhi/Desktop/loc_a101.csv'
INTO TABLE bronze.erp_loc_a101
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM bronze.erp_loc_a101;

-- px_cat_g1v2
LOAD DATA LOCAL INFILE '/Users/akhi/Desktop/px_cat_g1v2.csv'
INTO TABLE bronze.erp_px_cat_g1v2
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM bronze.erp_px_cat_g1v2;
