#include "methods.sp"
#include "callbacks.sp"
#include "migrations.sp"

#define DB_CONFIG_NAME "stats"

public void InitDB() {
    if(!SQL_CheckConfig(DB_CONFIG_NAME)) {
		SetFailState("No database config entry for '%s'; no database to connect to.", DB_CONFIG_NAME);
	} else if(!ConnectDB()) {
		SetFailState("Failed to connect to database for %s", DB_CONFIG_NAME);
	}
	ApplyMigrations();
}

bool ConnectDB() {
	char error[255];
	g_db = SQL_Connect(DB_CONFIG_NAME, true, error, sizeof(error));
	if (g_db == null) {
		LogError("Database error for %s: %s", DB_CONFIG_NAME, error);
		delete g_db;
		return false;
	} else {
		SQL_LockDatabase(g_db);
		SQL_FastQuery(g_db, "SET NAMES \"UTF8mb4\"");  
		SQL_UnlockDatabase(g_db);
		g_db.SetCharset("utf8mb4");
		PrintToServer("[Stats] Connected to database %s", DB_CONFIG_NAME);
		return true;
	}
}