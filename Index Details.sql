SELECT s.name AS schema_name
	,t.name AS table_name
	,i.name AS index_name
	,i.IS_PRimary_Key [PK]
	,CASE i.Type
		WHEN 1
			THEN 1
		ELSE 0
		END [CI]
	,i.is_unique [UQ]
	,STUFF((
			SELECT ', ' + c.name + ' ' + CASE 
					WHEN ic.is_descending_key = 1
						THEN 'DESC'
					ELSE 'ASC'
					END
			FROM sys.index_columns ic
			INNER JOIN sys.columns c ON ic.object_id = c.object_id
				AND ic.column_id = c.column_id
			WHERE ic.object_id = i.object_id
				AND ic.index_id = i.index_id
				AND ic.is_included_column = 0
			ORDER BY ic.key_ordinal
			FOR XML PATH('')
			), 1, 2, '') AS key_column_list
<<<<<<< HEAD
	,
	-- Included columns without ordering
=======
	, 
>>>>>>> 576c9bc8519e28203cccdaab24afa7c6a0829606
	STUFF((
			SELECT ', ' + c.name
			FROM sys.index_columns ic
			INNER JOIN sys.columns c ON ic.object_id = c.object_id
				AND ic.column_id = c.column_id
			WHERE ic.object_id = i.object_id
				AND ic.index_id = i.index_id
				AND ic.is_included_column = 1
			ORDER BY ic.key_ordinal
			FOR XML PATH('')
			), 1, 2, '') AS include_column_list
	,i.filter_definition
FROM sys.indexes i
INNER JOIN sys.tables t ON t.object_id = i.object_id
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
	AND i.type_desc IN (
		'NONCLUSTERED'
		,'CLUSTERED'
		)
ORDER BY schema_name
	,table_name
	,CASE 
		WHEN i.is_primary_key = 1
			THEN 1
		WHEN i.Type = 1
			THEN 1
		END DESC
	,i.is_primary_key
<<<<<<< HEAD
	,index_name;

=======
	,index_name;
>>>>>>> 576c9bc8519e28203cccdaab24afa7c6a0829606
