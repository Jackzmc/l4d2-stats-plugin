#pragma semicolon 1
#pragma newdecls required

// #define DEBUG 1
#define PLUGIN_VERSION "2.0.0"

#include <sourcemod>
#include <sdktools>
#include <geoip>
#include <sdkhooks>
#include <left4dhooks>
#include <jutils>
#include <l4d_info_editor>
#undef REQUIRE_PLUGIN
#include <l4d2_skill_detect>

// SETTINGS

// Each coordinate (x,y,z) is rounded to nearest multiple of this. 
#define HEATMAP_POINT_SIZE 10
#define MAX_HEATMAP_VISUALS 200
#define HEATMAP_PAGINATION_SIZE 500
#define DISTANCE_CALC_TIMER_INTERVAL 4.0

public Plugin myinfo = 
{
	name =  "L4D2 Stats Recorder", 
	author = "jackzmc", 
	description = "", 
	version = PLUGIN_VERSION, 
	url = "https://git.jackz.me/jackz/l4d2-stats"
};

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
	"MAP_RATE"
};

ConVar hServerTags, hZDifficulty, hStatsUrl;
ConVar hHeatmapInterval;
ConVar hHeatmapActive;
Database g_db;
char gamemode[32], serverTags[255], websiteUrlPrefix[128];
bool g_lateLoaded; //Has finale started?

int g_iLastBoomUser;
float g_iLastBoomTime;
Menu g_rateMenu;

char OFFICIAL_MAP_NAMES[14][] = {
	"Dead Center",   // c1
	"Dark Carnival", // c2
	"Swamp Fever",   // c3
	"Hard Rain",     // c4
	"The Parish",    // c5
	"The Passing",   // c6
	"The Sacrifice", // c7
	"No Mercy",      // c8
	"Crash Course",  // c9
	"Death Toll",    // c10
	"Dead Air",      // c11
	"Blood Harvest", // c12
	"Cold Stream",   // c13
	"Last Stand",    // c14
};

enum struct Game {
	int difficulty;
	int startTime;
	int finaleStartTime;
	int clownHonks;
	bool isVersusSwitched;
	bool finished; // finale_vehicle_ready triggered
	bool submitted; // finale_win triggered
	char gamemode[32];
	char uuid[64];
	char mapId[64];
	char mapTitle[128];
	char missionId[64];
	bool isCustomMap;

	bool IsVersusMode() {
		return StrEqual(this.gamemode, "versus") || StrEqual(this.gamemode, "scavenge");
	}

	void GetMap() {
		GetCurrentMap(this.mapId, sizeof(this.mapId));
		this.isCustomMap = this.mapId[0] != 'c' || !IsCharNumeric(this.mapId[1]) || !(IsCharNumeric(this.mapId[2]) || this.mapId[2] == 'm');
		if(this.isCustomMap)
			InfoEditor_GetString(0, "DisplayTitle", this.mapTitle, sizeof(this.mapTitle));
		else {
			int mapIndex = StringToInt(this.mapId[1]) - 1;
			strcopy(this.mapTitle, sizeof(this.mapTitle), OFFICIAL_MAP_NAMES[mapIndex]);
		}
		InfoEditor_GetString(0, "Name", this.missionId, sizeof(this.missionId));
		PrintToServer("[Stats] %s \"%s\" %s (c=%b)", this.mapId, this.mapTitle, this.missionId, this.isCustomMap);
	}
}

enum PointRecordType {
	PType_Invalid = 0,
	PType_FinishCampaign,
	PType_CommonKill,
	PType_SpecialKill,
	PType_TankKill,
	PType_WitchKill,
	PType_TankKill_Solo,
	PType_TankKill_Melee,
	PType_Headshot,
	PType_FriendlyFire,
	PType_HealOther,
	PType_ReviveOther,
	PType_ResurrectOther,
	PType_DeployAmmo,
	PType_FriendlyKilled,
	PType_WitchCrowned,
	PType_SelfClearSmoker,
	PType_HunterDeadstopped,

	PType_Count
}
int PointValueDefaults[PType_Count] = {
	0, // Generic
	0, // Finish Campaign - don't assign any value as tank kills / other stats should take in
	1, // Common Kill
	6, // Special Kill
	200, // Tank Kill
	25, // Witch Kill
	100, // Tank Kill (Solo)  [bonus to tank kill]
	50, // Tank Kill (Melee) [bonus to tank kill]
	4, // Headshot kill (commons only) [bonus to common kill]
	-5, // Friendly Fire
	50, // Heal Other
	25, // Revive Other
	50, // Defib Other
	5, // Deploy Special Ammo
	-500, // Friendly killed
	100, // Witch crowned
	10, // Self cleared smoker
	10, // Hunter dead stopped
};

#include "stats/weapons.sp"
#include "stats/player.sp"

Player players[MAXPLAYERS+1];
Game game;

