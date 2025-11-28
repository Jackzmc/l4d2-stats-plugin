#pragma semicolon 1
#pragma newdecls required

// Don't change
#define PLUGIN_VERSION "3.0.1"
#define STAT_METRIC_VERSION 1 // for stat_version 
#define DEBUG 1

#include <sourcemod>
#include <sdktools>
#include <geoip>
#include <sdkhooks>
#include <left4dhooks>
#include <jutils>
#include <l4d_info_editor>
#undef REQUIRE_PLUGIN
#include <l4d2_skill_detect>
#include <anymap>
#include <log>

// Each coordinate (x,y,z) is rounded to nearest multiple of this. 
#define HEATMAP_POINT_SIZE 10
#define MAX_HEATMAP_VISUALS 200
#define HEATMAP_PAGINATION_SIZE 500
#define DISTANCE_CALC_TIMER_INTERVAL 4.0

public Plugin myinfo = {
	name =  "L4D2 Stats Recorder", 
	author = "jackzmc", 
	description = "", 
	version = PLUGIN_VERSION, 
	url = "https://git.jackz.me/jackz/l4d2-stats"
};


ConVar hServerTags, hZDifficulty, hStatsUrl;
ConVar hHeatmapInterval;
ConVar hHeatmapActive;
Database g_db;
char serverTags[255], websiteUrlPrefix[128];
bool g_lateLoaded; //Has finale started?
bool isTransition = false;

int g_iLastBoomerAttacker;
float g_iLastBoomTime;

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
	int id; // auto inc id

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

	void Init() {
		this.id = 0;
		this.startTime = GetTime();
		this.clownHonks = 0;
		this.submitted = false;
		this.finished = false;
		LogInfo("Started recording statistics for new session (%d)", this.startTime);
	}

	bool IsVersusMode() {
		return StrEqual(this.gamemode, "versus") 
			|| StrEqual(this.gamemode, "scavenge");
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
		LogDebug("%s \"%s\" %s (custom=%b)", this.mapId, this.mapTitle, this.missionId, this.isCustomMap);
	}
}


#include "stats/points.sp"
#include "stats/weapons.sp"
#include "stats/player.sp"

Game game;
PlayerDataContainer g_players[MAXPLAYERS+1];

#include "stats/db/core.sp"
#include "stats/timers.sp"
#include "stats/modules/heatmaps.sp"
#include "stats/modules/rating.sp"
#include "stats/modules/honks.sp"
#include "stats/util.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	if(late) g_lateLoaded = true;
	return APLRes_Success;
}
//TODO: player_use (Check laser sights usage)
//TODO: Versus as infected stats
//TODO: Move kills to queue stats not on demand
//TODO: Track if lasers were had?

