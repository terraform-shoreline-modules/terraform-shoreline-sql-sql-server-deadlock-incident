

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