## Example Scheduled Event

CREATE EVENT rotateEncKeysEvent
    ## Following schedule runs once a week on Sunday at 1:00AM
    ON SCHEDULE EVERY 1 WEEK STARTS '2019-01-27 01:00:00'
    ON COMPLETION PRESERVE
    DO
        ## Change Stored Procedure call to your liking
        call rotateEncKeys(0,'');
