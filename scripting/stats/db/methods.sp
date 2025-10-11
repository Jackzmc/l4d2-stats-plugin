//Setups a user, this tries to fetch user by steamid
void SetupUserInDB(int client, const char steamid[32]) {
	if(client > 0 && !IsFakeClient(client)) {
		players[client].ResetFull();

		strcopy(players[client].steamid, 32, steamid);
		players[client].startedPlaying = GetTime();
		char query[128];
		

		// TODO: 	connections, first_join last_join
		Format(query, sizeof(query), "SELECT last_alias,points,connections,created_date,last_join_date FROM stats_users WHERE steamid='%s'", steamid);
		SQL_TQuery(g_db, DBCT_CheckUserExistance, query, GetClientUserId(client));
	}
}
//Increments a statistic by X amount
void IncrementStat(int client, const char[] name, int amount = 1, bool lowPriority = true) {
	if(client > 0 && !IsFakeClient(client) && IsClientConnected(client)) {
		//Only run if client valid client, AND has steamid. Not probably necessarily anymore.
		if (players[client].steamid[0]) {
			if(g_db == INVALID_HANDLE) {
				LogError("Database handle is invalid.");
				return;
			}
			int escaped_name_size = 2*strlen(name)+1;
			char[] escaped_name = new char[escaped_name_size];
			char query[255];
			g_db.Escape(name, escaped_name, escaped_name_size);
			Format(query, sizeof(query), "UPDATE stats_users SET `%s`=`%s`+%d WHERE steamid='%s'", escaped_name, escaped_name, amount, players[client].steamid);
			#if defined DEBUG
			PrintToServer("[Debug] Updating Stat %s (+%d) for %N (%d) [%s]", name, amount, client, client, players[client].steamid);
			#endif 
			SQL_TQuery(g_db, DBCT_Generic, query, QUERY_UPDATE_STAT, lowPriority ? DBPrio_Low : DBPrio_Normal);
		}
	}
}

