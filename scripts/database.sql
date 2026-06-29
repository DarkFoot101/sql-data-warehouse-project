/* CREATING THE DATABASE AND SCHEMAS 

We are creating the datawarehouse and schemas that is of gold, silver and bronze as per the architecutre is being made
Ensure to install mysql and ensure that data is not deleted and ensure to execute the tasks 
*/

use sys;

create database datawarehouse;
use datawarehouse;

create schema bronze;
create schema silver;
create schema gold;

