# Rotate Encryption Keys in MariaDB

## Summary
The purpose of this project is to provide you with a method to rotate all encryption keys created by the [File Key Management Plugin](https://mariadb.com/kb/en/library/file-key-management-encryption-plugin/) for every currently encrypted table.  The provided MariaDB SQL script, **_rotateEncKeysSP.sql_** will create a stored procedured named **_rotateEncKeys_** in a database of your choosing.  While it can be added to any database, the user running the procedure needs to have rights to alter every database's encrypted tables.  When the procedure is run, a temporary table named **_tmpEncKeyLog_** will be created to log the output to a CSV file.  This table will then be dropped upon the procdure's completion.  This method can also be **_automated via Event Scheduler_** to run on a schedule without user interaction.


## Prerequisites
You need to have MariaDB's [Data at Rest Encryption](https://mariadb.com/kb/en/library/data-at-rest-encryption/) already setup using the default encryption plugin, [File Key Management Plugin](https://mariadb.com/kb/en/library/file-key-management-encryption-plugin/).  You also need to have created multiple encryption keys for use with this plugin.

If you need help with the setup, you can follow this guide on my tech blog, [Labsrc.com - Please Encrypt Your Databases](https://www.labsrc.com/please-encrypt-your-databases-mariadb/).


## Installation
You'll need to **_specify a database_** you would like to add the stored procedure to and then run the SQL script, **_rotateEncKeysSP.sql_**, to create it.  The stored procedure will run against all databases with encrypted tables regardless of the database it resides in.
#### Install Command
```
mysql -u username -p databasename < rotateEncKeysSP.sql
```

## Running the Stored Procedure
The stored procedure can be called within the MariaDB console by running the following command while using the previously chosen database.
```
use databasename; 
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


## Automating Stored Procedure
To automate the stored procedure and rotate your encryption keys on a schedule, you'll need to first enable **_Event Scheduler_** in MariaDB.
#### Enable Event Scheduler
Edit your MariaDB config file normally found in **_/etc/mysql/mariadb.cnf_**
```
sudo nano /etc/mysql/mariadb.cnf
```
Add the following under the [mysqld] section then save.
```
[mysqld]
event_scheduler = ON
```
**_Restart MariaDB_** and event scheduler should now be running.

You then need to create a new event in the **_same database_** you created the **_stored procedure_** in.  Log into the **_MariaDB_** console and run the following:

#### Create Event Schedule
```
## Use the same database the stored procedure was created in
use database; 
CREATE EVENT rotateEncKeysEvent
   ## Following schedule runs once a week on Sunday at 1:00AM
   ON SCHEDULE EVERY 1 WEEK STARTS '2019-01-27 01:00:00'
   ON COMPLETION PRESERVE
   DO 
      call rotateEncKeys(0,'');
```
