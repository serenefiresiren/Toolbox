DECLARE @ReferencedTable NVARCHAR(100) = ''

SELECT 'ALTER TABLE ' + ParentObject + ' DROP CONSTRAINT ' + fkName [DropConstraint]
	,'ALTER TABLE ' + ParentObject + ' NOCHECK CONSTRAINT ' + fkName [NoCheck]
	,'ALTER TABLE ' + ParentObject + ' WITH CHECK ADD CONSTRAINT ' + fkName + ' FOREIGN KEY (' + ParentObjectCols + ') REFERENCES ' + ReferencedObject + ' (' + ReferencedObjectCols + ')' + IIF(DeleteAction <> 'NO_ACTION', ' ON DELETE ' + REPLACE(DeleteAction, '_', ' '), '') + IIF(UpdateAction <> 'NO_ACTION', ' ON UPDATE ' + REPLACE(UpdateAction, '_', ' '), '') [CreateConstraint]
	,'ALTER TABLE ' + ParentObject + ' CHECK CONSTRAINT ' + fkName [ReCheck]
	,fkName [ConstraintName]
	,ParentObject [ParentTable]
	,ParentObjectCols [ParentColumns]
	,ReferencedObject [ReferencedTable]
	,ReferencedObjectCols [ReferencedColumns]
	,DeleteAction
	,UpdateAction
FROM sys.foreign_keys fk
CROSS APPLY (
	SELECT QUOTENAME(OBJECT_SCHEMA_NAME(fk.parent_object_id)) + '.' + QUOTENAME(OBJECT_NAME(fk.parent_object_id)) [ParentObject]
		,QUOTENAME(OBJECT_SCHEMA_NAME(fk.referenced_object_id)) + '.' + QUOTENAME(OBJECT_NAME(fk.referenced_object_id)) 	[ReferencedObject]
		,QUOTENAME(fk.name) [fkName]
		,(
			SELECT STRING_AGG(QUOTENAME(c.name), ', ') WITHIN
			GROUP (
					ORDER BY fkc.constraint_column_id
					)
			FROM sys.foreign_key_columns fkc
			INNER JOIN sys.columns c ON fkc.parent_object_id = c.object_id
				AND fkc.parent_column_id = c.column_id
			WHERE fkc.constraint_object_id = fk.object_id
			) [ParentObjectCols]
		,(
			SELECT STRING_AGG(QUOTENAME(c.name), ', ') WITHIN
			GROUP (
					ORDER BY fkc.constraint_column_id
					)
			FROM sys.foreign_key_columns fkc
			INNER JOIN sys.columns c ON fkc.referenced_object_id = c.object_id
				AND fkc.referenced_column_id = c.column_id
			WHERE fkc.constraint_object_id = fk.object_id
			) [ReferencedObjectCols]
		,fk.delete_referential_action_desc COLLATE SQL_Latin1_General_CP1_CI_AS [DeleteAction]
		,fk.update_referential_action_desc COLLATE SQL_Latin1_General_CP1_CI_AS [UpdateAction]
	) d 
WHERE @ReferencedTable = ''
	OR OBJECT_NAME(fk.referenced_object_id) = @ReferencedTable
	OR OBJECT_NAME(fk.parent_object_id) = @ReferencedTable
ORDER BY 1

