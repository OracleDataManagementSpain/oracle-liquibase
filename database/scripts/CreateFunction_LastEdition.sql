CREATE OR REPLACE FUNCTION LASTEDITION RETURN DBA_EDITIONS.EDITION_NAME%TYPE AS 
    last_edition DBA_EDITIONS.EDITION_NAME%TYPE := 'ORA$BASE';
    next_edition DBA_EDITIONS.EDITION_NAME%TYPE := 'ORA$BASE';
BEGIN
    WHILE TRUE
    LOOP
        BEGIN
            SELECT EDITION_NAME 
            INTO next_edition 
            FROM DBA_EDITIONS 
            WHERE PARENT_EDITION_NAME=next_edition;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EXIT;
            WHEN OTHERS THEN
                RAISE;
        END;
        last_edition:=next_edition;
    END LOOP;

  RETURN last_edition;
END LASTEDITION;