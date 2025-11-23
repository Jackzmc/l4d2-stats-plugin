enum queryType {
	QUERY_ANY,
	QUERY_HEATMAPS,
	QUERY_WEAPON_STATS,
	QUERY_UPDATE_STAT,
	QUERY_POINTS,
	QUERY_UPDATE_USER,
	QUERY_UPDATE_NAME_HISTORY,
	QUERY_MAP_INFO,
	QUERY_MAP_RATE,
	QUERY_UPDATE_USER_STATS,
	QUERY_INSERT_SESSION,
	_QUERY_MAX
}
char QUERY_TYPE_ID[_QUERY_MAX][] = {
	"-any-",
	"HEATMAPS",
	"WEAPON_STATS",
	"UPDATE_STAT",
	"POINTS",
	"UPDATE_USER",
	"UPDATE_USER_NAME_HISTORY",
	"MAP_INFO",
	"MAP_RATE",
	"UPDATE_USER_STATS",
	"INSERT_SESSION_STATS"
};

//Setups a user, this tries to fetch user by steamid
void SetupUserInDB(int client, const char steamid[32]) {
	if(client > 0 && !IsFakeClient(client)) {
		strcopy(g_players[client].user.steamid, 32, steamid);
		char query[128];
		

		// TODO: 	connections, first_join last_join
		Format(query, sizeof(query), "SELECT last_alias,connections,created_date,last_join_date FROM stats_users WHERE steamid='%s'", steamid);
		SQL_TQuery(g_db, DBCT_CheckUserExistance, query, GetClientUserId(client));
	}
}

void SubmitPoints(int client) {
	if(g_players[client].pointsQueue.Length > 0) {
		char query[4098];
		Format(query, sizeof(query), "INSERT INTO stats_points (steamid,type,amount,timestamp,multiplier) VALUES ");
		// TODO; merge
		for(int i = 0; i < g_players[client].pointsQueue.Length; i++) {
			int type = g_players[client].pointsQueue.Get(i, 0);
			int amount = g_players[client].pointsQueue.Get(i, 1);
			int timestamp = g_players[client].pointsQueue.Get(i, 2);
			int multiplier = g_players[client].pointsQueue.Get(i, 3);
			Format(query, sizeof(query), "%s('%s',%d,%d,%d,%d)%c",
				query,

				g_players[client].user.steamid,
				type,
				amount,
				timestamp,
				multiplier,

				i == g_players[client].pointsQueue.Length - 1 ? ' ' : ',' // No trailing comma on last entry
			);
		}
		SQL_TQuery(g_db, DBCT_Generic, query, QUERY_POINTS, DBPrio_Low);
		g_players[client].pointsQueue.Clear();
	}
}

