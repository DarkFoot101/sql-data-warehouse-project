-- Silver Layer 
-- Data transformation, data cleaning, data validation, understanding tables from bronze layer 
-- data normalization, data enrichment, data analysis,tables without making date model 
-- use the same ddl scrips of bronze layer, but add metadata columns for each table.

-- =====================================================
-- Create Silver Database (if it doesn't exist)
-- =====================================================

CREATE DATABASE IF NOT EXISTS silver;
USE silver;

-- =====================================================
-- CRM Tables
-- =====================================================

DROP TABLE IF EXISTS silver.crm_cust_info;

CREATE TABLE silver.crm_cust_info (
    cst_id INT,
    cst_key VARCHAR(50),
    cst_firstname VARCHAR(50),
    cst_lastname VARCHAR(50),
    cst_material_status VARCHAR(50),
    cst_gndr VARCHAR(50),
    cst_create_date DATE
);

----------------------------------------------------------

DROP TABLE IF EXISTS silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info (
    prd_id INT,
    prd_key VARCHAR(50),
    prd_nm VARCHAR(50),
    prd_cost INT,
    prd_line VARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt DATE
);

----------------------------------------------------------

DROP TABLE IF EXISTS silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details (
    sls_ord_num VARCHAR(50),
    sls_prd_key VARCHAR(50),
    sls_cust_id INT,
    sls_order_dt INT,
    sls_ship_dt INT,
    sls_due_dt INT,
    sls_sales INT,
    sls_quantity INT,
    sls_price INT
);

-- =====================================================
-- ERP Tables
-- =====================================================

DROP TABLE IF EXISTS silver.erp_loc_a101;

CREATE TABLE silver.erp_loc_a101 (
    cid VARCHAR(50),
    cntry VARCHAR(50)
);

----------------------------------------------------------

DROP TABLE IF EXISTS silver.erp_cust_az12;

CREATE TABLE silver.erp_cust_az12 (
    cid VARCHAR(50),
    bdate DATE,
    gen VARCHAR(50)
);

----------------------------------------------------------

DROP TABLE IF EXISTS silver.erp_px_cat_g1v2;

CREATE TABLE silver.erp_px_cat_g1v2 (
    id VARCHAR(50),
    cat VARCHAR(50),
    subcat VARCHAR(50),
    maintenance VARCHAR(50)
);

-- =====================================================
-- Confirmation
-- =====================================================

SELECT 'Silver Layer Created Successfully!' AS Status;

-- ===================================================
-- Data Transformation 
-- ===================================================

select * from bronze.crm_cust_info;
 SELECT @@sql_mode;
 -- now we check the quality issues from the bronze layer first 
-- check the duplicates in primary key 

-- we will make a standard rule for cst_gndr - m for male, f for female only 
-- check for unwanted sspaces, expectation should be no results 
-- pick one value and see where you can do the data cleaning and data transformation
DELETE FROM bronze.crm_cust_info 
WHERE cst_create_date is null;

SET SESSION sql_mode =
REPLACE(REPLACE(@@sql_mode,
'NO_ZERO_DATE',''),
'NO_ZERO_IN_DATE','');

UPDATE bronze.crm_cust_info
SET cst_create_date = NULL
WHERE cst_create_date = '0000-00-00';

-- Restore your SQL mode if needed

insert into silver.crm_cust_info(
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname, 
    cst_material_status,
    cst_gndr,
    cst_create_date
)
with cleaned_bronze as (
    -- Step 1: Clean the data FIRST to get rid of '0000-00-00' completely
    select 
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_material_status,
        cst_gndr,
        cst_create_date
    from bronze.crm_cust_info 
    where cst_id is not null
),
ranked_data as (
    -- Step 2: Apply the window function to the already cleaned data
    select 
        *,
        row_number() over (partition by cst_id order by cst_create_date desc) as flag_last 
    from cleaned_bronze
)
-- Step 3: Run the final mapping and insert
select 
    cst_id,
    cst_key,
    trim(cst_firstname) as cst_firstname,
    trim(cst_lastname) as cst_lastname,
    case 
        when upper(trim(cst_material_status)) = 'S' then 'Single'
        when upper(trim(cst_material_status)) = 'M' then 'Married'
        else 'n/a'
    end as cst_material_status,
    case 
        when upper(trim(cst_gndr)) = 'M' then 'Male'
        when upper(trim(cst_gndr)) = 'F' then 'Female'
        else 'n/a'
    end as cst_gndr,
    cst_create_date
from ranked_data 
where flag_last = 1 and cst_create_date is not null ;

SET SQL_SAFE_UPDATES = 0;

DELETE FROM silver.crm_cust_info
WHERE cst_id = 0;

SET SQL_SAFE_UPDATES = 1;

select * from silver.crm_cust_info;
SET SQL_SAFE_UPDATES = 0;

DELETE FROM silver.crm_cust_info
WHERE cst_create_date = '0000-00-00';

SET SQL_SAFE_UPDATES = 1;

DELETE FROM silver.crm_cust_info
WHERE cst_id = 0;


-- ======================================
-- crm_prd_info
-- =====================================
select * from bronze.crm_prd_info;
-- when we check this table, we find that prd_key, has first 5 chars as the cat_id
-- this matches with the erp table where we need to do joining with that table
-- so we also find its a minus, not _, so we change that one also 

DROP TABLE IF EXISTS silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info (
    prd_id INT,
    prd_key VARCHAR(50),
    cat_id VARCHAR(50),
    prd_nm VARCHAR(50),
    prd_cost INT,
    prd_line VARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt DATE
);

-- we are going to add a cat_id, so we should manipulate and add the data as well whenever required.
INSERT INTO silver.crm_prd_info
(
    prd_id,
    prd_key,
    cat_id,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)

SELECT
    prd_id,
    SUBSTRING(prd_key,7) AS prd_key,
    REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
    prd_nm,
    IFNULL(prd_cost,0) AS prd_cost,
    CASE UPPER(TRIM(prd_line))
        WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,
    prd_start_dt,
    DATE_SUB(
        LEAD(prd_start_dt)
        OVER (
            PARTITION BY prd_key
            ORDER BY prd_start_dt
        ),
        INTERVAL 1 DAY
    ) AS prd_end_dt
FROM bronze.crm_prd_info;

SELECT * FROM silver.crm_prd_info;
-- here we find something important, the dates are messed up
-- we should ensure that the first end date should be smaller than the second start date,
-- we find the first end date smaller than the second start date which shouldn't happen at all
-- or we will use the start date of second date, as the end date of first row, this way it becomes consistant 
-- note this is for each product key adn cat_id, so we will go with the second approach
-- so we will clean that date also , including the switch of start and end date 
-- start date shouldn't be null also, end date can be also null. 


-- ============================
-- crm_sales_details 
-- ============================

-- Check if primary keys are all matching with the other tables 
-- check the table connect drawing for more info 
-- check for invalid dates , make it null 
-- make the dates proper 
select nullif(sls_order_dt,0) sls_order_dt 
from bronze.crm_sales_details
where sls_order_dt <= 0
or length(sls_order_dt) != 8
or sls_order_dt > 20500101
or sls_order_dt < 19000101;

select * from bronze.crm_sales_details 
where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt;

-- does sales quantity or price make sense? 
select 
sls_sales as old_sales,
sls_quantity,
sls_price as old_price,

case when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs(sls_price) then sls_quantity * abs(sls_price)
	else sls_sales
end as sls_sales,

case when sls_price is null or sls_price <= 0 
			then sls_sales / nullif(sls_quantity, 0)
	else sls_price
end as sls_price

from bronze.crm_sales_details 
where sls_sales != sls_quantity * sls_price 
or sls_sales is null or sls_quantity is null or sls_price is null 
or sls_sales < 0 or sls_quantity < 0 or sls_price < 0
order by sls_sales, sls_quantity, sls_price;

-- alter the table of date btw
ALTER TABLE silver.crm_sales_details 
MODIFY COLUMN sls_order_dt DATE,
MODIFY COLUMN sls_ship_dt DATE,
MODIFY COLUMN sls_due_dt DATE;

INSERT INTO silver.crm_sales_details (
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE 
        WHEN sls_order_dt = 0 OR LENGTH(TRIM(sls_order_dt)) != 8 THEN NULL
        ELSE STR_TO_DATE(CAST(sls_order_dt AS CHAR), '%Y%m%d')
    END AS sls_order_dt,
    
    CASE 
        WHEN sls_ship_dt = 0 OR LENGTH(TRIM(sls_ship_dt)) != 8 THEN NULL
        ELSE STR_TO_DATE(CAST(sls_ship_dt AS CHAR), '%Y%m%d')
    END AS sls_ship_dt,
    
    CASE 
        WHEN sls_due_dt = 0 OR LENGTH(TRIM(sls_due_dt)) != 8 THEN NULL
        ELSE STR_TO_DATE(CAST(sls_due_dt AS CHAR), '%Y%m%d')
    END AS sls_due_dt,
    
    CASE 
        WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
            THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    
    sls_quantity,
    
    CASE 
        WHEN sls_price IS NULL OR sls_price <= 0 
            THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price
FROM bronze.crm_sales_details;

-- check the values
SELECT * FROM silver.crm_sales_details;


-- ===============================
-- erp_cust_az12
-- ===============================

-- remove out the future dates at all costs 
INSERT INTO silver.erp_cust_az12 (
	cid,
    bdate,
    gen
)
SELECT
    -- Fix for ID: If you want to strip 'AW' prefixes, change 'NAS%' to 'AW%'
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
        ELSE cid
    END AS cid,
    
    CASE 
        WHEN bdate > NOW() THEN NULL
        ELSE bdate
    END AS bdate,
    
    -- Universal Gender Fix: Checks strings, numbers, and abbreviations
    gen
FROM bronze.erp_cust_az12;

-- there is NAS in the start, which is not required .

-- =====================================
-- erp_loc_a101 
-- =====================================
INSERT INTO silver.erp_loc_a101 (cid, cntry) 
SELECT 
	REPLACE (cid, '-', '') cid,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
    WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
    ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_a101;

-- ===========================
-- erp_px_cat_g1v2
-- ===========================

-- by doing distinct, trim, null or spaces or anytihing
-- if not just go and insert it
INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
SELECT 
id,
cat,
subcat,
maintenance
from bronze.erp_px_cat_g1v2;






















 



