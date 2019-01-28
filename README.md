# Rotate Encryption Keys in MariaDB via Stored Procedure

## Summary
This MariaDB SQL script will create a stored procedured named **_rotateEncKeys_** in the specified DB.  This procedure can be added to any database, however, the user running the procedure needs to have rights to alter every DB's encrypted tables.  The purpose of this procedure is to rotate all encryption keys created by the [File Key Management Plugin](https://mariadb.com/kb/en/library/file-key-management-encryption-plugin/) for every currently encrypted table.  When the procedure is run, a temporary table named **_tmpEncKeyLog_** will be created for logging purposes.  This table will be dropped upon the procdure's completion.


## Prerequisites
You need to have MariaDB's [Data at Rest Encryption](https://mariadb.com/kb/en/library/data-at-rest-encryption/) already setup using the default encryption plugin, [File Key Management Plugin](https://mariadb.com/kb/en/library/file-key-management-encryption-plugin/).  You also need to have created multiple encryption keys for use with this plugin.

If you need help with the setup, you can follow the guide I wrote on my tech blog site, [Labsrc.com - Please Encrypt Your Databases](https://www.labsrc.com/please-encrypt-your-databases-mariadb/).


## Installation
You will need to **_specify a database_** you would like to add the stored procedure to and then run the SQL script, **_rotateEncKeysSP.sql_**, to create it.  The stored procedure will run against all encrypted databases regardless of the database it resides in.
#### Install Command
```
mysql -u username -p databasename < rotateEncKeysSP.sql
```

## Running the Stored Procedure
The stored procedure can be called by running the following command while using the database it was stored in.
```
call rotateEncKeys(KeyID,LogLocation);
```


## Stored Procedure Parameters
#### Parameter 1: Encryption Key ID
   - All tables will rotate to specified Key ID
   - If specified key doesn't exist, all tables will rollover to Key ID "1"
   - If Key ID "0" is used, all tables will increment their current Key ID by one. If incremented Key ID does not exist, tables will rollover to Key ID "1".
#### Parameter 2: Log file location
   - Log file will be saved as encKeyLog_CurrentDate_CurrentTime.csv
   - If '' is used, log file will be saved to MariaDB's datadir **_(Default for Ubuntu is "/var/lib/mysql/")_**
   - Location must have write access to the user MariaDB runs as
   - MariaDB will not allow output to "Home Directories" by default


## Stored Procedure Example Usage
#### Example 1 - Incrementing All Encryption Keys
```
call rotateEncKeys(0,'');
```
This command will increment all encryption Key ID's by one and will output the log to your instance's default [datadir](https://mariadb.com/kb/en/library/server-system-variables/#datadir).  The default datadir for Ubuntu is **_"/var/lib/mysql"_**.  If the incremented Key ID doesn't exist, the table will rollover to Key ID 1.

#### Example 2 - Changing All Tables to Encryption Key ID 2 and Specifying Log Location
```
call rotateEncKeys(2,'/tmp/');
```
This command will change all encryption keys to Key ID 1 and will output the log to the /tmp/ directory.
