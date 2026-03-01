-- Combined index details and usage statistics with optional table search
DECLARE @TableName NVARCHAR(128) = '%';-- Set to table name or leave NULL for all tables
 
SELECT SCHEMA_NAME(o.schema_id) AS [Schema]
	,o.name AS [Name]
	,i.name AS [IndexName]
	,CASE i.type_desc
		WHEN 'Clustered'
			THEN 1
		WHEN 'NonClustered'
			THEN 0
		END [CI]
	,i.has_filter [F]
	,ius.user_seeks AS Seeks
	,ius.user_scans AS Scans
	,ius.user_lookups AS Lookups
	,ius.last_user_seek
	,ius.last_user_scan
	,ius.last_user_lookup
	,SUM(p.rows) AS row_count
	,ius.user_seeks + ius.user_scans + ius.user_lookups AS Reads
	,ius.user_updates AS Updates
	,ius.last_user_update
	,IIF(o.type_desc = 'USER_TABLE', 'U', 'V') AS ObjectType
FROM sys.dm_db_index_usage_stats ius
INNER JOIN sys.indexes i ON ius.object_id = i.object_id
	AND ius.index_id = i.index_id
INNER JOIN sys.objects o ON ius.object_id = o.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id
	AND i.index_id = p.index_id
WHERE ius.database_id = DB_ID()
	AND o.is_ms_shipped = 0
	AND o.type IN (
		'U'
		,'V'
		) -- U = User table, V = View
	AND i.type_desc IN (
		'CLUSTERED'
		,'NONCLUSTERED'
		)
	AND o.name LIKE @TableName
GROUP BY o.schema_id
	,o.name
	,o.type_desc
	,i.name
	,i.type_desc
	,i.is_unique
	,i.is_primary_key
	,i.is_disabled
	,i.has_filter
	,i.filter_definition
	,ius.user_seeks
	,ius.user_scans
	,ius.user_lookups
	,ius.user_updates
	,ius.last_user_seek
	,ius.last_user_scan
	,ius.last_user_lookup
	,ius.last_user_update
ORDER BY [Schema]
	,[Name]
	,CASE WHEN i.type_desc = 'CLUSTERED'
			THEN 1

		WHEN i.is_primary_key =0
		
			THEN 2
		ELSE 3
		END
	,IndexName;

SELECT SCHEMA_NAME(o.schema_id) AS [Schema]
	,o.name AS [Name]
	,i.name AS [IndexName]
	,CASE i.type_desc
		WHEN 'Clustered'
			THEN 1
		WHEN 'NonClustered'
			THEN 0
		END [CI]
	,i.is_unique [UQ]
	,i.is_primary_key [PK] 
	,i.filter_definition [Filter]
	,STRING_AGG(CASE 
			WHEN ic.is_included_column = 0
				THEN c.name + ' ' + IIF(ic.is_descending_key = 1, 'DESC', 'ASC')
			ELSE NULL
			END, ', ') WITHIN
GROUP (
		ORDER BY ic.key_ordinal
		) AS [KeyColumns]
	,STRING_AGG(CASE 
			WHEN ic.is_included_column = 1
				THEN c.name
			ELSE NULL
			END, ', ') AS [IncludeColumns]
FROM sys.indexes i
INNER JOIN sys.objects o ON i.object_id = o.object_id
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id
	AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id
	AND ic.column_id = c.column_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id
	AND i.index_id = p.index_id
WHERE o.is_ms_shipped = 0
	AND o.type IN (
		'U'
		,'V'
		) -- U = User table, V = View
	AND i.type_desc IN (
		'CLUSTERED'
		,'NONCLUSTERED'
		)
	AND o.name LIKE @TableName
GROUP BY o.schema_id
	,o.name
	,o.type_desc
	,i.name
	,i.type_desc
	,i.is_unique
	,i.is_primary_key
	,i.is_disabled
	,i.has_filter
	,i.filter_definition
ORDER BY [Schema]
	,[Name]
	,CASE WHEN i.type_desc = 'CLUSTERED'
			THEN 1

		WHEN i.is_primary_key = 0
		
			THEN 2
		ELSE 3
		END
		,[KeyColumns]
	,IndexName;

