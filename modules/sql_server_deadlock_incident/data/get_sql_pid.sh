cmd

# Get process ID for SQL Server instance

tasklist /fi "imagename eq sqlservr.exe" /fo list | findstr /i "PID"