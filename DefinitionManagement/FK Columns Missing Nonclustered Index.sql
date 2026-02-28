SELECT SCHEMA_NAME(t.schema_id) [TableSchema]
	,t.name [TableName]
	,c.name [ColumnName]
	,ty.name [DataType]
	,fk.name [ForeignKeyName]
	,IIF(fk.delete_referential_action <> 0, 1, 0) [ActionOnDelete]
	,IIF(fk.update_referential_action <> 0, 1, 0) [ActionOnUpdate]
	,p.rows [TableRowCount]
	,sp.has_filter [StatsIsFiltered]
	,sp.rows [StatsRowCount]
	,sp.rows_sampled [StatsRowsSampled]
	,sp.modification_counter [StatsModificationCount]
	,sp.last_updated [StatsLastUpdated]
	,CONCAT (
		'CREATE NONCLUSTERED INDEX [IX_'
		,REPLACE(t.name, ' ', '')
		,'_'
		,REPLACE(c.name, ' ', '')
		,'] ON '
		,QUOTENAME(SCHEMA_NAME(t.schema_id))
		,'.'
		,QUOTENAME(t.name)
		,' ('
		,QUOTENAME(c.name)
		,')'
		--		,'WITH (ONLINE = ON);'
		) [CreateIndexStatement]
FROM sys.foreign_key_columns fkc
INNER JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
INNER JOIN sys.tables t ON fkc.parent_object_id = t.object_id
INNER JOIN sys.columns c ON fkc.parent_object_id = c.object_id
	AND fkc.parent_column_id = c.column_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id
	AND p.index_id IN (0, 1) -- Heap or clustered index
OUTER APPLY (
	SELECT TOP 1 s.has_filter
		,sp1.rows
		,sp1.rows_sampled
		,sp1.modification_counter
		,sp1.last_updated
	FROM sys.stats s
	INNER JOIN sys.stats_columns sc ON s.object_id = sc.object_id
		AND s.stats_id = sc.stats_id
	CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) sp1
	WHERE s.object_id = t.object_id
		AND sc.column_id = c.column_id
		AND sc.stats_column_id = 1 -- Leading column of the stat
	ORDER BY sp1.last_updated DESC
) sp
WHERE NOT EXISTS (
		SELECT 1
		FROM sys.index_columns ic
		INNER JOIN sys.indexes i ON ic.object_id = i.object_id
			AND ic.index_id = i.index_id
		WHERE ic.object_id = t.object_id
			AND ic.column_id = c.column_id
			AND ic.key_ordinal = 1
			AND i.type IN (1, 2) -- Clustered or nonclustered
		)
	AND c.name NOT LIKE '%userId%'
GROUP BY SCHEMA_NAME(t.schema_id)
	,t.name
	,c.name
	,ty.name
	,fk.name
	,fk.delete_referential_action
	,fk.update_referential_action
	,p.rows
	,sp.has_filter
	,sp.rows
	,sp.rows_sampled
	,sp.modification_counter
	,sp.last_updated
ORDER BY
	-- FKs with cascade/set null/set default actions first: these scan the child table on parent modification
	IIF(fk.delete_referential_action <> 0 OR fk.update_referential_action <> 0, 0, 1)
	-- Larger tables benefit more from index seeks vs scans
	-- Numeric types before string types (narrower keys = more efficient indexes)
	,CASE
		WHEN ty.name IN ('tinyint', 'smallint', 'int', 'bigint') THEN 0
		WHEN ty.name IN ('uniqueidentifier') THEN 1
		WHEN ty.name IN ('char', 'varchar', 'nchar', 'nvarchar') THEN 2
		ELSE 3
	END
	,p.rows DESC
	,SCHEMA_NAME(t.schema_id)
	,c.name;