#include "stats/db/core.sp"
#include "stats/timers.sp"
#include "stats/modules/heatmaps.sp"
#include "stats/modules/rating.sp"
#include "stats/modules/honks.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("Stats_GetPoints", Native_GetPoints);
	if(late) g_lateLoaded = true;
	return APLRes_Success;
}
//TODO: player_use (Check laser sights usage)
//TODO: Versus as infected stats
//TODO: Move kills to queue stats not on demand
//TODO: Track if lasers were had?

public void OnPluginStart() {
	EngineVersion g_Game = GetEngineVersion();
	if(g_Game != Engine_Left4Dead2) {
		SetFailState("This plugin is for L4D/L4D2 only.");	
	}

	InitDB();
	

	g_rateMenu = SetupRateMenu();

	if(g_lateLoaded) {
		//If plugin late loaded, grab all real user's steamids again, then recreate user
		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) {
				char steamid[32];
				GetClientAuthId(i, AuthId_Steam2, steamid, sizeof(steamid));
				//Recreate user (grabs points, so it won't reset)
				SetupUserInDB(i, steamid);
			}
		}
	}

	hClownModeChangeChance = CreateConVar("l4d2_clown_mutate_chance", "0.3", "Percent chance of population changing", FCVAR_NONE, true, 0.0, true, 1.0);
	hClownMode = CreateConVar("l4d2_honk_mode", "0", "Shows a live clown honk count and increased shove amount.\n0 = OFF, 1 = ON, 2 = Randomly change population", FCVAR_NONE, true, 0.0, true, 2.0);
	hMinShove = FindConVar("z_gun_swing_coop_min_penalty");
	hMaxShove = FindConVar("z_gun_swing_coop_max_penalty");

	hClownMode.AddChangeHook(CVC_ClownModeChanged);

	hServerTags = CreateConVar("l4d2_statsrecorder_tags", "", "A comma-seperated list of tags that will be used to identity this server.");
	hServerTags.GetString(serverTags, sizeof(serverTags));
	hServerTags.AddChangeHook(CVC_TagsChanged);
	hStatsUrl = CreateConVar("l4d2_stats_url", "https://stats.example.com/games/", "The URL prefix to use to link at end of game to view stats. Ensure trailing slash at the end");
	hStatsUrl.GetString(websiteUrlPrefix, sizeof(websiteUrlPrefix));
	hStatsUrl.AddChangeHook(CVC_UrlChanged);

	ConVar hGamemode = FindConVar("mp_gamemode");
	hGamemode.GetString(gamemode, sizeof(gamemode));
	hGamemode.AddChangeHook(CVC_GamemodeChange);

	hZDifficulty = FindConVar("z_difficulty");

	hHeatmapActive = CreateConVar("l4d2_statsrecorder_heatmaps_enabled", "0", "Should heatmap data be recorded? 1 for ON. Visualize heatmaps with /heatmaps", FCVAR_NONE, true, 0.1);
	hHeatmapInterval = CreateConVar("l4d2_statsrecorder_heatmap_interval", "60", "Determines how often position heatmaps are recorded in seconds.", FCVAR_NONE, true, 0.1);


	HookEvent("player_bot_replace", Event_PlayerEnterIdle);
	HookEvent("bot_player_replace", Event_PlayerLeaveIdle);
	//Hook all events to track statistics
	HookEvent("player_disconnect", Event_PlayerFullDisconnect);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_incapacitated", Event_PlayerIncap);
	HookEvent("pills_used", Event_ItemUsed);
	HookEvent("defibrillator_used", Event_ItemUsed);
	HookEvent("adrenaline_used", Event_ItemUsed);
	HookEvent("heal_success", Event_ItemUsed);
	HookEvent("revive_success", Event_ItemUsed); //Yes it's not an item. No I don't care.
	HookEvent("melee_kill", Event_MeleeKill);
	HookEvent("tank_killed", Event_TankKilled);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("infected_death", Event_InfectedDeath);
	HookEvent("door_open", Event_DoorOpened);
	HookEvent("upgrade_pack_used", Event_UpgradePackUsed);
	HookEvent("triggered_car_alarm", Event_CarAlarm);
	//Used for campaign recording:
	HookEvent("finale_start", Event_FinaleStart);
	HookEvent("gauntlet_finale_start", Event_FinaleStart);
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
	HookEvent("finale_vehicle_ready", Event_FinaleVehicleReady);
	HookEvent("finale_win", Event_FinaleWin);
	HookEvent("hegrenade_detonate", Event_GrenadeDenonate);
	//Used to transition checkpoint statistics for stats_games
	HookEvent("game_init", Event_GameStart);
	HookEvent("round_end", Event_RoundEnd);

	HookEvent("boomer_exploded", Event_BoomerExploded);
	HookEvent("versus_round_start", Event_VersusRoundStart);
	HookEvent("map_transition", Event_MapTransition);
	HookEvent("player_ledge_grab", Event_LedgeGrab);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_left_safe_area", Event_PlayerLeftStartArea);
	AddNormalSoundHook(SoundHook);
	#if defined DEBUG
	RegConsoleCmd("sm_debug_stats", Command_DebugStats, "Debug stats");
	#endif
	RegAdminCmd("sm_stats", Command_PlayerStats, ADMFLAG_GENERIC);
	RegAdminCmd("sm_heatmaps", Command_Heatmaps, ADMFLAG_GENERIC);
	RegAdminCmd("sm_heatmap", Command_Heatmaps, ADMFLAG_GENERIC);
	RegConsoleCmd("sm_rate", Command_RateMap);

	AutoExecConfig(true, "l4d2_stats_recorder");

	for(int i = 1; i <= MaxClients; i++) {
		players[i].Init();
	}
	
	CreateTimer(hHeatmapInterval.FloatValue, Timer_HeatMapInterval, _, TIMER_REPEAT);
	CreateTimer(DISTANCE_CALC_TIMER_INTERVAL, Timer_CalculateDistances, _, TIMER_REPEAT);
}

