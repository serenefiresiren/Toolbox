SELECT	Schema_NAME(t.schema_id) [Schema], t.name AS 'Table Name'
	,i.name AS 'Index Name'
	,ius.user_updates AS 'Inserts/Updates/Deletes'
	,ius.user_seeks + ius.user_scans + ius.user_lookups AS 'Total Accesses'
	,ius.user_seeks AS 'Seeks'
	,ius.user_scans AS 'Scans'
	,ius.user_lookups AS 'Lookups'
	,ius.last_user_seek AS 'Last Seek'
	,ius.last_user_scan AS 'Last Scan'
	,ius.last_user_lookup AS 'Last Lookup'
	,p.rows AS 'Row Count' 
FROM sys.dm_db_index_usage_stats ius
JOIN sys.databases d
	ON ius.database_id = d.database_id
	AND d.name = DB_NAME()
JOIN sys.tables t	
	ON ius.object_id = t.object_id
	AND t.type = 'U'
JOIN sys.indexes i	
	ON ius.object_id = i.object_id
	AND ius.index_id = i.index_id
JOIN sys.partitions p	
	ON i.object_id = p.object_id
	AND i.index_id = p.index_id
JOIN sys.allocation_units au	
	ON p.partition_id = au.container_id
--where t.name = ''
ORDER BY 
	t.name
	,i.name