void RecordCampaign(int client) {
	if (client > 0 && IsClientInGame(client)) {
		char query[1023];

		if(players[client].m_checkpointZombieKills == 0) {
			PrintToServer("Warn: Client %N for %s | 0 zombie kills", client, game.uuid);
		}

		char model[64];
		GetClientModel(client, model, sizeof(model));

		// unused now:
		char topWeapon[1];

		int ping = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iPing", _, client);
		if(ping < 0) ping = 0;

		int finaleTimeTotal = (game.finaleStartTime > 0) ? GetTime() - game.finaleStartTime : 0;
		Format(query, sizeof(query), "INSERT INTO stats_games (`steamid`, `map`, `gamemode`,`campaignID`, `finale_time`, `join_time`,`date_start`,`date_end`, `zombieKills`, `survivorDamage`, `MedkitsUsed`, `PillsUsed`, `MolotovsUsed`, `PipebombsUsed`, `BoomerBilesUsed`, `AdrenalinesUsed`, `DefibrillatorsUsed`, `DamageTaken`, `ReviveOtherCount`, `FirstAidShared`, `Incaps`, `Deaths`, `MeleeKills`, `difficulty`, `ping`,`boomer_kills`,`smoker_kills`,`jockey_kills`,`hunter_kills`,`spitter_kills`,`charger_kills`,`server_tags`,`characterType`,`honks`,`top_weapon`, `SurvivorFFCount`, `SurvivorFFTakenCount`, `SurvivorFFDamage`, `SurvivorFFTakenDamage`) VALUES ('%s','%s','%s','%s',%d,%d,%d,UNIX_TIMESTAMP(),%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,'%s',%d,%d,'%s',%d,%d,%d,%d)",
			players[client].steamid,
			game.mapId,
			gamemode,
			game.uuid,
			finaleTimeTotal,
			players[client].joinedGameTime,
			game.startTime > 0 ? game.startTime : game.finaleStartTime, //incase iGameStartTime not set: use finaleTimeStart
			//unix_timestamp(),
			players[client].m_checkpointZombieKills,
			players[client].m_checkpointSurvivorDamage,
			players[client].m_checkpointMedkitsUsed,
			players[client].m_checkpointPillsUsed,
			players[client].m_checkpointMolotovsUsed,
			players[client].m_checkpointPipebombsUsed,
			players[client].m_checkpointBoomerBilesUsed,
			players[client].m_checkpointAdrenalinesUsed,
			players[client].m_checkpointDefibrillatorsUsed,
			players[client].m_checkpointDamageTaken,
			players[client].m_checkpointReviveOtherCount,
			players[client].m_checkpointFirstAidShared,
			players[client].m_checkpointIncaps,
			players[client].m_checkpointDeaths,
			players[client].m_checkpointMeleeKills,
			game.difficulty,
			ping, //record user ping
			players[client].sBoomerKills,
			players[client].sSmokerKills,
			players[client].sJockeyKills,
			players[client].sHunterKills,
			players[client].sSpitterKills,
			players[client].sChargerKills,
			serverTags,
			GetSurvivorType(model),
			players[client].clownsHonked,
			topWeapon,
			players[client].damageSurvivorFFCount, //SurvivorFFCount
			players[client].damageFFTakenCount, //SurvivorFFTakenCount
			players[client].damageSurvivorFF, //SurvivorFFDamage
			players[client].damageFFTaken //SurvivorFFTakenDamage
		);
		SQL_LockDatabase(g_db);
		bool result = SQL_FastQuery(g_db, query);
		SQL_UnlockDatabase(g_db);
		if(!result) {
			char error[128];
			SQL_GetError(g_db, error, sizeof(error));
			LogError("[l4d2_stats_recorder] RecordCampaign for %d failed. UUID %s | Query: `%s` | Error: %s", game.uuid, client, query, error);
		}
	}
}
//Flushes all the tracked statistics, and runs UPDATE SQL query on user. Then resets the variables to 0
void FlushQueuedStats(int client, bool disconnect) {
	//Update stats (don't bother checking if 0.)
	int minutes_played = (GetTime() - players[client].startedPlaying) / 60;
	//Incase somehow startedPlaying[client] not set (plugin reloaded?), defualt to 0
	if(minutes_played >= 2147483645) {
		players[client].startedPlaying = GetTime();
		minutes_played = 0;
	}
	//Prevent points from being reset by not recording until user has gotten a point. 
	if(players[client].points > 0) {
		char query[1023];
		Format(query, sizeof(query), "UPDATE stats_users SET survivor_damage_give=survivor_damage_give+%d,survivor_damage_rec=survivor_damage_rec+%d, infected_damage_give=infected_damage_give+%d,infected_damage_rec=infected_damage_rec+%d,survivor_ff=survivor_ff+%d,survivor_ff_rec=survivor_ff_rec+%d,common_kills=common_kills+%d,common_headshots=common_headshots+%d,melee_kills=melee_kills+%d,door_opens=door_opens+%d,damage_to_tank=damage_to_tank+%d, damage_witch=damage_witch+%d,minutes_played=minutes_played+%d, kills_witch=kills_witch+%d,points=%d,packs_used=packs_used+%d,damage_molotov=damage_molotov+%d,kills_molotov=kills_molotov+%d,kills_pipe=kills_pipe+%d,kills_minigun=kills_minigun+%d,clowns_honked=clowns_honked+%d,total_distance_travelled=total_distance_travelled+%d WHERE steamid='%s'",
			//VARIABLE													//COLUMN NAME

			players[client].damageSurvivorGiven, 						//survivor_damage_give
			GetEntProp(client, Prop_Send, "m_checkpointDamageTaken"),   //survivor_damage_rec
			players[client].damageInfectedGiven,  						//infected_damage_give
			players[client].damageInfectedRec,   						//infected_damage_rec
			players[client].damageSurvivorFF,    						//survivor_ff
			players[client].damageFFTaken,								//survivor_ff_rec
			GetEntProp(client, Prop_Send, "m_checkpointZombieKills"), 	//common_kills
			GetEntProp(client, Prop_Send, "m_checkpointHeadshots"),   	//common_headshots
			GetEntProp(client, Prop_Send, "m_checkpointMeleeKills"),  	//melee_kills
			players[client].doorOpens, 									//door_opens
			GetEntProp(client, Prop_Send, "m_checkpointDamageToTank"),  //damage_to_tank
			GetEntProp(client, Prop_Send, "m_checkpointDamageToWitch"), //damage_witch
			minutes_played, 											//minutes_played
			players[client].witchKills, 								//kills_witch
			players[client].points, 									//points
			players[client].upgradePacksDeployed, 						//packs_used
			players[client].molotovDamage, 								//damage_molotov
			players[client].pipeKills, 									//kills_pipe,
			players[client].molotovKills,								//kills_molotov
			players[client].minigunKills,								//kills_minigun
			players[client].clownsHonked,								//clowns_honked
			players[client].distance.accumulation,						//total_distance_travelled
			players[client].steamid[0]
		);
		
		//If disconnected, can't put on another thread for some reason: Push it out fast
		if(disconnect) {
			SQL_LockDatabase(g_db);
			SQL_FastQuery(g_db, query);
			SQL_UnlockDatabase(g_db);
			ResetInternal(client, true);
		}else{
			SQL_TQuery(g_db, DBCT_FlushQueuedStats, query, GetClientUserId(client));
			SubmitPoints(client);
			SubmitWeaponStats(client);
			SubmitHeatmaps(client);
		}
	}
}

