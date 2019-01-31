# MariaDB - Rotate Encryption Keys

## Summary
The purpose of this project is to provide a method to rotate all encryption keys used by MariaDB's [File Key Management Plugin](https://mariadb.com/kb/en/library/file-key-management-encryption-plugin/) for every encrypted table.  The provided MariaDB SQL script, **_rotateEncKeysSP.sql_** will create a stored procedure named **_rotateEncKeys_** in a database of your choosing.  While this procedure can be added to any database, the user running it needs to have rights to alter every database's encrypted tables.  A temporary table named **_tmpEncKeyLog_** will be created by the stored procedure to allow the logging of the key rotation to a CSV file.  This table will then be dropped upon the procdure's completion.  This method can also be **_automated via Event Scheduler_** to run on a schedule without user interaction.  See the [Automating Stored Procedure](https://github.com/labsrc/MariaDB-Rotate-Encryption-Keys/blob/master/README.md#automating-stored-procedure) section below for more info.

This method has been tested against **_MariaDB 10.3_**, but should work as far back as version **_10.1.4_**.

## Prerequisites
You need to have MariaDB's [Data at Rest Encryption](https://mariadb.com/kb/en/library/data-at-rest-encryption/) already setup using the default encryption plugin, [File Key Management Plugin](https://mariadb.com/kb/en/library/file-key-management-encryption-plugin/).  You also need to have created multiple encryption keys for use with this plugin or the same key will be used over and over.

If you need help with the setup, you can follow this guide on my tech blog, [Labsrc.com - Please Encrypt Your Databases](https://www.labsrc.com/please-encrypt-your-databases-mariadb/).


## Installation
You'll need to **_specify a database_** you would like to add the stored procedure to and then run the SQL script, **_rotateEncKeysSP.sql_**, to create it.  The created stored procedure will run against all databases with encrypted tables regardless of the database it resides in.
#### Install Command
```
mysql -u username -p databasename < rotateEncKeysSP.sql
```

## Running the Stored Procedure
The stored procedure can be called within the MariaDB console by running the following command while using the previously chosen database.
```
use databasename; 
call rotateEncKeys(KeyID,'LogLocation');
```


## Stored Procedure Parameters
#### Parameter 1: Encryption Key ID
   - All tables will rotate to the specified Key ID
   - If specified **_key doesn't exist_**, all tables will **_rollover to Key ID 1_**
   - If **_Key ID 0_** is used, all tables will **_increment_** their current Key ID **_by one_**. If incremented **_Key ID does not exist_**, tables will **_rollover to Key ID 1_**.
#### Parameter 2: Log file directory
   - Log file will be saved as **hostname_encKeyLog_CurrentDate_CurrentTime.csv_**
   - If **_''_** is used, log file will be saved to MariaDB's **_datadir_** __(Default for Ubuntu is__ **_"/var/lib/mysql/")_**
   - Directory must allow write access to the user MariaDB runs as
   - MariaDB will not allow output to "Home Directories" by default


## Example Stored Procedure Usage
#### Example 1 - Incrementing All Encryption Keys
```
call rotateEncKeys(0,'');
```
This command will increment all encryption Key ID's by one and will output the log to your instance's default [datadir](https://mariadb.com/kb/en/library/server-system-variables/#datadir).  The default datadir for Ubuntu is **_"/var/lib/mysql"_**.  If the incremented Key ID doesn't exist, the table will rollover to Key ID 1.

#### Example 2 - Changing All Tables to Encryption Key ID 2 and Specifying Log Location
```
call rotateEncKeys(2,'/tmp');
```
This command will change all encryption keys to Key ID 1 and will output the log to the /tmp directory.


## Automating Stored Procedure
To automate the stored procedure and rotate your encryption keys on a schedule, you'll need to first enable **_Event Scheduler_** in MariaDB.
#### Enable Event Scheduler
Edit your MariaDB config file normally found in **_/etc/mysql/mariadb.cnf_**
```
sudo nano /etc/mysql/mariadb.cnf
```
Add the following under the **_[mysqld]_**
```
[mysqld]
event_scheduler = ON
```
Save the config file, **_Restart MariaDB_** and event scheduler should now be running.

####  Create Scheduled Event
Now create a new event in the **_same database_** you added the **_stored procedure_** to.  Log into the **_MariaDB console_** and run the following code.  You can change the time, start date and frequency to your liking.
```
## Example Scheduled Event

## Must use the same database the "rotateEncKeys" stored procedure was created in
use database;

## Create Schedule Event
CREATE EVENT rotateEncKeysEvent
   ## Following schedule runs once a week on Sunday at 1:00AM
   ON SCHEDULE EVERY 1 WEEK STARTS '2019-01-27 01:00:00'
   ON COMPLETION PRESERVE
   DO 
      call rotateEncKeys(0,'');
```
#### Check Event Status
You can check the status of your event by running the following.
```
SHOW EVENTS\G;
```

## Closing Comments
I created this script in my free time as MariaDB does not currently provide this feature with their encryption plugin.  I may improve or alter this script in the future so check back in when you have time.  If you find any issues or have ways to improve this project in any way, feel free to post.
