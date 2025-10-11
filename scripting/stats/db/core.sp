#include "callbacks.sp"
#include "migrations.sp"
#include "methods.sp"

public void InitDB() {
    if(!SQL_CheckConfig("stats")) {
		SetFailState("No database entry for 'stats'; no database to connect to.");
	} else if(!ConnectDB()) {
		SetFailState("Failed to connect to database.");
	}
	ApplyMigrations();
}

bool ConnectDB() {
	char error[255];
	g_db = SQL_Connect("stats", true, error, sizeof(error));
	if (g_db == null) {
		LogError("Database error %s", error);
		delete g_db;
		return false;
	} else {
		SQL_LockDatabase(g_db);
		SQL_FastQuery(g_db, "SET NAMES \"UTF8mb4\"");  
		SQL_UnlockDatabase(g_db);
		g_db.SetCharset("utf8mb4");
		PrintToServer("Connected to database stats");
		return true;
	}
}