//When plugin is being unloaded: flush all user's statistics.
public void OnPluginEnd() {
	for(int i=1; i<=MaxClients;i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && players[i].steamid[0]) {
			FlushQueuedStats(i, false);
		}
	}
	ClearHeatMapEntities();
}

/////////////////////////////////
// CONVAR CHANGES
/////////////////////////////////
void CVC_GamemodeChange(ConVar convar, const char[] oldValue, const char[] newValue) {
	strcopy(game.gamemode, sizeof(game.gamemode), newValue);
	strcopy(gamemode, sizeof(gamemode), newValue);
}
void CVC_TagsChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	strcopy(serverTags, sizeof(serverTags), newValue);
}
void CVC_UrlChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	strcopy(websiteUrlPrefix, sizeof(websiteUrlPrefix), newValue);
}

/////////////////////////////////
// PLAYER AUTH
/////////////////////////////////
public void OnClientAuthorized(int client, const char[] auth) {
	if(client > 0 && !IsFakeClient(client)) {
		char steamid[32];
		strcopy(steamid, sizeof(steamid), auth);
		SetupUserInDB(client, steamid);
	}
}
public void OnClientPutInServer(int client) {
	if(!IsFakeClient(client)) {
		SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
	}
}
public void OnClientDisconnect(int client) {
	//Check if any pending stats to send.
	if(!IsFakeClient(client) && IsClientInGame(client)) {
		//Record campaign session, incase they leave early. 
		//Should only fire if disconnects after escape_vehicle_ready and before finale_win (credits screen)
		if(game.finished && game.uuid[0] && players[client].steamid[0]) {
			IncrementSessionStat(client);
			RecordCampaign(client);
			IncrementStat(client, "finales_won", 1);
			players[client].RecordPoint(PType_FinishCampaign);
		}

		FlushQueuedStats(client, true);
		players[client].ResetFull();

		//ResetSessionStats(client); //Can't reset session stats cause transitions!
	}
}

void Event_PlayerFirstSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0) {
		players[client].joinedGameTime = GetTime();
	}
}

void Event_PlayerFullDisconnect(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0) {
		players[client].ResetFull();
	}
}

void Event_PlayerEnterIdle(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("player"));
	if(client > 0) {
		players[client].idleStartTime = GetTime();
	}
}

void Event_PlayerLeaveIdle(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("player"));
	if(client > 0 && players[client].idleStartTime > 0) {
		players[client].idleStartTime = 0;
		players[client].totalIdleTime = GetTime() - players[client].idleStartTime;
	}
}