public void OnPluginStart() {
	Log_Init("l4d2-stats", Log_Trace, ADMFLAG_GENERIC, "sm_stats", Target_ServerConsole);
	EngineVersion g_Game = GetEngineVersion();
	if(g_Game != Engine_Left4Dead2) {
		SetFailState("This plugin is for L4D/L4D2 only.");	
	}

	InitDB();
	g_sessionDataStorage = new AnyMap();
	
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
	hGamemode.GetString(game.gamemode, sizeof(game.gamemode));
	hGamemode.AddChangeHook(CVC_GamemodeChange);

	hZDifficulty = FindConVar("z_difficulty");

	hHeatmapActive = CreateConVar("l4d2_statsrecorder_heatmaps_enabled", "0", "Should heatmap data be recorded? 1 for ON. Visualize heatmaps with /heatmaps", FCVAR_NONE, true, 0.1);
	hHeatmapInterval = CreateConVar("l4d2_statsrecorder_heatmap_interval", "60", "Determines how often position heatmaps are recorded in seconds.", FCVAR_NONE, true, 0.1);


	HookEvent("player_bot_replace", Event_PlayerEnterIdle);
	HookEvent("bot_player_replace", Event_PlayerLeaveIdle);
	HookEvent("player_spawn", Event_PlayerSpawn);
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
	HookEvent("finale_vehicle_ready", Event_FinaleVehicleReady);
	HookEvent("finale_win", Event_FinaleWin);
	//Used to transition checkpoint statistics for stats_games
	HookEvent("game_init", Event_GameInit);
	HookEvent("game_end", Event_GameEnd);
	HookEvent("round_end", Event_RoundEnd);

	HookEvent("boomer_exploded", Event_BoomerExploded);
	HookEvent("versus_round_start", Event_VersusRoundStart);
	HookEvent("map_transition", Event_MapTransition);
	HookEvent("player_ledge_grab", Event_LedgeGrab);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_left_safe_area", Event_PlayerLeftStartArea);
	HookEvent("player_jump", Event_PlayerJump);
	HookEvent("player_falldamage", Event_FallDamage);
	AddNormalSoundHook(SoundHook);
	#if defined DEBUG
	RegConsoleCmd("sm_debug_stats", Command_DebugStats, "Debug stats");
	#endif
	RegAdminCmd("sm_stats", Command_PlayerStats, ADMFLAG_GENERIC);
	RegAdminCmd("sm_heatmaps", Command_Heatmaps, ADMFLAG_GENERIC);
	RegAdminCmd("sm_heatmap", Command_Heatmaps, ADMFLAG_GENERIC);
	RegConsoleCmd("sm_rate", Command_RateMap);

	AutoExecConfig(true, "l4d2_stats_recorder");

	if(g_lateLoaded) {
		game.Init();
	}
	for(int i = 1; i <= MaxClients; i++) {
		g_players[i].Init();
		if(IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
	
	CreateTimer(hHeatmapInterval.FloatValue, Timer_HeatMapInterval, _, TIMER_REPEAT);
	CreateTimer(DISTANCE_CALC_TIMER_INTERVAL, Timer_CalculateDistances, _, TIMER_REPEAT);
}

//When plugin is being unloaded: flush all user's statistics.
public void OnPluginEnd() {
	LogDebug("plugin ending, flushing all players");
	for(int i=1; i<=MaxClients;i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && g_players[i].user.steamid[0] != '\0') {
			// Update user stats, save session to store
			FlushPlayer(i);
		}
	}
	// Flush store
	if(game.id) {
		LogDebug("plugin ending, flushing active session");
		RecordSessionStats();
	}

	ClearHeatMapEntities();
}

/////////////////////////////////
// CONVAR CHANGES
/////////////////////////////////
void CVC_GamemodeChange(ConVar convar, const char[] oldValue, const char[] newValue) {
	strcopy(game.gamemode, sizeof(game.gamemode), newValue);
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
public void OnClientPutInServer(int client) {
	if(!IsFakeClient(client)) {
		SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
		char steamid[32];
		// We just want a steamid, don't care if its valid
		if(GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), false)) {
			SetupUserInDB(client, steamid);
			g_players[client].Load(client, steamid);
		} else {
			LogWarn("OnClientPutInServer: did not get steamid for %d. this probably causes errors", client);
		}
		// load any saved player data
	}
}
public void OnClientDisconnect(int client) {
	//Check if any pending stats to send.
	if(IsClientInGame(client) && !IsFakeClient(client)) {
		// Record user stats, merge to session, and save session
		FlushPlayer(client);
		// clear out session data, it gets loaded
		g_players[client].Reset();
		LogDebug("disconnect; flushed player and reset %d", client);
	}
}

void Event_PlayerFirstSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		g_players[client].joinedGameTime = GetTime();
	}
}

void Event_PlayerEnterIdle(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("player"));
	if(client > 0 && !IsFakeClient(client)) {
		g_players[client].Calculate();
	}
}

void Event_PlayerLeaveIdle(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("player"));
	if(client > 0 && !IsFakeClient(client)) {
		g_players[client].Calculate();
	}
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
		ReplyToCommand(client, "\x04Session Points: \x05%d", g_players[player].session.common.points);
		ReplyToCommand(client, "\x04Joins: \x05%d", g_players[player].connections);
		FormatTime(arg, sizeof(arg), DATE_FORMAT, g_players[player].firstJoinedTime);
		ReplyToCommand(client, "\x04First Joined: \x05%s", arg);
		FormatTime(arg, sizeof(arg), DATE_FORMAT, g_players[player].lastJoinedTime);
		ReplyToCommand(client, "\x04Last Joined: \x05%s", arg);
	}

	return Plugin_Handled;
}

