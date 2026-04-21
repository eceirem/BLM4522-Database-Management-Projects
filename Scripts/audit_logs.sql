SELECT event_time, action_id, session_server_principal_name, database_name, statement
FROM sys.fn_get_audit_file('C:\Audit_Logs\*', NULL, NULL);