void DBCT_CheckUserExistance(Handle db, DBResultSet results, const char[] error, any data) {
	if(db == INVALID_HANDLE || results == INVALID_HANDLE) {
		LogError("DBCT_CheckUserExistance returned error: %s", error);
		return;
	}
	//initialize variables
	int client = GetClientOfUserId(data); 
	if(client == 0) return;
	int alias_length = 2*MAX_NAME_LENGTH+1;
	char alias[MAX_NAME_LENGTH], ip[40], country_name[45];
	char[] safe_alias = new char[alias_length];

	//Get a SQL-safe player name, and their counttry and IP
	GetClientName(client, alias, sizeof(alias));
	SQL_EscapeString(g_db, alias, safe_alias, alias_length);
	GetClientIP(client, ip, sizeof(ip));
	GeoipCountry(ip, country_name, sizeof(country_name));

	char query[255]; 
	if(results.RowCount == 0) {
		//user does not exist in db, create now
		Format(query, sizeof(query), "INSERT INTO `stats_users` (`steamid`, `last_alias`, `last_join_date`,`created_date`,`country`) VALUES ('%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), '%s')", players[client].steamid, safe_alias, country_name);
		g_db.Query(DBCT_Generic, query, QUERY_UPDATE_USER);

		Format(query, sizeof(query), "%N is joining for the first time", client);
		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID) {
				PrintToChat(i, query);
			}
		}
		PrintToServer("[l4d2_stats_recorder] Created new database entry for %N (%s)", client, players[client].steamid);
	} else {
		//User does exist, check if alias is outdated and update some columns (last_join_date, country, connections, or last_alias)
		results.FetchRow();
		char prevName[32];
		// last_alias,points,connections,created_date,last_join_date
		results.FetchString(0, prevName, sizeof(prevName));
		players[client].points = results.FetchInt(1);
		players[client].connections = results.FetchInt(2);
		players[client].firstJoinedTime = results.FetchInt(3);
		players[client].lastJoinedTime = results.FetchInt(4);

		if(players[client].points == 0) {
			PrintToServer("[l4d2_stats_recorder] Warning: Existing player %N (%d) has no points", client, client);
		}
		int connections_amount = g_lateLoaded ? 0 : 1;

		Format(query, sizeof(query), "UPDATE `stats_users` SET `last_alias`='%s', `last_join_date`=UNIX_TIMESTAMP(), `country`='%s', connections=connections+%d WHERE `steamid`='%s'", safe_alias, country_name, connections_amount, players[client].steamid);
		g_db.Query(DBCT_Generic, query, QUERY_UPDATE_USER);
		if(!StrEqual(prevName, alias)) {
			// Add prev name to history
			g_db.Format(query, sizeof(query), "INSERT INTO user_names_history (steamid, name, created) VALUES ('%s','%s', UNIX_TIMESTAMP())", players[client].steamid, alias);
			g_db.Query(DBCT_Generic, query, QUERY_UPDATE_NAME_HISTORY);
		}
	}
}
//Generic database response that logs error
void DBCT_Generic(Handle db, Handle child, const char[] error, queryType data) {
	if(db == null || child == null) {
		if(data != QUERY_ANY) {
			LogError("DBCT_Generic query `%s` returned error: %s", QUERY_TYPE_ID[data], error);
		} else {
			LogError("DBCT_Generic returned error: %s", error);
		}
	}
}

void DBCT_RateMap(Handle db, Handle child, const char[] error, int userid) { 
	int client = GetClientOfUserId(userid);
	if(client == 0) return;
	if(db == null || child == null) {
		LogError("DBCT_RateMap error: %s", error);
		PrintToChat(client, "An error occurred while rating campaign");
	} else {
		PrintToChat(client, "Rating submitted for %s", game.mapTitle);
	}
}

#define MAX_UUID_RETRY_ATTEMPTS 1
void DBCT_GetUUIDForCampaign(Handle db, DBResultSet results, const char[] error, int attempt) {
	if(results != INVALID_HANDLE) {
		if(results.FetchRow()) {
			results.FetchString(0, game.uuid, sizeof(game.uuid));
			DBResult result;
			bool hasData = results.FetchInt(1, result) && result == DBVal_Data;
			// PrintToServer("mapinfo: %d. result: %d. hasData:%b", results.FetchInt(1), result, hasData);
			if(!hasData) {
				SubmitMapInfo();
			}
			PrintToServer("UUID for campaign: %s | Difficulty: %d", game.uuid, game.difficulty);
			return;
		} else {
			game.uuid[0] = '\0';
			LogError("RecordCampaign, failed to get UUID: no data was returned");
		}
	} else {
		LogError("RecordCampaign, failed to get UUID: %s", error);
	}
	// Error
	game.uuid[0] = '\0';
	if(attempt < MAX_UUID_RETRY_ATTEMPTS) {
		FetchUUID(attempt + 1);
	}
}
//After a user's stats were flushed, reset any statistics needed to zero.
void DBCT_FlushQueuedStats(Handle db, Handle child, const char[] error, int userid) {
	if(db == INVALID_HANDLE || child == INVALID_HANDLE) {
		LogError("DBCT_FlushQueuedStats returned error: %s", error);
	}else{
		int client = GetClientOfUserId(userid);
		if(client > 0)
			ResetInternal(client, false);
	}
}