void SubmitWeaponStats(int client) {
	if(g_players[client].user.steamid[0] == '\0') {
		LogError("SubmitWeaponStats: Steamid is empty");
		return;
	} 
	if(g_players[client].wpn.pendingStats != null && g_players[client].wpn.pendingStats.Size > 0) {
		// Force save weapon stats, instead of waiting for player to switch weapon
		char query[512], weapon[64];
		
		StringMapSnapshot snapshot = g_players[client].wpn.pendingStats.Snapshot();
		WeaponStatistics stats;
		for(int i = 0; i < snapshot.Length; i++) {
			snapshot.GetKey(i, weapon, sizeof(weapon));
			if(weapon[0] == '\0') continue;
			g_players[client].wpn.pendingStats.GetArray(weapon, stats, sizeof(stats));
			if(stats.minutesUsed == 0) continue;
			g_db.Format(query, sizeof(query), 
				"INSERT INTO stats_weapon_usages (steamid,weapon,minutesUsed,totalDamage,kills,headshots) VALUES ('%s','%s',%f,%d,%d,%d) ON DUPLICATE KEY UPDATE minutesUsed=minutesUsed+%f,totalDamage=totalDamage+%d,kills=kills+%d,headshots=headshots+%d",
				g_players[client].user.steamid,
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
	if(g_players[client].pendingHeatmaps != null && g_players[client].pendingHeatmaps.Length > 0) {
		PendingHeatMapData hmd;
		char query[2048];
		Format(query, sizeof(query), "INSERT INTO stats_heatmaps (steamid,map,timestamp,type,x,y,z) VALUES ");
		int length = g_players[client].pendingHeatmaps.Length;
		char commaChar = ',';
		for(int i = 0; i < length; i++) {
			g_players[client].pendingHeatmaps.GetArray(i, hmd);
			// Add commas to every entry but trailing
			if(i == length - 1) {
				commaChar = ' ';
			}
			Format(query, sizeof(query), "%s('%s','%s',%d,%d,%d,%d,%d)%c", 
				query,
				g_players[client].user.steamid,
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
		g_players[client].pendingHeatmaps.Erase(length-1);
	}
}

// Creates a new game entry and populates game.id
void CreateGame() {
	char query[256];
	g_db.Format(query, sizeof(query), 
		"INSERT INTO stats_games (date_start,date_start_finale,map_id,gamemode,difficulty,server_tags,stat_version) VALUES (%d,%d,'%s','%s',%d,'%s',%d)",
		game.startTime, 		//date_start
		GetTime(), 				//date_start_finale
		game.mapId, 			//map_id
		game.gamemode, 			//gamemode
		game.difficulty, 		//difficulty
		serverTags, 			//server_tags
		STAT_METRIC_VERSION     //stat_version
	);
	g_db.Query(DBCT_CreateGame, query, _, DBPrio_Low);
}

void UpdateGame() {
	if(!game.id) ThrowError("game.id missing");
	char query[256];
	g_db.Format(query, sizeof(query), 
		"UPDATE stats_games SET date_end=%d WHERE id=%d",
		GetTime(), 				//date_end
		game.id 				//id
	);
	g_db.Query(DBCT_CreateGame, query, _);
}


// Submits map info, ignoring any duplicate errors
void SubmitMapInfo() {
	char title[128];
	InfoEditor_GetString(0, "DisplayTitle", title, sizeof(title));
	int chapters = L4D_GetMaxChapters();
	char query[128];
	g_db.Format(query, sizeof(query), "INSERT IGNORE INTO stats_map_info (mapid,name,chapter_count) VALUES ('%s','%s',%d)", game.mapId, title, chapters);
	g_db.Query(DBCT_Generic, query, QUERY_MAP_INFO, DBPrio_Low);
}

// Creates new game sessions for every stored user
void RecordSessionStats() {
	AnyMapSnapshot snapshot = g_sessionDataStorage.Snapshot();
	SessionData saveData;
	for(int i = 0; i < snapshot.Length; i++) {
		int key = snapshot.GetKey(i);
		g_sessionDataStorage.GetArray(key, saveData, sizeof(saveData));
		saveData.flags |= view_as<int>(Session_PresentInfinale);
		RecordPlayerSession(saveData);
	} 

	delete snapshot;
}

// Updates stats_user with new data
// 
// Called at end of every chapter, for all users, and then is reset.
void RecordUserStats(UserData user) {
	char query[1024];
	g_db.Format(query, sizeof(query), 
		"UPDATE stats_users SET " ...
		"points=points+%d,deaths=deaths+%d,damage_taken=damage_taken+%d,damage_dealt=damage_dealt+%d,pickups_bile=pickups_bile+%d,pickups_molotov=pickups_molotov+%d,pickups_pipebomb=pickups_pipebomb+%d,pickups_pills=pickups_pills+%d,pickups_adrenaline=pickups_adrenaline+%d,used_kit_self=used_kit_self+%d,used_kit_other=used_kit_other+%d,used_defib=used_defib+%d,used_pills=used_pills+%d,used_adrenaline=used_adrenaline+%d,times_incapped=times_incapped+%d,times_hanging=times_hanging+%d,times_revive_other=times_revive_other+%d,kills_melee=kills_melee+%d,kills_tank=kills_tank+%d,kills_tank_solo=kills_tank_solo+%d,kills_tank_melee=kills_tank_melee+%d,damage_dealt_friendly=damage_dealt_friendly+%d,damage_taken_friendly=damage_taken_friendly+%d,kills_common=kills_common+%d,kills_common_headshots=kills_common_headshots+%d,door_opens=door_opens+%d,damage_dealt_tank=damage_dealt_tank+%d,damage_dealt_witch=damage_dealt_witch+%d,finales_won=finales_won+%d,kills_smoker=kills_smoker+%d,kills_boomer=kills_boomer+%d,kills_hunter=kills_hunter+%d,kills_spitter=kills_spitter+%d,kills_jockey=kills_jockey+%d,kills_charger=kills_charger+%d,kills_witch=kills_witch+%d,used_ammo_packs=used_ammo_packs+%d,kills_friendly=kills_friendly+%d,throws_puke=throws_puke+%d,throws_molotov=throws_molotov+%d,throws_pipe=throws_pipe+%d,damage_dealt_fire=damage_dealt_fire+%d,kills_fire=kills_fire+%d,kills_pipebomb=kills_pipebomb+%d,kills_minigun=kills_minigun+%d,caralarms_activated=caralarms_activated+%d,witches_crowned=witches_crowned+%d,witches_crowned_angry=witches_crowned_angry+%d,smokers_selfcleared=smokers_selfcleared+%d,rocks_hitby=rocks_hitby+%d,hunters_deadstopped=hunters_deadstopped+%d,times_cleared_pinned=times_cleared_pinned+%d,times_pinned=times_pinned+%d,honks=honks+%d,seconds_alive=seconds_alive+%d,seconds_idle=seconds_idle+%d,seconds_dead=seconds_dead+%d,times_boomed_teammate=times_boomed_teammate+%d,times_boomed_self=times_boomed_self+%d,times_boomed=times_boomed+%d,forgot_kit_count=forgot_kit_count+%d,kits_slapped=kits_slapped+%d" 
		... " WHERE steamid = '%s'",
		user.common.points,
		user.common.deaths,
		user.common.damage_taken,
		user.common.damage_dealt,
		user.user.pickups_bile,
		user.user.pickups_molotov,
		user.user.pickups_pipebomb,
		user.user.pickups_pills,
		user.user.pickups_adrenaline,
		user.common.used_kit_self,
		user.common.used_kit_other,
		user.common.used_defib,
		user.common.used_pills,
		user.common.used_adrenaline,
		user.common.times_incapped,
		user.common.times_hanging,
		user.common.times_revive_other,
		user.common.kills_melee,
		user.common.kills_tank,
		user.user.kills_tank_solo,
		user.user.kills_tank_melee,
		user.common.damage_dealt_friendly,
		user.common.damage_taken_friendly,
		user.common.kills_common,
		user.user.kills_common_headshots,
		user.user.door_opens,
		user.common.damage_dealt_tank,
		user.common.damage_dealt_witch,
		user.user.finales_won,
		user.common.kills_smoker,
		user.common.kills_boomer,
		user.common.kills_hunter,
		user.common.kills_spitter,
		user.common.kills_jockey,
		user.common.kills_charger,
		user.common.kills_witch,
		user.user.used_ammo_packs,
		user.user.kills_friendly,
		user.common.used_bile, 		//throws_puke
		user.common.used_molotov, 	//throws_molotov
		user.common.used_pipebomb,  //throws_pipe
		user.common.damage_dealt_fire,
		user.common.kills_fire,
		user.common.kills_pipebomb,
		user.common.kills_minigun,
		user.common.caralarms_activated,
		user.common.witches_crowned,
		user.user.witches_crowned_angry,
		user.common.smokers_selfcleared,
		user.common.rocks_hitby,
		user.common.hunters_deadstopped,
		user.common.times_cleared_pinned,
		user.common.times_pinned,
		user.common.honks,
		user.common.seconds_alive,
		user.common.seconds_idle,
		user.common.seconds_dead,
		user.common.times_boomed_teammate,
		user.user.times_boomed_self,
		user.common.times_boomed,
		user.user.forgot_kit_count,
		user.user.kits_slapped,
		user.steamid
	);
	g_db.Query(DBCT_Generic, query, QUERY_UPDATE_USER_STATS);
}

// creates new stats_sessions for game.id
void RecordPlayerSession(SessionData session) {
	if(!game.id) ThrowError("game id missing");
	// size of just INSERT (...) VALUES (...) template is ~811 characters
	// steamid is +32 char, every int is maybe 4-8 chars
	char query[1024];
	g_db.Format(query, sizeof(query), 
		"INSERT INTO " ... 
		"(game_id,steamid,flags,join_time,character_type,ping,kills_common,kills_melee,damage_dealt, damage_taken,damage_dealt_friendly_count,damage_taken_friendly_count,damage_dealt_friendly,damage_taken_friendly,used_kit_self,used_kit_other,used_defib,used_molotov,used_pipebomb,used_bile,used_pills,used_adrenaline,times_revive_other,times_incapped,times_hanging,deaths,kills_boomer,kills_smoker, kills_jockey,kills_hunter,kills_spitter,kills_charger,kills_tank,kills_witch,kills_fire,kills_pipebomb,kills_minigun,honks,top_weapon,seconds_alive,witches_crowned,smokers_selfcleared,rocks_hitby,rocks_dodged,hunters_deadstopped,times_pinned,times_cleared_pinned,times_boomed_teammates,times_boomed,damage_dealt_tank,damage_dealt_witch, caralarms_activated)" ...
		" VALUES " ...
		"(%d,'%s',%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)",
		game.id,
		session.steamid,
		session.flags,
		session.join_time,
		session.lastSurvivorType,   //character_type
		0, 						     //ping TODO: 
		session.common.kills_common, 
		session.common.kills_melee,  
		session.common.damage_dealt,
		session.common.damage_taken,
		session.common.damage_dealt_friendly_count,
		session.common.damage_taken_friendly_count,
		session.common.damage_dealt_friendly,
		session.common.damage_taken_friendly,
		session.common.used_kit_self,
		session.common.used_kit_other,
		session.common.used_defib,
		session.common.used_molotov,
		session.common.used_pipebomb,
		session.common.used_molotov,
		session.common.used_pills,
		session.common.used_adrenaline,
		session.common.times_revive_other,
		session.common.times_incapped,
		session.common.times_hanging,
		session.common.deaths,
		session.common.kills_boomer,
		session.common.kills_smoker,
		session.common.kills_jockey,
		session.common.kills_hunter,
		session.common.kills_spitter,
		session.common.kills_charger,
		session.common.kills_tank,
		session.common.kills_witch,
		session.common.kills_fire,
		session.common.kills_pipebomb,
		session.common.kills_minigun,
		session.common.honks,
		"", // top _weapon TODO: 
		session.common.seconds_alive,
		session.common.seconds_idle,
		session.common.seconds_dead,
		session.common.witches_crowned,
		session.common.smokers_selfcleared,
		session.common.rocks_hitby,
		session.common.rocks_dodged,
		session.common.hunters_deadstopped,
		session.common.times_pinned,
		session.common.times_cleared_pinned,
		session.common.times_boomed_teammate,
		session.common.times_boomed,
		session.common.damage_dealt_tank,
		session.common.damage_dealt_witch,
		session.common.caralarms_activated,
		session.common.longest_shot_distance
	);
	g_db.Query(DBCT_Generic, query, QUERY_INSERT_SESSION);
}