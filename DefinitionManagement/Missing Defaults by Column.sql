SELECT TABLE_SCHEMA
	,TABLE_NAME
	,COLUMN_NAME
	,DATA_TYPE
	,'ALTER TABLE ' + Table_Schema + '.' + Table_NAme + ' ADD CONSTRAINT [DF_' + Table_Name + '_ROWID] DEFAULT (newid())    for [ROWID]' [NewDefault] 
FROM information_Schema.COLUMNS c
WHERE column_name = 'ROWID'
	AND NOT EXISTS (
		--Select 1 from sys.key_constraints pk where pk.type = 'PK' AND OBJECT_NAME(parent_object_id) = c.TABLE_NAME AND  SCHEMA_NAME(Schema_ID) =  TABLE_SCHEMA)
		SELECT 1
		FROM sys.default_constraints d
		WHERE OBJECT_NAME(parent_object_id) = c.TABLE_NAME
			AND SCHEMA_NAME(Schema_ID) = TABLE_SCHEMA
			AND d.parent_column_id = c.ORDINAL_POSITION
		)

