DECLARE @TargetTable nvarchar(100), @SourceTable nvarchar(100) 

SELECT  'ALTER TABLE '
		+SourceTable
		+' DROP CONSTRAINT  '
		+ConstraintName
		 [DropConstraint]
	, 
		'ALTER TABLE '
		+SourceTable
		+' NOCHECK CONSTRAINT '
		+ConstraintName
		  [NoCheck]
	, 
		'ALTER TABLE '
		+SourceTable
		+' WITH CHECK ADD CONSTRAINT '
		+ConstraintName
		+' FOREIGN KEY ('
		+SourceColumns
		+') REFERENCES '
		+TargetTable
		+' ('
		+TargetColumns
		+')' +  CASE 
		WHEN DeleteAction <> 'NO_ACTION'
			THEN ' ON DELETE ' + REPLACE(DeleteAction, 'SET_NULL', 'SET NULL')
		ELSE ''
		END + CASE 
		WHEN UpdateAction <> 'NO_ACTION'
			THEN ' ON UPDATE ' + REPLACE(UpdateAction, 'SET_NULL', 'SET NULL')
		ELSE ''
		END [CreateConstraint]
	,
		'ALTER TABLE '
		+SourceTable
		+'  CHECK CONSTRAINT '
		+ConstraintName  [ReCheck]
	,ConstraintName
	,SourceTable
	,SourceColumns
	,TargetTable
	,TargetColumns 
FROM (
	SELECT  
			'[' +OBJECT_SCHEMA_NAME(fk.parent_object_id)
			+'].['
			+OBJECT_NAME(fk.parent_object_id)
			+']'
			  [SourceTable]
		, 
			'['
			+OBJECT_SCHEMA_NAME(fk.referenced_object_id)
			+'].['
			+OBJECT_NAME(fk.referenced_object_id)
			+']'
			 [TargetTable]
		,QUOTENAME(fk.name) [ConstraintName]
		, QUOTENAME(sc.name)  [SourceColumns]
		,  QUOTENAME(tc.Name) [TargetColumns]
		,delete_referential_action_desc COLLATE SQL_Latin1_General_CP1_CI_AS [DeleteAction]
		,update_referential_action_desc COLLATE SQL_Latin1_General_CP1_CI_AS [UpdateAction] 
	FROM sys.foreign_keys fk
	INNER JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
	INNER JOIN sys.columns sc ON fkc.parent_column_id = sc.column_id
		AND fkc.parent_object_id = sc.object_id
	INNER JOIN sys.columns tc ON fkc.referenced_column_id = tc.column_id
		AND fkc.referenced_object_id = tc.object_id
		CROSS APPLY (Select OBJECT_SCHEMA_NAME(fk.parent_object_id)
		 +'.'
			+OBJECT_NAME(fk.parent_object_id) 
			 [SourceTable]
		, OBJECT_SCHEMA_NAME(fk.referenced_object_id)
			+'.' 
			+OBJECT_NAME(fk.referenced_object_id)  [TargetTable]) td
			WHERE  (@TargetTable is null or td.TargetTable = @TargetTable) OR (@SourceTable IS NULL OR  td.SourceTable = @SourceTable)
	) fkdtl
ORDER BY DropConstraint