//Record a special kill to local variable
void IncrementSpecialKill(int client, int special) {
	switch(special) {
		case 1: players[client].sSmokerKills++;
		case 2: players[client].sBoomerKills++;
		case 3: players[client].sHunterKills++;
		case 4: players[client].sSpitterKills++;
		case 5: players[client].sJockeyKills++;
		case 6: players[client].sChargerKills++;
	}
}
//Called ONLY on game_start
void ResetSessionStats(int client, bool resetAll) {
	players[client].m_checkpointZombieKills =			0;
	players[client].m_checkpointSurvivorDamage = 		0;
	players[client].m_checkpointMedkitsUsed = 			0;
	players[client].m_checkpointPillsUsed = 			0;
	players[client].m_checkpointMolotovsUsed = 			0;
	players[client].m_checkpointPipebombsUsed = 		0;
	players[client].m_checkpointBoomerBilesUsed = 		0;
	players[client].m_checkpointAdrenalinesUsed = 		0;
	players[client].m_checkpointDefibrillatorsUsed = 	0;
	players[client].m_checkpointDamageTaken =			0;
	players[client].m_checkpointReviveOtherCount = 		0;
	players[client].m_checkpointFirstAidShared = 		0;
	players[client].m_checkpointIncaps  = 				0;
	if(resetAll) players[client].m_checkpointDeaths = 	0;
	players[client].m_checkpointMeleeKills = 			0;
	players[client].sBoomerKills  = 0;
	players[client].sSmokerKills  = 0;
	players[client].sJockeyKills  = 0;
	players[client].sHunterKills  = 0;
	players[client].sSpitterKills = 0;
	players[client].sChargerKills = 0;
	players[client].clownsHonked  = 0;

	players[client].damageSurvivorFF 		= 0;
	players[client].damageFFTaken 			= 0;
	players[client].damageSurvivorFFCount   = 0;
	players[client].damageFFTakenCount 		= 0;
}
//Called via FlushQueuedStats which is called on disconnects / map transitions / game_start or round_end
void ResetInternal(int client, bool disconnect) {
	players[client].damageSurvivorGiven 	= 0;
	players[client].doorOpens 				= 0;
	players[client].witchKills 				= 0;
	players[client].upgradePacksDeployed 	= 0;
	players[client].molotovDamage 			= 0;
	players[client].pipeKills 				= 0;
	players[client].molotovKills 			= 0;
	players[client].minigunKills 			= 0;
	if(!disconnect) {
		players[client].startedPlaying = GetTime();
	}
	players[client].wpn.Flush();
}
void IncrementSessionStat(int client) {
	players[client].m_checkpointZombieKills += 			GetEntProp(client, Prop_Send, "m_checkpointZombieKills");
	players[client].m_checkpointSurvivorDamage += 		players[client].damageSurvivorFF;
	players[client].m_checkpointMedkitsUsed += 			GetEntProp(client, Prop_Send, "m_checkpointMedkitsUsed");
	players[client].m_checkpointPillsUsed += 			GetEntProp(client, Prop_Send, "m_checkpointPillsUsed");
	players[client].m_checkpointMolotovsUsed += 		GetEntProp(client, Prop_Send, "m_checkpointMolotovsUsed");
	players[client].m_checkpointPipebombsUsed += 		GetEntProp(client, Prop_Send, "m_checkpointPipebombsUsed");
	players[client].m_checkpointBoomerBilesUsed += 		GetEntProp(client, Prop_Send, "m_checkpointBoomerBilesUsed");
	players[client].m_checkpointAdrenalinesUsed += 		GetEntProp(client, Prop_Send, "m_checkpointAdrenalinesUsed");
	players[client].m_checkpointDefibrillatorsUsed += 	GetEntProp(client, Prop_Send, "m_checkpointDefibrillatorsUsed");
	players[client].m_checkpointDamageTaken +=			GetEntProp(client, Prop_Send, "m_checkpointDamageTaken");
	players[client].m_checkpointReviveOtherCount += 	GetEntProp(client, Prop_Send, "m_checkpointReviveOtherCount");
	players[client].m_checkpointFirstAidShared += 		GetEntProp(client, Prop_Send, "m_checkpointFirstAidShared");
	players[client].m_checkpointIncaps  += 				GetEntProp(client, Prop_Send, "m_checkpointIncaps");
	players[client].m_checkpointDeaths += 				GetEntProp(client, Prop_Send, "m_checkpointDeaths");
	players[client].m_checkpointMeleeKills += 			GetEntProp(client, Prop_Send, "m_checkpointMeleeKills");
	PrintToServer("[l4d2_stats_recorder] Incremented checkpoint stats for %N", client);
}

/////////////////////////////////
//DATABASE CALLBACKS
/////////////////////////////////
//Handles the CreateDBUser() response. Either updates alias and stores points, or creates new SQL user.
void SubmitMapInfo() {
	char title[128];
	InfoEditor_GetString(0, "DisplayTitle", title, sizeof(title));
	int chapters = L4D_GetMaxChapters();
	char query[128];
	g_db.Format(query, sizeof(query), "INSERT INTO map_info (mapid,name,chapter_count) VALUES ('%s','%s',%d)", game.mapId, title, chapters);
	g_db.Query(DBCT_Generic, query, QUERY_MAP_INFO, DBPrio_Low);
}
////////////////////////////
// COMMANDS
///////////////////////////

#define DATE_FORMAT "%F at %I:%M %p"
Action Command_PlayerStats(int client, int args) {
	if(args == 0) {
		ReplyToCommand(client, "Syntax: /stats <player name>");
		return Plugin_Handled;
	}
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[1], target_count;
	bool tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			1,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	int player = target_list[0];
	if(player > 0) {
		ReplyToCommand(client, "");
		ReplyToCommand(client, "\x04Name: \x05%N", player);
		ReplyToCommand(client, "\x04Points: \x05%d", players[player].points);
		ReplyToCommand(client, "\x04Joins: \x05%d", players[player].connections);
		FormatTime(arg, sizeof(arg), DATE_FORMAT, players[player].firstJoinedTime);
		ReplyToCommand(client, "\x04First Joined: \x05%s", arg);
		FormatTime(arg, sizeof(arg), DATE_FORMAT, players[player].lastJoinedTime);
		ReplyToCommand(client, "\x04Last Joined: \x05%s", arg);
		if(players[player].idleStartTime > 0) {
			FormatTime(arg, sizeof(arg), DATE_FORMAT, players[player].idleStartTime);
			ReplyToCommand(client, "\x04Idle Start Time: \x05%s", arg);
		}
		ReplyToCommand(client, "\x04Minutes Idle: \x05%d", players[player].totalIdleTime);
	}

	return Plugin_Handled;
}

