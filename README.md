# MariaDB Stored Procedure to Rotate Encryption Keys

## Summary:
   Script will create a stored procedured named rotateEncKeys in the currently used DB.  This procedure can be added to any DB as 
   long as the user running it has rights to alter any DB's tables. It's purpose is to rotate encryption keys created by MariaDB's
   "File Key Management Plugin" for all currently encrypted tables.  When the procedure is run, a temporary table named 
   "tmpEncKeyLog" will be created to log output.  This table will be dropped upon completion.

## Example
```
call rotateEncKeys(1,'/tmp/mariadblogs/');
```
This command will rotate all encrypted tables to encryption key id 1 and will output logs to /tmp/mariadblogs/
   
Parameters:
   Param 1: Encryption Key ID
      - All tables will rotate to specified Key ID
      - If specified key doesn't exist, all tables will rollover to Key ID "1"
      - If Key ID "0" is used, all tables will increment their current Key ID by one. If incremented Key ID does not exist, tables will rollover to Key ID "1".
   Param 2: Log file location
      - Log file will be saved as encKeyLog_CurrentDate_CurrentTime.csv
      - If '' is used, log file will be saved to MariaDB's datadir (Default for Ubuntu is "/var/lib/mysql/")
      - Location must have write access to the user MariaDB runs as
      - MariaDB will not allow output to "Home Directories" by default
