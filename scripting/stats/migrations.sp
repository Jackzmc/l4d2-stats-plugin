#define NUM_MIGRATIONS 1


char MIGRATIONS[NUM_MIGRATIONS][1];

/**
 * Attempts to apply migrations from the last applied migration. 
 * Will cause plugin to fail on any migration failure
 */
public void ApplyMigrations() {
    GetLastAppliedMigration();
    // TODO: apply each migration if it hasn't already applied
}

// Fetch the last migration ID 
void GetLastAppliedMigration() {
    g_db.Query(DBCB_OnLastMigration, "SELECT MAX(id) id FROM stats_migrations LIMIT 1");
}

void DBCB_OnLastMigration(Handle db, DBResultSet results, const char[] error, int data) {
	if(db == null || results == null) {
		SetFailState("GetLastAppliedMigration failed: %s", error);
        return;
	}
    results.FetchRow();

    int id = -1;
    if(!results.IsFieldNull(0)) {
        id = results.FetchInt(0);
    }
    _ApplyMigrations(id);
}

// Apply all migrations at once in a transaction
void _ApplyMigrations(int lastId) {
    Transaction tx = new Transaction();
    for(int i = lastId + 1; i < NUM_MIGRATIONS; i++) {
        tx.AddQuery(MIGRATIONS[i], i);
    }
    g_db.Execute(tx, TXCB_Success, TXCB_Failure, _, DBPrio_High);
}

void TXCB_Success(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData) {
    char query[128];
    // Record all completed migrations to table, naive inserts
    for(int i = 0; i < numQueries; i++) {
        g_db.Format(query, sizeof(query), "INSERT INTO stats_migrations (id,state) VALUES ('%d', 1)", queryData[numQueries]);
        g_db.Query(DBCB_RecordMigration, query, queryData[numQueries]);
    }
}

void TXCB_Failure(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData) {
    SetFailState("Applying %d migrations failed on migration #%d: ", numQueries, queryData[failIndex], error);
}

void DBCB_RecordMigration(Handle db, DBResultSet results, const char[] error, int migrationId) {
    if(results == null || db == null) {
        SetFailState("Recording migration success failed on migration #%d: %s", migrationId, error);
    }
    PrintToServer("[Stats] Applied migration #%d successfully", migrationId);
}