#if defined DEBUG
public Action Command_DebugStats(int client, int args) {
	if(client == 0 && !IsDedicatedServer()) {
		ReplyToCommand(client, "This command must be used as a player.");
	}else {
		ReplyToCommand(client, "damage_dealt %d %d", g_players[client].user.common.damage_dealt, g_players[client].session.common.damage_dealt);
		ReplyToCommand(client, "damage_taken %d %d", g_players[client].user.common.damage_taken, g_players[client].session.common.damage_taken);
		ReplyToCommand(client, "longest_shot_distance %f", g_players[client].session.session.longest_shot_distance);
		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2) {
				ReplyToCommand(client, "p#%i | pending heatmaps: %d | ", i, g_players[i].pendingHeatmaps.Length, g_players[i].pointsQueue.Length);
			}
		}
	}
	return Plugin_Handled;
}
#endif

////////////////////////////
// MAP EVENTS 
////////////////////////////
void Event_GameInit(Event event, const char[] name, bool dontBroadcast) {
	game.Init();
	for(int i = 1; i <= MaxClients; i++) {
		g_players[i].Reset();
	}
	LogDebug("game init; reset");
	g_sessionDataStorage.Clear();
}
public void OnMapStart() {
	if(isTransition) {
		isTransition = false;
	}else{
		game.difficulty = GetDifficultyInt();
	}
	game.GetMap();
	if(!game.startTime) {
		LogDebug("GameInit wasn't called and map is starting, initializing game");
		game.Init();
	}
}

void Event_VersusRoundStart(Event event, const char[] name, bool dontBroadcast) {
	if(game.IsVersusMode()) {
		game.isVersusSwitched = !game.isVersusSwitched; 
	}
}

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
					g_players[client].user.user.forgot_kit_count++;
					break;
				}
			}
		}
	}
}

void Event_MapTransition(Event event, const char[] name, bool dontBroadcast) {
	isTransition = true;
	// Technically not necessary as OnClientDisconnect will trigger this
	// But just to be on the safe side, why not
	LogDebug("map transition; flushing players");
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsFakeClient(i)) {
			FlushPlayer(i);
		}
	}
}


void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	PrintToServer("[l4d2_stats_recorder] round_end; flushing");
	game.finished = false;
	
	// Everyone died and round is restarting
	// Flush the stats just to be on the safe side
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			FlushPlayer(i);
		}
	}
}

public void OnMapEnd() {
	if(g_HeatMapEntities != null) delete g_HeatMapEntities;
}

void Event_GameEnd(Event event, const char[] name, bool dontBroadcast) {
	LogDebug("game end; reset");
	for(int i = 1; i <= MaxClients; i++) {
		g_players[i].Reset();
	}
	g_sessionDataStorage.Clear();
}
////////////////////////////
// OTHER EVENTS 
////////////////////////////

void OnWeaponSwitch(int client, int weapon) {
	// Update weapon when switching to a new one
	if(weapon > -1) {
		
		// TODO: if melee
		g_players[client].wpn.SetActiveWeapon(weapon);
	}
}
public void Event_BoomerExploded(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2) {
		g_iLastBoomTime = GetGameTime();
		g_iLastBoomerAttacker = attacker;
	}
}

