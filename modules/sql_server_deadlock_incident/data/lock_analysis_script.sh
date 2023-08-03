

@echo off



set RESOURCE="PLACEHOLDER"

set SERVER=${SERVER_NAME}

set DATABASE="PLACEHOLDER"



REM Check if the resource is being blocked or locked

sqlcmd -S %SERVER% -d %DATABASE% -Q "SELECT resource_type, request_mode, request_status, request_session_id, resource_description FROM sys.dm_tran_locks WHERE resource_associated_entity_id = OBJECT_ID('%RESOURCE%')" -o output.txt -h-1 -s"|" -W



REM Check if there are any deadlocks occurring

sqlcmd -S %SERVER% -d %DATABASE% -Q "SELECT * FROM sys.dm_tran_database_transactions WHERE transaction_state = '2'" -o output.txt -h-1 -s"|" -W



REM Check if there are any long-running transactions

sqlcmd -S %SERVER% -d %DATABASE% -Q "SELECT * FROM sys.dm_exec_requests WHERE status = 'running' AND session_id <> @@SPID" -o output.txt -h-1 -s"|" -W



REM Check if there are any blocked sessions

sqlcmd -S %SERVER% -d %DATABASE% -Q "SELECT blocking_session_id, wait_type, wait_time, last_wait_type, wait_resource FROM sys.dm_os_waiting_tasks WHERE session_id <> @@SPID" -o output.txt -h-1 -s"|" -W



REM Display the output

type output.txt



REM Cleanup the output file

del output.txt