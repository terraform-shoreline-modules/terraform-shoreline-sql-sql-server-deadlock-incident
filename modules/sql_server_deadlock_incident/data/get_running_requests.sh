SELECT 

    r.session_id, 

    r.status, 

    r.blocking_session_id, 

    r.wait_type, 

    r.wait_time, 

    r.last_wait_type, 

    r.cpu_time, 

    r.total_elapsed_time, 

    r.reads, 

    r.writes, 

    r.logical_reads,

    t.text, 

    qp.query_plan 

FROM 

    sys.dm_exec_requests r 

    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t

    CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) qp 

WHERE 

    r.status IN ('running', 'suspended') 

    AND r.session_id != @@SPID;