DECLARE @ObjectName NVARCHAR(255) = 'MyTable'

SELECT cvalue.DBName
	,cvalue.ObjectName
	,SUBSTRING(cvalue.TEXT, cvalue.statement_start_offset, cvalue.statement_end_offset) AS sql_text
	,cvalue.query_plan
	,pc.compiled.value('@Column', 'nvarchar(128)') AS Parameterlist
	,pc.compiled.value('@ParameterCompiledValue', 'nvarchar(128)') AS [compiled Value]
FROM (
	SELECT OBJECT_NAME(est.objectid) ObjectName
		,DB_NAME(est.dbid) DBName
		,eqs.plan_handle
		,eqs.query_hash
		,est.TEXT
		,eqp.query_plan
		,eqs.statement_start_offset / 2 + 1 AS statement_start_offset
		,(
			CASE 
				WHEN eqs.statement_end_offset = - 1
					THEN LEN(CONVERT(NVARCHAR(MAX), est.TEXT)) * 2
				ELSE eqs.statement_end_offset
				END - eqs.statement_start_offset
			) / 2 AS statement_end_offset
		,TRY_CONVERT(XML, SUBSTRING(etqp.query_plan, CHARINDEX('<ParameterList>', etqp.query_plan), CHARINDEX('</ParameterList>', etqp.query_plan) + LEN('</ParameterList>') - CHARINDEX('<ParameterList>', etqp.query_plan))) AS Parameters
	FROM sys.dm_exec_query_stats eqs
	CROSS APPLY sys.dm_exec_sql_text(eqs.sql_handle) est
	CROSS APPLY sys.dm_exec_text_query_plan(eqs.plan_handle, eqs.statement_start_offset, eqs.statement_end_offset) etqp
	CROSS APPLY sys.dm_exec_query_plan(eqs.plan_handle) eqp
	WHERE est.ENCRYPTED <> 1
	) cvalue
OUTER APPLY cvalue.parameters.nodes('//ParameterList/ColumnReference') AS pc(compiled)
WHERE cvalue.ObjectName = @ObjectName
GO