#if defined DEBUG
public Action Command_DebugStats(int client, int args) {
	if(client == 0 && !IsDedicatedServer()) {
		ReplyToCommand(client, "This command must be used as a player.");
	}else {
		ReplyToCommand(client, "Statistics for %s", players[client].steamid);
		ReplyToCommand(client, "lastDamage = %f", players[client].lastWeaponDamage);
		ReplyToCommand(client, "points = %d", players[client].points);
		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2) {
				ReplyToCommand(client, "p#%i | pending heatmaps: %d | ", i, players[i].pendingHeatmaps.Length, players[i].pointsQueue.Length);
			}
		}
		ReplyToCommand(client, "connections = %d", players[client].connections);
		// ReplyToCommand(client, "Total weapons cache %d", game.weaponUsages.Size);
	}
	return Plugin_Handled;
}
#endif

////////////////////////////
// EVENTS 
////////////////////////////
void Event_PlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast) {
	if(GetSurvivorCount() > 4) return;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		// Check if they do not have a kit
		if(GetPlayerWeaponSlot(client, 3) == -1) {
			// Check if there are any kits remaining in the safe area (that they did not pickup)
			int entity = -1;
			float pos[3];
			while((entity = FindEntityByClassname(entity, "weapon_first_aid_kit_spawn")) != INVALID_ENT_REFERENCE) {
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", pos);
				if(L4D_IsPositionInLastCheckpoint(pos)) {
					PrintToConsoleAll("[Stats] Player %N forgot to pickup a kit", client);
					IncrementStat(client, "forgot_kit_count");
					break;
				}
			}
		}
	}
}
void OnWeaponSwitch(int client, int weapon) {
	// Update weapon when switching to a new one
	if(weapon > -1) {
		
		// TODO: if melee
		players[client].wpn.SetActiveWeapon(weapon);
	}
}
public void Event_BoomerExploded(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2) {
		g_iLastBoomTime = GetGameTime();
		g_iLastBoomUser = attacker;
	}
}

public Action L4D_OnVomitedUpon(int victim, int &attacker, bool &boomerExplosion) {
	if(boomerExplosion && GetGameTime() - g_iLastBoomTime < 23.0) {
		if(victim == g_iLastBoomUser)
			IncrementStat(g_iLastBoomUser, "boomer_mellos_self");
		else
			IncrementStat(g_iLastBoomUser, "boomer_mellos");
	}
	return Plugin_Continue;
}

