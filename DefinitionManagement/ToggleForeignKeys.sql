DECLARE @FilterTable nvarchar(255) = '[schema].[table]'

SELECT CONCAT ('ALTER TABLE ', SourceTable, ' DROP CONSTRAINT ', ConstraintName) [DropConstraint]
	, CONCAT ('ALTER TABLE ', SourceTable, ' NOCHECK CONSTRAINT ', ConstraintName) [NoCheck]
	, CONCAT ('ALTER TABLE ', SourceTable, ' WITH CHECK ADD CONSTRAINT ', ConstraintName, ' FOREIGN KEY (', SourceColumn, ' REFERENCES ', TargetTable, ' (', TargetColumn, ')') 
		+ CASE 
			WHEN DeleteAction <> 'NO_ACTION'
				THEN ' ON DELETE ' + DeleteAction
			ELSE ''
			END + CASE 
			WHEN UpdateAction <> 'NO_ACTION'
				THEN ' ON UPDATE ' + UpdateAction
			ELSE ''
			END [CreateConstraint]
	, CONCAT ('ALTER TABLE ', SourceTable, '  CHECK CONSTRAINT ', ConstraintName) [ReCheck]
	, ConstraintName
	, SourceTable
	, SourceColumn
	, TargetTable
	, TargetColumn
FROM (
	SELECT CONCAT ('[', OBJECT_SCHEMA_NAME(f.parent_object_id), '].[', OBJECT_NAME(f.parent_object_id), ']') SourceTable
			, CONCAT ('[', OBJECT_SCHEMA_NAME(f.referenced_object_id), '].[', OBJECT_NAME(f.referenced_object_id), ']') TargetTable
			, QUOTENAME(f.name) [ConstraintName]
			, QUOTENAME(pc.name) [SourceColumn]
			, QUOTENAME(rc.Name) [TargetColumn] 
			, delete_referential_action_desc COLLATE SQL_Latin1_General_CP1_CI_AS [DeleteAction]
			, update_referential_action_desc COLLATE SQL_Latin1_General_CP1_CI_AS [UpdateAction]
	FROM sys.foreign_keys f
	INNER JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = f.object_id
	INNER JOIN sys.columns pc ON fkc.parent_column_id = pc.column_id
		AND fkc.parent_object_id = pc.object_id
	INNER JOIN sys.columns rc ON fkc.referenced_column_id = rc.column_id
		AND fkc.referenced_object_id = rc.object_id
	) fd
WHERE @FilterTable IS NULL OR SourceTable = @FilterTable OR TargetTable = @FilterTable
 