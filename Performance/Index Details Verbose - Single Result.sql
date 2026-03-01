-- Combined index details and usage statistics with optional table search
DECLARE @TableName NVARCHAR(128) = '%'; -- Set to table name or leave NULL for all tables

SELECT 
    SCHEMA_NAME(o.schema_id) AS [Schema],
    o.name AS [Name],
    i.name AS [IndexName],
    CASE i.type_desc
        WHEN 'CLUSTERED' THEN 1
        WHEN 'NONCLUSTERED' THEN 0
    END AS [CI],
    i.is_primary_key AS [PK],
    i.has_filter AS [F],
    STRING_AGG(
        CASE WHEN ic.is_included_column = 0 
        THEN c.name + IIF(ic.is_descending_key = 1, ' DESC','') --+  IIF(ic.is_descending_key = 1, ' DESC', ' ASC')
        ELSE NULL END, 
        ', '
    ) WITHIN GROUP (ORDER BY ic.key_ordinal) AS [KeyColumns],
    STRING_AGG(
        CASE WHEN ic.is_included_column = 1 
        THEN c.name 
        ELSE NULL END, 
        ', '
    ) AS [IncludeColumns],
    
  --  i.filter_definition AS [Filter],
    ISNULL(ius.user_seeks, 0) AS Seeks,
    ISNULL(ius.user_scans, 0) AS Scans,
    ISNULL(ius.user_lookups, 0) AS Lookups,
    ius.last_user_seek,
    ius.last_user_scan,
    ius.last_user_lookup,
    SUM(p.rows) AS [Rows],
    ISNULL(ius.user_seeks, 0) + ISNULL(ius.user_scans, 0) + ISNULL(ius.user_lookups, 0) AS Reads,
    ISNULL(ius.user_updates, 0) AS Updates,
    ius.last_user_update,
    i.is_unique AS [UQ],
    IIF(o.type_desc = 'USER_TABLE', 'U', 'V') AS ObjectType
FROM 
    sys.indexes i
INNER JOIN 
    sys.objects o ON i.object_id = o.object_id
INNER JOIN 
    sys.index_columns ic ON i.object_id = ic.object_id 
    AND i.index_id = ic.index_id
INNER JOIN 
    sys.columns c ON ic.object_id = c.object_id 
    AND ic.column_id = c.column_id
INNER JOIN
    sys.partitions p ON i.object_id = p.object_id
    AND i.index_id = p.index_id
LEFT JOIN 
    sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id 
    AND i.index_id = ius.index_id
    AND ius.database_id = DB_ID()
WHERE 
    o.is_ms_shipped = 0
    AND o.type IN ('U', 'V') -- U = User table, V = View
    AND i.type_desc IN ('CLUSTERED', 'NONCLUSTERED')
    AND o.name LIKE @TableName
GROUP BY
    o.schema_id,
    o.name,
    o.type_desc,
    i.name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key,
    i.is_disabled,
    i.has_filter,
    i.filter_definition,
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates,
    ius.last_user_seek,
    ius.last_user_scan,
    ius.last_user_lookup,
    ius.last_user_update
ORDER BY 
    [Schema],
    [Name],
    CASE 
        WHEN i.type_desc = 'CLUSTERED' THEN 1
        WHEN i.is_primary_key = 1 THEN 2
        ELSE 3
    END,
    [KeyColumns],
    [IndexName];