public Action L4D_OnVomitedUpon(int victim, int &attacker, bool &boomerExplosion) {
	if(boomerExplosion && GetGameTime() - g_iLastBoomTime < 23.0) {
		if(victim == g_iLastBoomerAttacker) {
			g_players[victim].user.user.times_boomed_self++;
		} else {
			g_players[g_iLastBoomerAttacker].user.common.times_boomed_teammates++;
		}
		g_players[victim].user.common.times_boomed++;
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
				g_players[client].user.common.honks++;
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}
//Records the amount of HP done to infected (zombies)
void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker > 0 && !IsFakeClient(attacker)) {
		int dmg = event.GetInt("amount");
		g_players[attacker].user.common.damage_dealt += dmg;
		g_players[attacker].wpn.damage += dmg;
	}
}
void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker > 0 && !IsFakeClient(attacker)) {
		bool blast = event.GetBool("blast");
		bool headshot = event.GetBool("headshot");
		bool usingMinigun = event.GetBool("minigun");

		if(headshot) {
			g_players[attacker].RecordPoint(PType_Headshot, .allowMerging = true);
			g_players[attacker].wpn.headshots++;
			g_players[attacker].user.user.kills_common_headshots++;
		}

		g_players[attacker].RecordPoint(PType_CommonKill, .allowMerging = true);
		g_players[attacker].wpn.kills++;
		g_players[attacker].user.common.kills_common++;


		if(usingMinigun) {
			g_players[attacker].user.common.kills_minigun++;
		} else if(blast) {
			g_players[attacker].user.common.kills_pipebomb++;
		}
	}
}
void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victimTeam = victim > 0 ? GetClientTeam(victim) : 0;
	int dmg = event.GetInt("dmg_health");
	if(dmg <= 0) return;
	if(attacker > 0 && !IsFakeClient(attacker)) {
		int attackerTeam = GetClientTeam(attacker);
		g_players[attacker].wpn.damage += dmg;
		g_players[attacker].user.common.damage_dealt += dmg;



		if(attackerTeam == 2) {
			if(victimTeam == 2) {
				g_players[attacker].RecordPoint(PType_FriendlyFire, .allowMerging = true);
				g_players[attacker].user.common.damage_dealt_friendly += dmg;
				g_players[attacker].user.common.damage_dealt_friendly_count++;

				g_players[victim].user.common.damage_taken_friendly += dmg;
				g_players[victim].user.common.damage_taken_friendly_count++;
			} else if(victimTeam == 3) {
				char wpnName[16];
				event.GetString("weapon", wpnName, sizeof(wpnName));

				if(StrEqual(wpnName, "inferno", true)) {
					g_players[attacker].user.common.damage_dealt_fire += dmg;
				}
			}
		}
	}
	
	if(victim > 0 && !IsFakeClient(victim) && victimTeam == 2) {
		g_players[victim].user.common.damage_taken += dmg;
	}
}
void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && GetClientTeam(client) == 2) {
		g_players[client].CalculateTime(client);
	}
}
void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(victim > 0) {
		g_players[victim].CalculateTime(victim);
		int victimTeam = GetClientTeam(victim);

		// Survivor died
		if(!IsFakeClient(victim) && victimTeam == 2) {
			g_players[victim].user.common.deaths++;

			float pos[3];
			GetClientAbsOrigin(victim, pos);
			g_players[victim].RecordHeatMap(HeatMap_Death, pos);
		}

		// If Survivor attacker
		if(attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2) {
			if(victimTeam == 3) {
				int infectedClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
				char class[8];
				g_players[attacker].wpn.kills++;

				if(GetInfectedClassName(infectedClass, class, sizeof(class))) {
					IncrementSpecialKill(g_players[attacker].user, infectedClass);
					g_players[attacker].RecordPoint(PType_SpecialKill, .allowMerging = true);
				}
				char wpnName[16];
				event.GetString("weapon", wpnName, sizeof(wpnName));
				int type = event.GetInt("type");
				if(StrEqual(wpnName, "inferno", true) || StrEqual(wpnName, "entityflame", true)) {
					g_players[attacker].user.common.kills_fire++;
				} else if(type & DMG_BULLET) {
					float distance = GetEntityDistance(attacker, victim);
					if(distance > g_players[attacker].session.session.longest_shot_distance) {
						PrintToServer("[Stats] New highest distance for %N: %f units away", attacker, distance);
						g_players[attacker].session.session.longest_shot_distance = distance;
					}
				}
			} else if(victimTeam == 2) {
				g_players[attacker].user.user.kills_friendly++;
				g_players[attacker].RecordPoint(PType_FriendlyKilled);
			}
		}
	}
}