Action SoundHook(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed) {
	if(numClients > 0 && StrContains(sample, "clown") > -1) {
		// The sound of the honk comes from the honker directly, so we loop all the receiving clients
		// Then the one with the exact coordinates of the sound, is the honker 
		static float zPos[3], survivorPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", zPos);
		for(int i = 0; i < numClients; i++) {
			int client = clients[i];
			GetClientAbsOrigin(client, survivorPos);
			if(survivorPos[0] == zPos[0] && survivorPos[1] == zPos[1] && survivorPos[2] == zPos[2]) {
				game.clownHonks++;
				players[client].clownsHonked++;
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}
//Records the amount of HP done to infected (zombies)
public void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker > 0 && !IsFakeClient(attacker)) {
		int dmg = event.GetInt("amount");
		players[attacker].damageSurvivorGiven += dmg;
		players[attacker].wpn.damage += dmg;
	}
}
public void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker > 0 && !IsFakeClient(attacker)) {
		bool blast = event.GetBool("blast");
		bool headshot = event.GetBool("headshot");
		bool using_minigun = event.GetBool("minigun");

		if(headshot) {
			players[attacker].RecordPoint(PType_Headshot, .allowMerging = true);
			players[attacker].wpn.headshots++;
		}

		players[attacker].RecordPoint(PType_CommonKill, .allowMerging = true);
		players[attacker].wpn.kills++;


		if(using_minigun) {
			players[attacker].minigunKills++;
		} else if(blast) {
			players[attacker].pipeKills++;
		}
	}
}
public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim_team = GetClientTeam(victim);
	int dmg = event.GetInt("dmg_health");
	if(dmg <= 0) return;
	if(attacker > 0 && !IsFakeClient(attacker)) {
		int attacker_team = GetClientTeam(attacker);
		players[attacker].wpn.damage += dmg;


		if(attacker_team == 2) {
			players[attacker].damageSurvivorGiven += dmg;
			char wpn_name[16];
			event.GetString("weapon", wpn_name, sizeof(wpn_name));

			if(victim_team == 3 && StrEqual(wpn_name, "inferno", true)) {
				players[attacker].molotovDamage += dmg;
			}
		} else if(attacker_team == 3) {
			players[attacker].damageInfectedGiven += dmg;
		}
		if(attacker_team == 2 && victim_team == 2) {
			players[attacker].RecordPoint(PType_FriendlyFire, .allowMerging = true);
			players[attacker].damageSurvivorFF += dmg;
			players[attacker].damageSurvivorFFCount++;
			players[victim].damageFFTaken += dmg;
			players[victim].damageFFTakenCount++;
		}
	}
}
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(victim > 0) {
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		int victim_team = GetClientTeam(victim);

		if(!IsFakeClient(victim)) {
			if(victim_team == 2) {
				IncrementStat(victim, "survivor_deaths", 1);
				float pos[3];
				GetClientAbsOrigin(victim, pos);
				players[victim].RecordHeatMap(HeatMap_Death, pos);
			}
		}

		if(attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2) {
			if(victim_team == 3) {
				int victim_class = GetEntProp(victim, Prop_Send, "m_zombieClass");
				char class[8], statname[16];
				players[attacker].wpn.kills++;


				if(GetInfectedClassName(victim_class, class, sizeof(class))) {
					IncrementSpecialKill(attacker, victim_class);
					Format(statname, sizeof(statname), "kills_%s", class);
					IncrementStat(attacker, statname, 1);
					players[attacker].RecordPoint(PType_SpecialKill, .allowMerging = true);
				}
				char wpn_name[16];
				event.GetString("weapon", wpn_name, sizeof(wpn_name));
				if(StrEqual(wpn_name, "inferno", true) || StrEqual(wpn_name, "entityflame", true)) {
					players[attacker].molotovKills++;
				}
				IncrementStat(victim, "infected_deaths", 1);
			} else if(victim_team == 2) {
				IncrementStat(attacker, "ff_kills", 1);
				players[attacker].RecordPoint(PType_FriendlyKilled);
			}
		}
	}
	
}
public void Event_MeleeKill(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		players[client].RecordPoint(PType_CommonKill, .allowMerging = true);
	}
}
public void Event_TankKilled(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int solo = event.GetBool("solo") ? 1 : 0;
	int melee_only = event.GetBool("melee_only") ? 1 : 0;

	if(attacker > 0 && !IsFakeClient(attacker)) {
		if(solo) {
			IncrementStat(attacker, "tanks_killed_solo", 1);
			players[attacker].RecordPoint(PType_TankKill_Solo);
		}
		if(melee_only) {
			players[attacker].RecordPoint(PType_TankKill_Melee);
			IncrementStat(attacker, "tanks_killed_melee", 1);
		}
		players[attacker].RecordPoint(PType_TankKill);
		IncrementStat(attacker, "tanks_killed", 1);
	}
}
public void Event_DoorOpened(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && event.GetBool("closed") && !IsFakeClient(client)) {
		players[client].doorOpens++;

	}
}
void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsFakeClient(client) && GetClientTeam(client) == 2) {
		IncrementStat(client, "survivor_incaps", 1);
		float pos[3];
		GetClientAbsOrigin(client, pos);
		players[client].RecordHeatMap(HeatMap_Incap, pos);
	}
}
void Event_LedgeGrab(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsFakeClient(client) && GetClientTeam(client) == 2) {
		float pos[3];
		GetClientAbsOrigin(client, pos);
		players[client].RecordHeatMap(HeatMap_LedgeGrab, pos);
		IncrementStat(client, "survivor_incaps", 1);
	}
}
//Track heals, or defibs
void Event_ItemUsed(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		if(StrEqual(name, "heal_success", true)) {
			int subject = GetClientOfUserId(event.GetInt("subject"));
			if(subject == client) {
				IncrementStat(client, "heal_self", 1);
			}else{
				players[client].RecordPoint(PType_HealOther);
				IncrementStat(client, "heal_others", 1);
			}
		} else if(StrEqual(name, "revive_success", true)) {
			int subject = GetClientOfUserId(event.GetInt("subject"));
			if(subject != client) {
				IncrementStat(client, "revived_others", 1);
				players[client].RecordPoint(PType_ReviveOther);
				IncrementStat(subject, "revived", 1);
			}
		} else if(StrEqual(name, "defibrillator_used", true)) {
			players[client].RecordPoint(PType_ResurrectOther);
			IncrementStat(client, "defibs_used", 1);
		} else{
			IncrementStat(client, name, 1);
		}
	}
}

public void Event_UpgradePackUsed(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		players[client].upgradePacksDeployed++;
		players[client].RecordPoint(PType_DeployAmmo);
	}
}
public void Event_CarAlarm(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		IncrementStat(client, "caralarms_activated", 1);
	}
}
public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		players[client].witchKills++;
		players[client].RecordPoint(PType_WitchKill);
	}
}


