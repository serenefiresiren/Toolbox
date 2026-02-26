DECLARE @OldConstraint NVARCHAR(500)
	,@NewConstraint NVARCHAR(max)

DECLARE RenameFK CURSOR
FOR
SELECT '"' + [ObjectSchema] + '"."' + ConstraintName + '"' [OldConstraint]
	,'FK_' + fkdtl.ParentTable + '_' + fkdtl.ParentColumns + '_' + fkdtl.ReferencedTable + '_' + fkdtl.ReferencedColumns [NewfKName]
FROM (
	SELECT OBJECT_SCHEMA_NAME(fk.parent_object_id) [ObjectSchema]
		,OBJECT_NAME(fk.parent_object_id) [ParentTable]
		,OBJECT_NAME(fk.referenced_object_id) [ReferencedTable]
		,fk.name [ConstraintName]
		,(
			SELECT STRING_AGG(sc.name, '_') within
			GROUP (
					ORDER BY fkc.constraint_column_id
					)
			FROM sys.foreign_key_columns fkc
			INNER JOIN sys.columns sc ON fkc.parent_column_id = sc.column_id
				AND fkc.parent_object_id = sc.object_id
			WHERE fkc.constraint_object_id = fk.object_id
			) [ParentColumns]
		,(
			SELECT STRING_AGG(tc.name, '_') within
			GROUP (
					ORDER BY fkc.constraint_column_id
					)
			FROM sys.foreign_key_columns fkc
			INNER JOIN sys.columns tc ON fkc.referenced_column_id = tc.column_id
				AND fkc.referenced_object_id = tc.object_id
			WHERE fkc.constraint_object_id = fk.object_id
			) [ReferencedColumns]
	FROM sys.foreign_keys fk
	WHERE fk.name LIKE 'FK_/_%' ESCAPE '/'
	) fkdtl

OPEN RenameFK

FETCH
FROM RenameFK
INTO @OldConstraint
	,@NewConstraint

WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT 'Rename ' + @OldConstraint + ' to ' + @NewConstraint

	EXEC sp_Rename @OldConstraint
		,@NewConstraint
		,'Object';

	FETCH
	FROM RenameFK
	INTO @OldConstraint
		,@NewConstraint
END

CLOSE RenameFK

DEALLOCATE RenameFK