void Event_MeleeKill(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		g_players[client].user.common.kills_melee++;
		g_players[client].RecordPoint(PType_CommonKill, .allowMerging = true);
	}
}
void Event_TankKilled(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int solo = event.GetBool("solo") ? 1 : 0;
	int melee_only = event.GetBool("melee_only") ? 1 : 0;

	if(attacker > 0 && !IsFakeClient(attacker)) {
		if(solo) {
			g_players[attacker].RecordPoint(PType_TankKill_Solo);
			g_players[attacker].user.user.kills_tank_solo++;
		}
		if(melee_only) {
			g_players[attacker].RecordPoint(PType_TankKill_Melee);
			g_players[attacker].user.user.kills_tank_melee++;
		}
		g_players[attacker].RecordPoint(PType_TankKill);
		g_players[attacker].user.common.kills_tank++;
	}
}
void Event_DoorOpened(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && event.GetBool("closed") && !IsFakeClient(client)) {
		g_players[client].user.user.door_opens++;
	}
}
void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsFakeClient(client) && GetClientTeam(client) == 2) {
		float pos[3];
		GetClientAbsOrigin(client, pos);
		g_players[client].RecordHeatMap(HeatMap_Incap, pos);

		char weaponName[32];
		event.GetString("weapon", weaponName, sizeof(weaponName));
		g_players[client].user.common.times_incapped++;

		LogDebug("incap %N %s", client, weaponName);

		if(StrEqual(weaponName, "inferno")) {
			g_players[client].user.user.times_incapped_fire++;
		} else if(StrEqual(weaponName, "insect_swarm")) {
			g_players[client].user.user.times_incapped_acid++;
		} else {
			int attacker = GetClientOfUserId(event.GetInt("attacker"));
			if(attacker > 0 && GetClientTeam(attacker) == 3) {
				int infectedClass = GetEntProp(client, Prop_Send, "m_zombieClass");
				switch(infectedClass) {
					case 8: g_players[client].user.user.times_incapped_tank++;
					case 7: g_players[client].user.user.times_incapped_witch++;
					default: g_players[client].user.user.times_incapped_special++;
				}
			} else {
				char classname[16];
				GetEntityClassname(attacker, classname, sizeof(classname));
				if(StrEqual(classname, "infected")) {
					g_players[client].user.user.times_incapped_zombie++;
				}
			}
		}
	}
}
void Event_LedgeGrab(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsFakeClient(client) && GetClientTeam(client) == 2) {
		g_players[client].user.common.times_hanging++;

		float pos[3];
		GetClientAbsOrigin(client, pos);
		g_players[client].RecordHeatMap(HeatMap_LedgeGrab, pos);
	}
}
void Event_PlayerJump(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 2) {
		g_players[client].user.common.times_jumped++;
	}
}
void Event_FallDamage(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client) && GetClientTeam(client) == 2) {
		float damage = event.GetFloat("damage");
		g_players[client].user.common.damage_taken_fall += damage;
	}
}
//Track heals, or defibs
void Event_ItemUsed(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		if(StrEqual(name, "heal_success", true)) {
			int subject = GetClientOfUserId(event.GetInt("subject"));
			if(subject == client) {
				g_players[client].user.common.used_kit_self++;
			} else {
				g_players[client].user.common.used_kit_other++;
				g_players[client].RecordPoint(PType_HealOther);
			}
		} else if(StrEqual(name, "revive_success", true)) {
			int subject = GetClientOfUserId(event.GetInt("subject"));
			if(subject != client) {
				g_players[client].user.common.times_revived_other++;
				g_players[client].RecordPoint(PType_ReviveOther);
			}
		} else if(StrEqual(name, "defibrillator_used", true)) {
			g_players[client].RecordPoint(PType_ResurrectOther);
			g_players[client].user.common.used_defib++;
		} else if(StrEqual(name, "adrenaline_used", true)) {
			g_players[client].user.common.used_adrenaline++;
		} else if(StrEqual(name, "pills_used")) {
			g_players[client].user.common.used_pills++;
		}
	}
}

void Event_UpgradePackUsed(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		int type = event.GetInt("upgradeid");
		g_players[client].RecordPoint(PType_DeployAmmo);
		if(type & 1) {
			g_players[client].user.user.used_ammopack_fire++;
		} else if(type & 2) {
			g_players[client].user.user.used_ammopack_explosive++;
		}
	}
}
void Event_CarAlarm(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		g_players[client].user.common.caralarms_activated++;
	}
}
void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		g_players[client].RecordPoint(PType_WitchKill);
		g_players[client].user.common.kills_witch++;
	}
}
public void L4D_OnSwingStart(int client, int weapon) {
	g_players[client].user.common.times_shove++;
}
///THROWABLE TRACKING
//This is used to track throwable throws 
public void OnEntityCreated(int entity, const char[] classname) {
	if(IsValidEntity(entity) && StrContains(classname, "_projectile", true) > -1) {
		RequestFrame(EntityCreateCallback, entity);
	}
}
void EntityCreateCallback(int entity) {
	if(!IsValidEntity(entity) || !HasEntProp(entity, Prop_Send, "m_hOwnerEntity") || !IsValidEntity(entity)) return;
	char class[32];

	GetEntityClassname(entity, class, sizeof(class));
	int entOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(entOwner > 0 && entOwner <= MaxClients) {
		if(StrEqual(class, "vomitjar_projectile", true)) {
			g_players[entOwner].user.common.used_bile++;
		} else if(StrEqual(class, "molotov_projectile", true)) {
			g_players[entOwner].user.common.used_molotov++;
		} else if(StrEqual(class, "pipe_bomb_projectile", true)) {
			g_players[entOwner].user.common.used_pipebomb++;
		}
	}
}
public void L4D2_CInsectSwarm_CanHarm_Post(int acid, int spitter, int entity) {
	if(entity <= 32 && GetClientTeam(entity) == 2) {
		g_players[entity].timeInAcid.TryStart();
	}
	// TODO: accumulate
}
public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) {
	if(GetEntityFlags(client) & FL_ONFIRE) {
		g_players[client].timeInFire.TryStart();
	} else {
		g_players[client].timeInFire.TryEnd();
	}
}