void SubmitPoints(int client) {
	if(players[client].pointsQueue.Length > 0) {
		char query[4098];
		Format(query, sizeof(query), "INSERT INTO stats_points (steamid,type,amount,timestamp,multiplier) VALUES ");
		// TODO; merge
		for(int i = 0; i < players[client].pointsQueue.Length; i++) {
			int type = players[client].pointsQueue.Get(i, 0);
			int amount = players[client].pointsQueue.Get(i, 1);
			int timestamp = players[client].pointsQueue.Get(i, 2);
			int multiplier = players[client].pointsQueue.Get(i, 3);
			Format(query, sizeof(query), "%s('%s',%d,%d,%d,%d)%c",
				query,

				players[client].steamid,
				type,
				amount,
				timestamp,
				multiplier,

				i == players[client].pointsQueue.Length - 1 ? ' ' : ',' // No trailing comma on last entry
			);
		}
		SQL_TQuery(g_db, DBCT_Generic, query, QUERY_POINTS, DBPrio_Low);
		players[client].pointsQueue.Clear();
	}
}

void SubmitWeaponStats(int client) {
	if(players[client].wpn.pendingStats != null && players[client].wpn.pendingStats.Size > 0) {
		// Force save weapon stats, instead of waiting for player to switch weapon
		char query[512], weapon[64];
		
		StringMapSnapshot snapshot = players[client].wpn.pendingStats.Snapshot();
		WeaponStatistics stats;
		for(int i = 0; i < snapshot.Length; i++) {
			snapshot.GetKey(i, weapon, sizeof(weapon));
			if(weapon[0] == '\0') continue;
			players[client].wpn.pendingStats.GetArray(weapon, stats, sizeof(stats));
			if(stats.minutesUsed == 0) continue;
			g_db.Format(query, sizeof(query), 
				"INSERT INTO stats_weapon_usages (steamid,weapon,minutesUsed,totalDamage,kills,headshots) VALUES ('%s','%s',%f,%d,%d,%d) ON DUPLICATE KEY UPDATE minutesUsed=minutesUsed+%f,totalDamage=totalDamage+%d,kills=kills+%d,headshots=headshots+%d",
				players[client].steamid,
				weapon,
				stats.minutesUsed,
				stats.totalDamage,
				stats.kills,
				stats.headshots,
				stats.minutesUsed,
				stats.totalDamage,
				stats.kills,
				stats.headshots
			);
			g_db.Query(DBCT_Generic, query, QUERY_WEAPON_STATS, DBPrio_Low);
		}
	}
} 

void SubmitHeatmaps(int client) {
	if(players[client].pendingHeatmaps != null && players[client].pendingHeatmaps.Length > 0) {
		PendingHeatMapData hmd;
		char query[2048];
		Format(query, sizeof(query), "INSERT INTO stats_heatmaps (steamid,map,timestamp,type,x,y,z) VALUES ");
		int length = players[client].pendingHeatmaps.Length;
		char commaChar = ',';
		for(int i = 0; i < length; i++) {
			players[client].pendingHeatmaps.GetArray(i, hmd);
			// Add commas to every entry but trailing
			if(i == length - 1) {
				commaChar = ' ';
			}
			Format(query, sizeof(query), "%s('%s','%s',%d,%d,%d,%d,%d)%c", 
				query,
				players[client].steamid,
				game.mapId, //map nam
				hmd.timestamp,
				hmd.type,
				hmd.pos[0],
				hmd.pos[1],
				hmd.pos[2],
				commaChar
			);
		}

		SQL_TQuery(g_db, DBCT_Generic, query, QUERY_HEATMAPS, DBPrio_Low);
		// Resize using the new length - old length, incase new data shows up.
		players[client].pendingHeatmaps.Erase(length-1);
	}
}

void SubmitMapInfo() {
	char title[128];
	InfoEditor_GetString(0, "DisplayTitle", title, sizeof(title));
	int chapters = L4D_GetMaxChapters();
	char query[128];
	g_db.Format(query, sizeof(query), "INSERT INTO stats_map_info (mapid,name,chapter_count) VALUES ('%s','%s',%d)", game.mapId, title, chapters);
	g_db.Query(DBCT_Generic, query, QUERY_MAP_INFO, DBPrio_Low);
}