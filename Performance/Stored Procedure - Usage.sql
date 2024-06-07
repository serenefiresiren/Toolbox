 
 IF OBJECT_ID('tempdb..#StoredProcScriptsRaw') IS NOT NULL
 Drop table #StoredProcScriptsRaw

SELECT  DB_NAME(st.dbid) DBName
	,ISNULL(OBJECT_SCHEMA_NAME(st.objectid, st.dbid), '') SchemaName
	,CASE WHEN st.Objectid IS NOT NULL THEN OBJECT_NAME(st.objectid, st.dbid) END [Object]
	,SUBSTRING(st.text, (qs.statement_start_offset / 2) + 1, 
                (CASE qs.statement_end_offset 
                    WHEN -1 THEN DATALENGTH(st.text) 
                    ELSE qs.statement_end_offset 
                END - qs.statement_start_offset) / 2 + 1) AS [ScriptOnly]
	,st.text [Script]
	,qs.statement_end_offset
	,qs.statement_start_offset
	,max(cp.usecounts) execution_count
	,sum(qs.total_worker_time) total_cpu_time
	,sum(qs.total_worker_time) / max(cp.usecounts) avg_cpu_time
	,sum(qs.total_elapsed_time) total_elapsed_time
	,sum(qs.total_elapsed_time) / max(cp.usecounts) avg_elapsed_time
	,sum(qs.total_physical_reads + qs.total_logical_reads + qs.total_logical_writes) total_IO
	,sum(qs.total_physical_reads + qs.total_logical_reads + qs.total_logical_writes) / (max(cp.usecounts)) avg_total_IO
	,CasT(sum(qs.total_physical_reads) AS INT) total_physical_reads
	,CAST(sum(qs.total_physical_reads) / (max(cp.usecounts) * 1.0) AS INT) avg_physical_read
	,sum(qs.total_logical_reads) total_logical_reads
	,CAST(sum(qs.total_logical_reads) / (max(cp.usecounts) * 1.0) AS INT) avg_logical_read
	,sum(qs.total_logical_writes) total_logical_writes
	,CAST(sum(qs.total_logical_writes) / (max(cp.usecounts) * 1.0) AS INT) avg_logical_writes
     ,CAST(query_plan AS nvarchar(max)) as plan_xml 
	 ,query_plan
 INTO #StoredProcScriptsRaw
FROM sys.dm_exec_query_stats qs
LEFT OUTER JOIN sys.dm_exec_cached_plans cp ON qs.plan_handle = cp.plan_handle
CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) st 
CROSS APPLY sys.dm_exec_text_query_plan
    (qs.plan_handle, qs.statement_start_offset, qs.statement_end_offset) 
    as textplan
 WHERE st.dbid = DB_ID()
GROUP BY DB_NAME(st.dbid)
	,OBJECT_SCHEMA_NAME(st.objectid, st.dbid)
	,COALESCE(OBJECT_NAME(st.objectid, st.dbid), TEXT)
	,statement_end_offset
	,statement_start_offset
	,st.text
	,CASE WHEN st.Objectid IS NOT NULL THEN OBJECT_NAME(st.objectid, st.dbid) END
	,query_plan


SELECT   r.DBName, r.SchemaName, r.Object , count(r.RawScript) [Executions]
	,r.RawScript
	,MAX(r.plan_xml) [ExamplePlanXML]
	,MAX(r.script) [ExampleScript]
	,AVG(r.avg_cpu_time) [avg_cpu_time]
	,AVG(r.avg_elapsed_time) [avg_elapsed_time]
	,AVG(r.avg_total_IO) [avg_total_IO]
	,AVG(r.avg_physical_read) [avg_physical_read]
	,AVG(r.avg_logical_read) [avg_logical_read]
	,AVG(r.avg_logical_writes) [avg_logical_writes]
	,GetDate() [CollectionTime] 
FROM (
	SELECT sp.DBName
		,sp.SchemaName
		,sp.Object
		,sp.ScriptOnly [RawScript]
		,sp.Script
		,sp.avg_cpu_time
		,sp.avg_elapsed_time
		,avg_total_IO
		,sp.avg_physical_read
		,sp.avg_logical_read
		,sp.avg_logical_writes 
		,sp.plan_xml
	FROM #StoredProcScriptsRaw sp 
	--WHERE ScriptOnly NOT LIKE '%change_tracking%'
	) r
GROUP BY r.DBName,RawScript , r.SchemaName, r.Object
having count(1) > 1
