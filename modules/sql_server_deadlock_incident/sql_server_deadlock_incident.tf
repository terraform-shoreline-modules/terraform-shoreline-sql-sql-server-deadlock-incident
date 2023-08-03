resource "shoreline_notebook" "sql_server_deadlock_incident" {
  name       = "sql_server_deadlock_incident"
  data       = file("${path.module}/data/sql_server_deadlock_incident.json")
  depends_on = [shoreline_action.invoke_get_sql_pid,shoreline_action.invoke_lock_analysis_script,shoreline_action.invoke_get_running_requests,shoreline_action.invoke_check_locks,shoreline_action.invoke_sql_timeout_script]
}

resource "shoreline_file" "get_sql_pid" {
  name             = "get_sql_pid"
  input_file       = "${path.module}/data/get_sql_pid.sh"
  md5              = filemd5("${path.module}/data/get_sql_pid.sh")
  description      = "Shell command to retrieve process id for sql server instance."
  destination_path = "/agent/scripts/get_sql_pid.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "lock_analysis_script" {
  name             = "lock_analysis_script"
  input_file       = "${path.module}/data/lock_analysis_script.sh"
  md5              = filemd5("${path.module}/data/lock_analysis_script.sh")
  description      = "Multiple transactions trying to access the same resource simultaneously."
  destination_path = "/agent/scripts/lock_analysis_script.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "get_running_requests" {
  name             = "get_running_requests"
  input_file       = "${path.module}/data/get_running_requests.sh"
  md5              = filemd5("${path.module}/data/get_running_requests.sh")
  description      = "Sql query to retrieve information about currently running or suspended sessions and associated queries."
  destination_path = "/agent/scripts/get_running_requests.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "check_locks" {
  name             = "check_locks"
  input_file       = "${path.module}/data/check_locks.sh"
  md5              = filemd5("${path.module}/data/check_locks.sh")
  description      = "Avoid using NOLOCK or READ UNCOMMITTED transaction isolation levels as this can lead to dirty reads and make deadlocks worse."
  destination_path = "/agent/scripts/check_locks.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "sql_timeout_script" {
  name             = "sql_timeout_script"
  input_file       = "${path.module}/data/sql_timeout_script.sh"
  md5              = filemd5("${path.module}/data/sql_timeout_script.sh")
  description      = "Increase the timeout value for transactions to allow more time for resolving deadlocks."
  destination_path = "/agent/scripts/sql_timeout_script.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_action" "invoke_get_sql_pid" {
  name        = "invoke_get_sql_pid"
  description = "Shell command to retrieve process id for sql server instance."
  command     = "`chmod +x /agent/scripts/get_sql_pid.sh && /agent/scripts/get_sql_pid.sh`"
  params      = []
  file_deps   = ["get_sql_pid"]
  enabled     = true
  depends_on  = [shoreline_file.get_sql_pid]
}

resource "shoreline_action" "invoke_lock_analysis_script" {
  name        = "invoke_lock_analysis_script"
  description = "Multiple transactions trying to access the same resource simultaneously."
  command     = "`chmod +x /agent/scripts/lock_analysis_script.sh && /agent/scripts/lock_analysis_script.sh`"
  params      = ["SERVER_NAME"]
  file_deps   = ["lock_analysis_script"]
  enabled     = true
  depends_on  = [shoreline_file.lock_analysis_script]
}

resource "shoreline_action" "invoke_get_running_requests" {
  name        = "invoke_get_running_requests"
  description = "Sql query to retrieve information about currently running or suspended sessions and associated queries."
  command     = "`chmod +x /agent/scripts/get_running_requests.sh && /agent/scripts/get_running_requests.sh`"
  params      = []
  file_deps   = ["get_running_requests"]
  enabled     = true
  depends_on  = [shoreline_file.get_running_requests]
}

resource "shoreline_action" "invoke_check_locks" {
  name        = "invoke_check_locks"
  description = "Avoid using NOLOCK or READ UNCOMMITTED transaction isolation levels as this can lead to dirty reads and make deadlocks worse."
  command     = "`chmod +x /agent/scripts/check_locks.sh && /agent/scripts/check_locks.sh`"
  params      = ["DATABASE_NAME","TABLE_NAME","COLUMN_NAME","SERVER_NAME"]
  file_deps   = ["check_locks"]
  enabled     = true
  depends_on  = [shoreline_file.check_locks]
}

resource "shoreline_action" "invoke_sql_timeout_script" {
  name        = "invoke_sql_timeout_script"
  description = "Increase the timeout value for transactions to allow more time for resolving deadlocks."
  command     = "`chmod +x /agent/scripts/sql_timeout_script.sh && /agent/scripts/sql_timeout_script.sh`"
  params      = ["SERVER_NAME"]
  file_deps   = ["sql_timeout_script"]
  enabled     = true
  depends_on  = [shoreline_file.sql_timeout_script]
}