////////////////////////////
// FORWARD EVENTS
///////////////////////////
public void OnWitchCrown(int survivor, int damage) {
	g_players[survivor].user.common.witches_crowned++;
}
public void OnSmokerSelfClear( int survivor, int smoker, bool withShove ) {
	g_players[survivor].user.common.smokers_selfcleared++;
}
public void OnTankRockEaten( int tank, int survivor ) {
	g_players[survivor].user.common.rocks_hitby++;
}
public void OnHunterDeadstop(int survivor, int hunter) {
	g_players[survivor].user.common.hunters_deadstopped++;
}
public void OnSpecialClear( int clearer, int pinner, int pinvictim, int zombieClass, float timeA, float timeB, bool withShove ) {
	g_players[clearer].user.common.times_cleared_pinned++;
	g_players[pinvictim].user.common.times_pinned++;
}

/////////////////////////////////
// FINALE EVENTS
/////////////////////////////////

/*Order of events:
finale_start: create stats_game entry, get id
escape_vehicle_ready: IF fired, sets game.finished = true
finale_win: Record all stats (game + user)
*/
void Event_FinaleStart(Event event, const char[] name, bool dontBroadcast) {
	game.finaleStartTime = GetTime();
	game.difficulty = GetDifficultyInt();
	LogDebug("finale start, creating game");
	CreateGame();
	SubmitMapInfo();
}
void Event_FinaleVehicleReady(Event event, const char[] name, bool dontBroadcast) {
	//Get UUID on finale_start
	if(L4D_IsMissionFinalMap()) {
		game.difficulty = GetDifficultyInt();
		game.finished = true;
		if(!game.id) {
			LogWarn("game id missing. finale vehicle ready. shouldn't happen, creating game");
			CreateGame();
		}
	}
}

void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast) {
	if(!L4D_IsMissionFinalMap() || game.submitted) return;

	game.difficulty = event.GetInt("difficulty");
	UpdateGame(); // update date_end

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && GetClientTeam(i) == 2) {
			int client = i;

			//get real client if player is idle
			if(IsFakeClient(i)) {
				if(!HasEntProp(i, Prop_Send, "m_humanSpectatorUserID")) continue;
				client = GetClientOfUserId(GetEntPropEnt(i, Prop_Send, "m_humanSpectatorUserID"));
				if(client == 0) continue;
			}

			if(g_players[client].user.steamid[0]) {
				g_players[client].RecordPoint(PType_FinishCampaign);
				g_players[i].user.user.finales_won++;
				// Store it as we will iterate _all_ stored players for recording
				g_players[i].SaveSession();
				if(game.id > 0)
					PrintToChat(client, "View this game's statistics at %s%d", websiteUrlPrefix, game.id);
				if(game.clownHonks > 0) {
					PrintToChat(client, "%d clowns were honked this session, you honked %d", game.clownHonks, g_players[client].session.common.honks);
				}
			}

		}
	}	

	if(game.clownHonks > 0) {
		ArrayList winners = new ArrayList();
		int mostHonks;
		for(int j = 1; j <= MaxClients; j++) {
			if(g_players[j].session.common.honks <= 0 || !IsClientInGame(j) || IsFakeClient(j)) continue;
			if(g_players[j].session.common.honks > mostHonks || winners.Length == 0) {
				mostHonks = g_players[j].session.common.honks;
				// Clear the winners list
				winners.Clear();
				winners.Push(j);
			} else if(g_players[j].session.common.honks == mostHonks) {
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
	
	LogDebug("finale win. update game & record sessions");
	// Send ALL player data
	RecordSessionStats(); // records _all_ sessions, even if they left

	// want to send this at the end
	for(int i = 1; i <= MaxClients; i++) {
		g_players[i].session.common.honks = 0;
		if(IsClientInGame(i) && !IsFakeClient(i)) {
			PrintToChat(i, "Rate this map with /rate # (1 lowest, 5 highest)");
		}
	}
	game.submitted = true;
	game.clownHonks = 0;
}