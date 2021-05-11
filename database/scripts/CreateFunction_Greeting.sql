-- CreateFunction_Greeting.sql
CREATE OR REPLACE FUNCTION Greeting RETURN VARCHAR2 AS
BEGIN
	RETURN 'Hello, world from a new version v7';
END;
/
