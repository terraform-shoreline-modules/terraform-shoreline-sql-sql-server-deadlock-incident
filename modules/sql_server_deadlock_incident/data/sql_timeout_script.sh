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