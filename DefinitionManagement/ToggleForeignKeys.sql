SELECT CONCAT (
		'ALTER TABLE '
		,SourceTable
		,' DROP CONSTRAINT IF EXISTS '
		,ConstraintName
		) [DropConstraint]
	,CONCAT (
		'ALTER TABLE '
		,SourceTable
		,' NOCHECK CONSTRAINT '
		,ConstraintName
		) [NoCheck]
	,CONCAT (
		'ALTER TABLE '
		,SourceTable
		,' WITH CHECK ADD CONSTRAINT '
		,ConstraintName
		,' FOREIGN KEY ('
		,SourceColumns
		,') REFERENCES '
		,TargetTable
		,' ('
		,TargetColumns
		,')'
		) + CASE 
		WHEN DeleteAction <> 'NO_ACTION'
			THEN ' ON DELETE ' + REPLACE(DeleteAction, 'SET_NULL', 'SET NULL')
		ELSE ''
		END + CASE 
		WHEN UpdateAction <> 'NO_ACTION'
			THEN ' ON UPDATE ' + REPLACE(UpdateAction, 'SET_NULL', 'SET NULL')
		ELSE ''
		END [CreateConstraint]
	,CONCAT (
		'ALTER TABLE '
		,SourceTable
		,'  CHECK CONSTRAINT '
		,ConstraintName
		) [ReCheck]
	,ConstraintName
	,SourceTable
	,SourceColumns
	,TargetTable
	,TargetColumns 
FROM (
	SELECT CONCAT (
			'['
			,OBJECT_SCHEMA_NAME(fk.parent_object_id)
			,'].['
			,OBJECT_NAME(fk.parent_object_id)
			,']'
			) SourceTable
		,CONCAT (
			'['
			,OBJECT_SCHEMA_NAME(fk.referenced_object_id)
			,'].['
			,OBJECT_NAME(fk.referenced_object_id)
			,']'
			) TargetTable
		,QUOTENAME(fk.name) [ConstraintName]
		,STRING_AGG(QUOTENAME(sc.name), ',') WITHIN
	GROUP (
			ORDER BY fkc.Constraint_Column_ID
			) [SourceColumns]
		,STRING_AGG(QUOTENAME(tc.Name), ',') WITHIN
	GROUP (
			ORDER BY fkc.Constraint_Column_ID
			) [TargetColumns]
		,delete_referential_action_desc COLLATE SQL_Latin1_General_CP1_CI_AS [DeleteAction]
		,update_referential_action_desc COLLATE SQL_Latin1_General_CP1_CI_AS [UpdateAction] 
	FROM sys.foreign_keys fk
	INNER JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
	INNER JOIN sys.columns sc ON fkc.parent_column_id = sc.column_id
		AND fkc.parent_object_id = sc.object_id
	INNER JOIN sys.columns tc ON fkc.referenced_column_id = tc.column_id
		AND fkc.referenced_object_id = tc.object_id
	GROUP BY fk.parent_object_id
		,fk.referenced_object_id
		,fk.name
		,delete_referential_action_desc
		,update_referential_action_desc
		,fkc.Constraint_object_ID
		,fk.object_id
	) fkdtl
ORDER BY DropConstraint

