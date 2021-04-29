-- CreateFunction_ProductCount.sql
CREATE OR REPLACE FUNCTION getProductCount RETURN NUMBER AS
	l_count NUMBER;
BEGIN
	SELECT COUNT(*) 
	INTO l_count
	FROM Product;

	RETURN l_count;
END;
/
