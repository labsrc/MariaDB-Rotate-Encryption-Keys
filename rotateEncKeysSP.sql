DELIMITER //
CREATE PROCEDURE rotateEncKeys (IN encKeyID INT, IN rotateEncLogDir VARCHAR(10000))
BEGIN
DECLARE dbTableName VARCHAR(1000);
DECLARE totalKeys INT DEFAULT 9999;
DECLARE curKey INT;
DECLARE exit_loop BOOLEAN DEFAULT FALSE;
DECLARE encKeyMaxed BOOLEAN DEFAULT FALSE;
DECLARE otherErr BOOLEAN DEFAULT FALSE;
DEClARE curTableKeys CURSOR FOR
    SELECT NAME,CURRENT_KEY_ID FROM information_schema.innodb_tablespaces_encryption WHERE NAME <>'innodb_system';
DECLARE CONTINUE HANDLER FOR NOT FOUND SET exit_loop = TRUE;
DECLARE CONTINUE HANDLER FOR 1005,1478 SET encKeyMaxed = TRUE;
DECLARE CONTINUE HANDLER FOR 1 SELECT 'ERROR 1 (HY000): Can\'t create/write to file (Errcode: 13 "Permission denied")' AS 'Log File Error';
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET otherErr = TRUE;
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
        SET @otherErrMsg = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
    END;
DROP TEMPORARY TABLE IF EXISTS tmpEncKeyLog;
CREATE TEMPORARY TABLE tmpEncKeyLog (TABLE_NAME VARCHAR(50000), NEW_KEY INT, PREV_KEY INT, ERROR VARCHAR(10000));
OPEN curTableKeys;
getTables: LOOP
    FETCH curTableKeys INTO dbTableName, curKey;
    IF exit_loop THEN
        LEAVE getTables;
    END IF;
    SET @newKey = curKey + 1;
    IF encKeyID > 0 THEN
        SET @newKey = encKeyID;
    END IF;
    SET dbTableName = REPLACE(dbTableName, '/', '.');
    SET @dbTableNameFinal = CONCAT('ALTER TABLE ', dbTableName, ' ENCRYPTION_KEY_ID = ', @newKey);
    PREPARE rotateKey FROM @dbTableNameFinal; 
    EXECUTE rotateKey; 
    DEALLOCATE PREPARE rotateKey;
    IF encKeyMaxed THEN
        SET totalKeys = curKey;
        SET @newKey = 1;
        SET @dbTableNameFinal = CONCAT('ALTER TABLE ', dbTableName, ' ENCRYPTION_KEY_ID = ', @newKey);
        PREPARE rotateKey FROM @dbTableNameFinal; 
        EXECUTE rotateKey; 
        DEALLOCATE PREPARE rotateKey;
        IF otherErr THEN 
            SET @newkey = curKey;
            SET @errorOutput = CONCAT('ROTATION FAILED - KEY ID WAS NOT CHANGED\n', @otherErrMsg);
            SET otherErr = FALSE;
            SET encKeyMaxed = FALSE;
        ELSE
            SET @errorOutput = 'HIGHEST KEY ID ALREADY IN USE - ROTATING TO FIRST KEY ID';
            SET encKeyMaxed = FALSE;
        END IF;
    ELSEIF otherErr THEN
        SET @newkey = curKey;
        SET @errorOutput = CONCAT('ROTATION FAILED - KEY ID WAS NOT CHANGED\n', @otherErrMsg);
        SET otherErr = FALSE;
    ELSE
        SET @errorOutput = '';
    END IF;
    INSERT INTO tmpEncKeyLog (TABLE_NAME, NEW_KEY, PREV_KEY, ERROR) VALUES (dbTableName, @newKey, curKey, @errorOutput);
END LOOP getTables;
CLOSE curTableKeys;
IF (rotateEncLogDir IS NULL or rotateEncLogDir = '') THEN
    SET rotateEncLogDir = @@datadir;
ELSEIF (SUBSTRING(rotateEncLogDir, -1) != '/') THEN
    SET rotateEncLogDir = CONCAT(rotateEncLogDir, '/');
END IF;
SET @rotateKeyLogPath = CONCAT(rotateEncLogDir, @@hostname, '_encKeyLog_', CURDATE(), '_', CURTIME() + 0, '.csv');
SET @encKeyOutput = CONCAT('SELECT \'TABLE_NAME\', \'NEW_KEY\', \'PREV_KEY\', \'ERROR\'
    UNION ALL
    SELECT * FROM (SELECT TABLE_NAME, NEW_KEY, PREV_KEY, ERROR
    FROM tmpEncKeyLog ORDER BY TABLE_NAME LIMIT 18446744073709551615)
    a INTO OUTFILE \'', @rotateKeyLogPath,
    '\' FIELDS TERMINATED BY \',\'
    ENCLOSED BY \'"\'
    LINES TERMINATED BY \'\\n\'');
PREPARE rotateKeyLog FROM @encKeyOutput;
EXECUTE rotateKeyLog;
DEALLOCATE PREPARE rotateKeyLog;
DROP TEMPORARY TABLE tmpEncKeyLog;
END;
//
DELIMITER ;