public void Event_GrenadeDenonate(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		char wpn_name[32];
		GetClientWeapon(client, wpn_name, sizeof(wpn_name));
	}
}
///THROWABLE TRACKING
//This is used to track throwable throws 
public void OnEntityCreated(int entity, const char[] classname) {
	if(IsValidEntity(entity) && StrContains(classname, "_projectile", true) > -1 && HasEntProp(entity, Prop_Send, "m_hOwnerEntity")) {
		RequestFrame(EntityCreateCallback, entity);
	}
}
void EntityCreateCallback(int entity) {
	if(!HasEntProp(entity, Prop_Send, "m_hOwnerEntity") || !IsValidEntity(entity)) return;
	char class[16];

	GetEntityClassname(entity, class, sizeof(class));
	int entOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(entOwner > 0 && entOwner <= MaxClients) {
		if(StrContains(class, "vomitjar", true) > -1) {
			IncrementStat(entOwner, "throws_puke", 1);
		} else if(StrContains(class, "molotov", true) > -1) {
			IncrementStat(entOwner, "throws_molotov", 1);
		} else if(StrContains(class, "pipe_bomb", true) > -1) {
			IncrementStat(entOwner, "throws_pipe", 1);
		}
	}
}
public void L4D2_CInsectSwarm_CanHarm_Post(int acid, int spitter, int entity) {
	if(entity <= 32 && GetClientTeam(entity) == 2) {
		players[entity].timeInAcid.TryStart();
	}
	// TODO: accumulate
}
public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) {
	if(GetEntityFlags(client) & FL_ONFIRE) {
		players[client].timeInFire.TryStart();
	} else {
		players[client].timeInFire.TryEnd();
	}
}
bool isTransition = false;
////MAP EVENTS
public void Event_GameStart(Event event, const char[] name, bool dontBroadcast) {
	game.startTime = GetTime();
	game.clownHonks = 0;
	game.submitted = false;

	PrintToServer("[l4d2_stats_recorder] Started recording statistics for new session");
	for(int i = 1; i <= MaxClients; i++) {
		ResetSessionStats(i, true);
		ResetInternal(i, true);
	}
}
public void OnMapStart() {
	if(isTransition) {
		isTransition = false;
	}else{
		game.difficulty = GetDifficultyInt();
	}
	game.GetMap();
}
public void OnMapEnd() {
	if(g_HeatMapEntities != null) delete g_HeatMapEntities;
}
public void Event_VersusRoundStart(Event event, const char[] name, bool dontBroadcast) {
	if(game.IsVersusMode()) {
		game.isVersusSwitched = !game.isVersusSwitched; 
	}
}
public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast) {
	isTransition = true;
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsFakeClient(i)) {
			IncrementSessionStat(i);
			FlushQueuedStats(i, false);
		}
	}
}
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	PrintToServer("[l4d2_stats_recorder] round_end; flushing");
	game.finished = false;
	
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			//ResetSessionStats(i, false);
			FlushQueuedStats(i, false);
		}
	}
}
/*Order of events:
finale_start: Gets UUID
escape_vehicle_ready: IF fired, sets var campaignFinished to true.
finale_win: Record all players, campaignFinished = false

if player disconnects && campaignFinished: record their session. Won't be recorded in finale_win
*/
//Fetch UUID from finale start, should be ready for events finale_win OR escape_vehicle_ready
void Event_FinaleStart(Event event, const char[] name, bool dontBroadcast) {
	game.finaleStartTime = GetTime();
	game.difficulty = GetDifficultyInt();
	//Use the same UUID for versus
	//FIXME: This was causing UUID to not fire another new one for back-to-back-coop
	//if(game.IsVersusMode && game.isVersusSwitched) return;
	FetchUUID();
}
void FetchUUID(int attempt = 0) {
	char query[128];
	g_db.Format(query, sizeof(query), "SELECT UUID() AS UUID, (SELECT !ISNULL(mapid) from map_info where mapid = '%s') as mapid", game.mapId);
	g_db.Query(DBCT_GetUUIDForCampaign, query, attempt);
}
void Event_FinaleVehicleReady(Event event, const char[] name, bool dontBroadcast) {
	//Get UUID on finale_start
	if(L4D_IsMissionFinalMap()) {
		game.difficulty = GetDifficultyInt();
		game.finished = true;
	}
}

void Event_FinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast) {
	// if(L4D_IsMissionFinalMap()) {
	// 	// TODO: check if user has rated?
	// 	g_rateMenu.SetTitle("Rate %s", game.mapTitle);
	// 	for(int i = 1; i <= MaxClients; i++) {
	// 		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2) {
	// 			// g_rateMenu.Display(i, 0);
	// 		}
	// 	}
	// }
}

