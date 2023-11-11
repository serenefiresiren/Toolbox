DECLARE @SourceDatabase NVARCHAR(255) = 'REPLACEME'
	,@DestDatabase NVARCHAR(255) = 'REPLACEMETOO'

SELECT 'USE '+ QUOTENAME(@DestDatabase)+ '; ' + CASE
		WHEN tcr.IdentityColumn >= 1 THEN	' SET IDENTITY_INSERT ' + tcr.FullTableName + ' ON; ' ELSE	''
	END + ' INSERT INTO ' + QUOTENAME(@DestDatabase) + '.' + tcr.FullTableNAme + ' ( ' + tcr.ReducedColumns
	+ ' ) SELECT ' + Tcr.ReducedColumns + ' FROM ' + QUOTENAME(@SourceDatabase) + '.' + FullTableName
	+	CASE
			WHEN tcr.IdentityColumn >= 1 
				THEN	' SET IDENTITY_INSERT ' + tcr.FullTableName + ' OFF;' 
			ELSE	''
		END
FROM (
	SELECT QUOTENAME(SCHEMA_NAME(t.schema_ID)) + '.' + QUOTENAME(t.name) [FullTableName]
		,(SELECT count(1)
			FROM sys.columns ci
			WHERE ci.is_identity = 1
				AND ci.object_id = t.object_id) [IdentityColumn]
		,STUFF((SELECT ',' + ncc.Name
				FROM sys.Columns ncc
				WHERE ncc.is_computed = 0
					AND ncc.object_id = t.object_id
				ORDER BY ncc.Column_ID
				FOR XML PATH('')), 1, 1, '') [ReducedColumns]
	FROM sys.tables t
	WHERE t.type = 'U'
		AND EXISTS (SELECT 1
					FROM sys.columns cc
					WHERE cc.is_computed = 1
						AND cc.object_id = t.object_id)
	) tcr
ORDER BY tcr.FullTableName
