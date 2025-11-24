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
		Format(query, sizeof(query), 
			"INSERT INTO `stats_users` (`steamid`, `last_alias`, `last_join_date`,`created_date`,`country`)" ... 
			" VALUES " ...
			"('%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), '%s')", 
			g_players[client].user.steamid, safe_alias, country_name
		);
		g_db.Query(DBCT_Generic, query, QUERY_UPDATE_USER);

		Format(query, sizeof(query), "%N is joining for the first time", client);
		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID) {
				PrintToChat(i, query);
			}
		}
		PrintToServer("[l4d2_stats_recorder] Created new database entry for %N (%s)", client, g_players[client].user.steamid);
	} else {
		//User does exist, check if alias is outdated and update some columns (last_join_date, country, connections, or last_alias)
		results.FetchRow();
		char prevName[32];
		results.FetchString(0, prevName, sizeof(prevName));
		//last_alias,connections,created_date,last_join_date
		g_players[client].connections = results.FetchInt(1);
		g_players[client].firstJoinedTime = results.FetchInt(2);
		g_players[client].lastJoinedTime = results.FetchInt(3);

		int connections_amount = g_lateLoaded ? 0 : 1;

		Format(query, sizeof(query), 
			"UPDATE stats_users"
			... " SET last_alias='%s', last_join_date=UNIX_TIMESTAMP(), country='%s', connections=connections+%d"
			... " WHERE `steamid`='%s'", 
			safe_alias, country_name, connections_amount, g_players[client].user.steamid
		);
		g_db.Query(DBCT_Generic, query, QUERY_UPDATE_USER);
		if(!StrEqual(prevName, alias)) {
			// Add prev name to history
			g_db.Format(query, sizeof(query), 
				"INSERT INTO stats_names_history (steamid, name, created)" 
				... " VALUES" 
				... " ('%s','%s', UNIX_TIMESTAMP())", 
				g_players[client].user.steamid, alias
			);
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

//After game created, get id
void DBCT_CreateGame(Database db, DBResultSet results, const char[] error, int userid) {
	if(db == INVALID_HANDLE || results == INVALID_HANDLE) {
		LogError("DBCT_CreateGame returned error: %s", error);
	} else if(results.InsertId > 0) {
		game.id = results.InsertId
		LogInfo("Game ID: %d", game.id);
	}
}