void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast) {
	if(!L4D_IsMissionFinalMap() || game.submitted) return;
	game.difficulty = event.GetInt("difficulty");
	game.finished = false;
	char shortID[9];
	StrCat(shortID, sizeof(shortID), game.uuid);

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && GetClientTeam(i) == 2) {
			int client = i;
			if(IsFakeClient(i)) {
				if(!HasEntProp(i, Prop_Send, "m_humanSpectatorUserID")) continue;
				client = GetClientOfUserId(GetEntPropEnt(i, Prop_Send, "m_humanSpectatorUserID"));
				//get real client
			}
			if(players[client].steamid[0]) {
				players[client].RecordPoint(PType_FinishCampaign);
				IncrementSessionStat(client);
				RecordCampaign(client);
				IncrementStat(client, "finales_won", 1);
				if(game.uuid[0] != '\0')
					PrintToChat(client, "View this game's statistics at %s%s", shortID, websiteUrlPrefix);
				if(game.clownHonks > 0) {
					PrintToChat(client, "%d clowns were honked this session, you honked %d", game.clownHonks, players[client].clownsHonked);
				}
			}

		}
	}	
	if(game.clownHonks > 0) {
		ArrayList winners = new ArrayList();
		int mostHonks;
		for(int j = 1; j <= MaxClients; j++) {
			if(players[j].clownsHonked <= 0 || !IsClientInGame(j) || IsFakeClient(j)) continue;
			if(players[j].clownsHonked > mostHonks || winners.Length == 0) {
				mostHonks = players[j].clownsHonked;
				// Clear the winners list
				winners.Clear();
				winners.Push(j);
			} else if(players[j].clownsHonked == mostHonks) {
				// They are tied with the current winner, add them to list
				winners.Push(j);
			}
		}

		if(mostHonks > 0) {
			if(winners.Length > 1) {
				char msg[256];
				Format(msg, sizeof(msg), "%N", winners.Get(0));
				for(int i = 1; i < winners.Length; i++) {
					int winner = winners.Get(i);
					if(!IsClientConnected(winner)) continue;
					if(i == winners.Length - 1) {
						// If this is the last winner, use 'and '
						Format(msg, sizeof(msg), "%s and %N", msg, winner);
					} else {
						// In between first and last winner, comma
						Format(msg, sizeof(msg), "%s, %N", msg, winner);
					}
				}
				PrintToChatAll("%s tied for the most clown honks with a count of %d", msg, mostHonks);
			} else {
				int winner = winners.Get(0);
				if(IsClientConnected(winner)) {
					PrintToChatAll("%N had the most clown honks with a count of %d", winner, mostHonks);
				}
			}
		} 
		delete winners;
	}
	for(int i = 1; i <= MaxClients; i++) {
		players[i].clownsHonked = 0;
		if(IsClientInGame(i) && !IsFakeClient(i)) {
			PrintToChat(i, "Rate this map with /rate # (1 lowest, 5 highest)");
		}
	}
	game.submitted = true;
	game.clownHonks = 0;
}


////////////////////////////
// FORWARD EVENTS
///////////////////////////
public void OnWitchCrown(int survivor, int damage) {
	IncrementStat(survivor, "witches_crowned", 1);
}
public void OnSmokerSelfClear( int survivor, int smoker, bool withShove ) {
	IncrementStat(survivor, "smokers_selfcleared", 1);
}
public void OnTankRockEaten( int tank, int survivor ) {
	IncrementStat(survivor, "rocks_hitby", 1);
}
public void OnHunterDeadstop(int survivor, int hunter) {
	IncrementStat(survivor, "hunters_deadstopped", 1);
}
public void OnSpecialClear( int clearer, int pinner, int pinvictim, int zombieClass, float timeA, float timeB, bool withShove ) {
	IncrementStat(clearer, "cleared_pinned", 1);
	IncrementStat(pinvictim, "times_pinned", 1);
}
////////////////////////////
// NATIVES
///////////////////////////
public any Native_GetPoints(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	return players[client].points;
}

////////////////////////////
// STOCKS
///////////////////////////
//Simply prints the respected infected's class name based on their numeric id. (not client/user ID)
stock bool GetInfectedClassName(int type, char[] buffer, int bufferSize) {
	switch(type) {
		case 1: strcopy(buffer, bufferSize, "smoker");
		case 2: strcopy(buffer, bufferSize, "boomer");
		case 3: strcopy(buffer, bufferSize, "hunter");
		case 4: strcopy(buffer, bufferSize, "spitter");
		case 5: strcopy(buffer, bufferSize, "jockey");
		case 6: strcopy(buffer, bufferSize, "charger");
		default: return false;
	}
	return true;
}

stock int GetDifficultyInt() {
	char diff[16];
	hZDifficulty.GetString(diff, sizeof(diff));
	if(StrEqual(diff, "easy", false)) return 0;
	else if(StrEqual(diff, "hard", false)) return 2;
	else if(StrEqual(diff, "impossible", false)) return 3;
	else return 1;
}

stock int GetSurvivorCount() {
	int count;
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && GetClientTeam(i) == 2) {
			count++;
		}
	}
	return count;
}