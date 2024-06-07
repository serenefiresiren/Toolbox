SELECT kcu.TABLE_SCHEMA
	,kcu.TABLE_NAME
	,kcu.COLUMN_NAME
	,c.DATA_TYPE
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
INNER JOIN INFORMATION_SCHEMA.COLUMNS c ON kcu.COLUMN_NAME = c.COLUMN_NAME
	AND c.TABLE_NAME = kcu.TABLE_NAME
WHERE CONSTRAINT_NAME LIKE 'FK%'
	AND c.DATA_TYPE IN ('int', 'smallint', 'bigint')
	AND NOT EXISTS (
		SELECT 1
		FROM sys.index_columns ic
		INNER JOIN sys.columns c ON ic.column_id = c.column_id
			AND ic.object_id = c.object_id
		WHERE OBJECT_NAME(ic.object_id) NOT LIKE 'SYS%'
			AND OBJECT_NAME(ic.object_id) = kcu.TABLE_NAME
			AND SCHEMA_NAME(ic.Object_Id) = kcu.TABLE_SCHEMA
			AND c.name = kcu.COLUMN_NAME
		GROUP BY OBJECT_NAME(ic.object_id)
			,c.name
		)
ORDER BY TABLE_SCHEMA
	,TABLE_NAME

