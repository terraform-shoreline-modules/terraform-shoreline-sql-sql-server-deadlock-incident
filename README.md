
### About Shoreline
The Shoreline platform provides real-time monitoring, alerting, and incident automation for cloud operations. Use Shoreline to detect, debug, and automate repairs across your entire fleet in seconds with just a few lines of code.

Shoreline Agents are efficient and non-intrusive processes running in the background of all your monitored hosts. Agents act as the secure link between Shoreline and your environment's Resources, providing real-time monitoring and metric collection across your fleet. Agents can execute actions on your behalf -- everything from simple Linux commands to full remediation playbooks -- running simultaneously across all the targeted Resources.

Since Agents are distributed throughout your fleet and monitor your Resources in real time, when an issue occurs Shoreline automatically alerts your team before your operators notice something is wrong. Plus, when you're ready for it, Shoreline can automatically resolve these issues using Alarms, Actions, Bots, and other Shoreline tools that you configure. These objects work in tandem to monitor your fleet and dispatch the appropriate response if something goes wrong -- you can even receive notifications via the fully-customizable Slack integration.

Shoreline Notebooks let you convert your static runbooks into interactive, annotated, sharable web-based documents. Through a combination of Markdown-based notes and Shoreline's expressive Op language, you have one-click access to real-time, per-second debug data and powerful, fleetwide repair commands.

### What are Shoreline Op Packs?
Shoreline Op Packs are open-source collections of Terraform configurations and supporting scripts that use the Shoreline Terraform Provider and the Shoreline Platform to create turnkey incident automations for common operational issues. Each Op Pack comes with smart defaults and works out of the box with minimal setup, while also providing you and your team with the flexibility to customize, automate, codify, and commit your own Op Pack configurations.

# SQL Server Deadlock Incident
---

A SQL Server deadlock incident occurs when two or more processes are blocked and waiting on each other to release a resource. This results in a situation where none of the processes can continue executing, causing a system slowdown or complete system failure. The incident requires immediate attention from a software engineer to identify and resolve the issue.

### Parameters
```shell
# Environment Variables

export SERVER_NAME="PLACEHOLDER"

export SESSION_ID="PLACEHOLDER"

export DATABASE_NAME="PLACEHOLDER"

export COLUMN_NAME="PLACEHOLDER"

export TABLE_NAME="PLACEHOLDER"


```

## Debug

### Shell command to retrieve process id for sql server instance.
```shell
cmd

# Get process ID for SQL Server instance

tasklist /fi "imagename eq sqlservr.exe" /fo list | findstr /i "PID"
```

### Get active SQL Server sessions and their status
```shell
sqlcmd -S ${SERVER_NAME} -E -Q "SELECT session_id, status FROM sys.dm_exec_sessions"
```

### Get currently executing SQL statements for a given session ID
```shell
sqlcmd -S ${SERVER_NAME} -E -Q "SELECT t.text FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t WHERE r.session_id = ${SESSION_ID}"
```

### Get information about current locks and blocking chains
```shell
sqlcmd -S ${SERVER_NAME} -E -Q "SELECT blocking_session_id, wait_type, last_wait_type, wait_resource, resource_description FROM sys.dm_exec_requests WHERE blocking_session_id <> 0"
```

### Get information about deadlocks that have occurred
```shell
sqlcmd -S ${SERVER_NAME} -E -Q "SELECT * FROM sys.event_log WHERE event_type = 'deadlock'"
```

### Get current SQL Server performance statistics
```shell
typeperf "\SQLServer:General Statistics\User Connections" "\SQLServer:Locks(_Total)\Number of Deadlocks/sec" "\SQLServer:Transactions(_Total)\Transactions/sec"
```

### Get current SQL Server performance statistics
```shell
typeperf "\SQLServer:General Statistics\User Connections" "\SQLServer:Locks(_Total)\Number of Deadlocks/sec" "\SQLServer:Transactions(_Total)\Transactions/sec"
```

### Multiple transactions trying to access the same resource simultaneously.
```shell


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


```

## Repair

### Sql query to retrieve information about currently running or suspended sessions and associated queries.
```shell
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
```

### Avoid using NOLOCK or READ UNCOMMITTED transaction isolation levels as this can lead to dirty reads and make deadlocks worse.
```shell


# Set variables

$serverName = "${SERVER_NAME}"

$databaseName = "${DATABASE_NAME}"

$tableName = "${TABLE_NAME}"

$columnName = "${COLUMN_NAME}"



# Connect to SQL Server

$sqlConnection = New-Object System.Data.SqlClient.SqlConnection

$sqlConnection.ConnectionString = "Server=$serverName;Database=$databaseName;Integrated Security=True"

$sqlConnection.Open()



# Check if NOLOCK or READ UNCOMMITTED is being used

$sqlCommand = $sqlConnection.CreateCommand()

$sqlCommand.CommandText = "SELECT t.text

                           FROM sys.dm_exec_requests r

                           OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t

                           WHERE t.text LIKE '%NOLOCK%'

                           OR t.text LIKE '%READ UNCOMMITTED%'

                           AND r.session_id > 50;"

$sqlReader = $sqlCommand.ExecuteReader()



# If NOLOCK or READ UNCOMMITTED is being used, modify the query

if ($sqlReader.HasRows) {

    Write-Host "Modifying query to remove NOLOCK or READ UNCOMMITTED..."

    $sqlReader.Close()

    

    $sqlCommand = $sqlConnection.CreateCommand()

    $sqlCommand.CommandText = "ALTER TABLE $tableName SET (LOCK_ESCALATION = TABLE);

                               ALTER INDEX ALL ON $tableName REBUILD WITH (ONLINE = ON);

                               UPDATE STATISTICS $tableName WITH FULLSCAN;

                               ALTER DATABASE $databaseName SET ALLOW_SNAPSHOT_ISOLATION ON;

                               ALTER DATABASE $databaseName SET READ_COMMITTED_SNAPSHOT ON;"

    $sqlCommand.ExecuteNonQuery()

    

    Write-Host "Query modified successfully."

}

else {

    Write-Host "NOLOCK or READ UNCOMMITTED is not being used."

}



# Close SQL connection

$sqlConnection.Close()


```

### Increase the timeout value for transactions to allow more time for resolving deadlocks.
```shell
batch

@echo off


 USERNAME="PLACEHOLDER"

 TIMEOUT_VALUE="PLACEHOLDER"

 PASSWORD="PLACEHOLDER"

:: Define the timeout value in seconds

set timeout=${TIMEOUT_VALUE}



:: Set the timeout value for transactions in SQL Server

sqlcmd -S ${SERVER_NAME} -U ${USERNAME} -P ${PASSWORD} -Q "sp_configure 'show advanced options', 1; RECONFIGURE; sp_configure 'remote query timeout', %timeout%; RECONFIGURE;"

if %errorlevel% neq 0 (

    echo Error: Failed to update the transaction timeout value.

    exit /b 1

)



echo The transaction timeout value has been updated to %timeout% seconds.

exit /b 0


```