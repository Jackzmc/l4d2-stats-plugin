#pragma semicolon 1
#pragma newdecls required

// #define DEBUG 1
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <geoip>
#include <sdkhooks>
#include <left4dhooks>
#include <SteamWorks>

#undef REQUIRE_PLUGIN
#include <l4d2_skill_detect>
//#include <sdkhooks>

public Plugin myinfo = 
{
	name =  "L4D2 Stats Recorder", 
	author = "jackzmc", 
	description = "", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/Jackzmc/sourcemod-plugins"
};
static ConVar hServerTags, hZDifficulty, hClownMode, hPopulationClowns, hMinShove, hMaxShove, hClownModeChangeChance;
static Handle hHonkCounterTimer;
static Database g_db;
static char gamemode[32], serverTags[255], uuid[64];
static bool lateLoaded; //Has finale started?

int g_iLastBoomUser;
float g_iLastBoomTime;

enum struct Game {
	int difficulty;
	int startTime;
	int finaleStartTime;
	int clownHonks;
	bool isVersusSwitched;
	bool finished;
	char gamemode[32];
	char uuid[64];
	char name[64];
	bool isCustomMap;

	bool IsVersusMode() {
		return StrEqual(this.gamemode, "versus") || StrEqual(this.gamemode, "scavenge");
	}

	void GetMap() {
		GetCurrentMap(this.name, sizeof(this.name));
		this.isCustomMap = this.name[0] != 'c' || !IsCharNumeric(this.name[1]) || this.name[2] != 'm';
	}
}

#define NUMBER_OF_WEAPONS 36
StringMap WeaponIds;
StringMapSnapshot WeaponIdsSnapshot;

enum struct WeaponStatistics {
	float minutesUsed;
	int totalDamage;
	int headshots;
	int kills;

	void Reset() {
		this.totalDamage = 0;
		this.minutesUsed = 0.0;
		this.kills = 0;
		this.headshots = 0;
	}

	bool HasChanged() {
		return this.totalDamage > 0.0 || this.minutesUsed > 0.0 || this.kills > 0.0;
	}
}

WeaponStatistics WeaponStats[MAXPLAYERS+1][NUMBER_OF_WEAPONS]; // Index -> WeaponIds[index] for name

enum PointRecordType {
	PType_Generic = 0,
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
	PType_DeployAmmo
}

enum struct Player {
	char steamid[32];
	int damageSurvivorGiven;
	int damageInfectedRec;
	int damageInfectedGiven;
	int damageSurvivorFF;
	int damageSurvivorFFCount;
	int damageFFTaken;
	int damageFFTakenCount;
	int doorOpens;
	int witchKills;
	int startedPlaying;
	int points;
	int upgradePacksDeployed;
	int finaleTimeStart;
	int molotovDamage;
	int pipeKills;
	int molotovKills;
	int minigunKills;
	int clownsHonked;

	//Used for table: stats_games;
	int m_checkpointZombieKills;
	int m_checkpointSurvivorDamage;
	int m_checkpointMedkitsUsed;
	int m_checkpointPillsUsed;
	int m_checkpointMolotovsUsed;
	int m_checkpointPipebombsUsed;
	int m_checkpointBoomerBilesUsed;
	int m_checkpointAdrenalinesUsed;
	int m_checkpointDefibrillatorsUsed;
	int m_checkpointDamageTaken;
	int m_checkpointReviveOtherCount;
	int m_checkpointFirstAidShared;
	int m_checkpointIncaps;
	int m_checkpointAccuracy;
	int m_checkpointDeaths;
	int m_checkpointMeleeKills;
	int sBoomerKills;
	int sSmokerKills;
	int sJockeyKills;
	int sHunterKills;
	int sSpitterKills;
	int sChargerKills;

	//TODO: Hook player_reload

	StringMap weaponStats;
	float lastWeaponPickupTime;
	char lastWeaponName[64];
	int lastWeaponDamage;

	ArrayList pointsQueue;

	void Init() {
		this.weaponStats = new StringMap();
		this.pointsQueue = new ArrayList(3); // [ type, amount, time ]
	}

	void ResetFull() {
		this.lastWeaponPickupTime = float(GetTime());
		this.lastWeaponName[0] = '\0';
		this.lastWeaponDamage = 0;
		this.steamid[0] = '\0';
		this.points = 0;
		if(this.weaponStats != null)
			this.weaponStats.Clear();
		if(this.pointsQueue != null)
			this.pointsQueue.Clear();
		// this.mostUsedWeapon.usage = 0;
		// this.mostUsedWeapon.damage = 0.0;
		// this.mostUsedWeapon.name[0] = '\0';
		// this.activeWeapon = this.mostUsedWeapon;
	}

	void RecordPoint(PointRecordType type, int amount = 1) {
		this.points += amount;
		// Common kills are too spammy 
		if(type != PType_CommonKill) {
			int index = this.pointsQueue.Push(type);
			this.pointsQueue.Set(index, amount, 1);
			this.pointsQueue.Set(index, GetTime(), 2);
		}
	}
	//add:  	m_checkpointDamageToTank
	//add:  	m_checkpointDamageToWitch
}
static Player players[MAXPLAYERS+1];
static Game game;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("Stats_GetPoints", Native_GetPoints);
	if(late) lateLoaded = true;
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
	if(!SQL_CheckConfig("stats")) {
		SetFailState("No database entry for 'stats'; no database to connect to.");
	}
	if(!ConnectDB()) {
		SetFailState("Failed to connect to database.");
	}

	LoadWeaponDatabase();

	if(lateLoaded) {
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
	hPopulationClowns = FindConVar("l4d2_population_clowns");

	hClownMode.AddChangeHook(CVC_ClownModeChanged);

	hServerTags = CreateConVar("l4d2_statsrecorder_tags", "", "A comma-seperated list of tags that will be used to identity this server.");
	hServerTags.GetString(serverTags, sizeof(serverTags));
	hServerTags.AddChangeHook(CVC_TagsChanged);

	ConVar hGamemode = FindConVar("mp_gamemode");
	hGamemode.GetString(gamemode, sizeof(gamemode));
	hGamemode.AddChangeHook(CVC_GamemodeChange);

	hZDifficulty = FindConVar("z_difficulty");

	//Hook all events to track statistics
	HookEvent("player_disconnect", Event_PlayerFullDisconnect);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	// HookEvent("weapon_reload", Event_WeaponReload);
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
	//Used for campaign recording:
	HookEvent("finale_start", Event_FinaleStart);
	HookEvent("gauntlet_finale_start", Event_FinaleStart);
	HookEvent("finale_vehicle_ready", Event_FinaleVehicleReady);
	HookEvent("finale_win", Event_FinaleWin);
	HookEvent("hegrenade_detonate", Event_GrenadeDenonate);
	//Used to transition checkpoint statistics for stats_games
	HookEvent("game_init", Event_GameStart);
	HookEvent("round_end", Event_RoundEnd);

	HookEvent("boomer_exploded", Event_BoomerExploded);
	HookEvent("versus_round_start", Event_VersusRoundStart);
	HookEvent("map_transition", Event_MapTransition);
	AddNormalSoundHook(SoundHook);
	#if defined DEBUG
	RegConsoleCmd("sm_debug_stats", Command_DebugStats, "Debug stats");
	#endif

	AutoExecConfig(true, "l4d2_stats_recorder");

	for(int i = 1; i <= MaxClients; i++) {
		players[i].Init();
	}
}

void LoadWeaponDatabase() {
	WeaponIds = new StringMap();
	int i = 0;
	WeaponIds.SetValue("weapon_pistol", i++);
	WeaponIds.SetValue("weapon_smg", i++);
	WeaponIds.SetValue("weapon_pistol", i++);
	WeaponIds.SetValue("weapon_smg", i++);
	WeaponIds.SetValue("weapon_pumpshotgun", i++);
	WeaponIds.SetValue("weapon_autoshotgun", i++);
	WeaponIds.SetValue("weapon_rifle", i++);
	WeaponIds.SetValue("weapon_hunting_rifle", i++);
	WeaponIds.SetValue("weapon_smg_silenced", i++);
	WeaponIds.SetValue("weapon_shotgun_chrome", i++);
	WeaponIds.SetValue("weapon_rifle_desert", i++);
	WeaponIds.SetValue("weapon_sniper_military", i++);
	WeaponIds.SetValue("weapon_shotgun_spas", i++);
	WeaponIds.SetValue("weapon_chainsaw", i++);
	WeaponIds.SetValue("weapon_grenade_launcher", i++);
	WeaponIds.SetValue("weapon_rifle_ak47", i++);
	WeaponIds.SetValue("weapon_pistol_magnum", i++);
	WeaponIds.SetValue("weapon_smg_mp5", i++);
	WeaponIds.SetValue("weapon_rifle_sg552", i++);
	WeaponIds.SetValue("weapon_sniper_awp",	 i++);
	WeaponIds.SetValue("weapon_sniper_scout", i++);
	WeaponIds.SetValue("weapon_rifle_m60", i++);

	WeaponIds.SetValue("knife", i++);
	WeaponIds.SetValue("baseball_bat", i++);
	WeaponIds.SetValue("chainsaw", i++);
	WeaponIds.SetValue("cricket_bat", i++);
	WeaponIds.SetValue("crowbar", i++);
	WeaponIds.SetValue("didgeridoo", i++);
	WeaponIds.SetValue("electric_guitar", i++);
	WeaponIds.SetValue("fireaxe", i++);
	WeaponIds.SetValue("frying_pan", i++);
	WeaponIds.SetValue("golfclub", i++);
	WeaponIds.SetValue("katana", i++);
	WeaponIds.SetValue("machete", i++);
	WeaponIds.SetValue("riotshield", i++);
	WeaponIds.SetValue("tonfa", i++);

	WeaponIdsSnapshot = WeaponIds.Snapshot();

	if(i != NUMBER_OF_WEAPONS) {
		PrintToServer("[l4d2_stats_recorder] Warning: NUMBER_OF_WEAPONS define does not equal WeaponIds length!!!");
	}
}

//When plugin is being unloaded: flush all user's statistics.
public void OnPluginEnd() {
	for(int i=1; i<=MaxClients;i++) {
		if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && players[i].steamid[0]) {
			FlushQueuedStats(i, false);
		}
	}
}
//////////////////////////////////
// TIMER
/////////////////////////////////
public Action Timer_FlushStats(Handle timer) {
	//Periodically flush the statistics
	if(GetClientCount(true) > 0) {
		for(int i=1; i<=MaxClients;i++) {
			if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && players[i].steamid[0]) {
				FlushQueuedStats(i, false);
			}
		}
	}
	return Plugin_Continue;
}
/////////////////////////////////
// CONVAR CHANGES
/////////////////////////////////
public void CVC_GamemodeChange(ConVar convar, const char[] oldValue, const char[] newValue) {
	strcopy(game.gamemode, sizeof(game.gamemode), newValue);
	strcopy(gamemode, sizeof(gamemode), newValue);
}
public void CVC_TagsChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	strcopy(serverTags, sizeof(serverTags), newValue);
}
public void CVC_ClownModeChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if(hClownMode.IntValue > 0) {
		hMinShove.IntValue = 20;
		hMaxShove.IntValue = 40;
		hPopulationClowns.FloatValue = 0.4;
		hHonkCounterTimer = CreateTimer(30.0, Timer_HonkCounter, _, TIMER_REPEAT);
	} else {
		hMinShove.IntValue = 5;
		hMaxShove.IntValue = 15;
		hPopulationClowns.FloatValue = 0.0;
		if(hHonkCounterTimer != null) {
			delete hHonkCounterTimer;
		}
	}
}
public Action Timer_HonkCounter(Handle h) { 
	int honks, honker = -1;
	for(int j = 1; j <= MaxClients; j++) {
		if(players[j].clownsHonked > 0 && (players[j].clownsHonked > honks || honker == -1) && !IsFakeClient(j)) {
			honker = j;
			honks = players[j].clownsHonked;
		}
	}
	if(honker > 0) {
		for(int i = 1; i <= MaxClients; i++) {
			if(players[i].clownsHonked > 0 && IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2) {
				PrintHintText(i, "Top Honker: %N (%d honks)\nYou: %d honks", honker, honks, players[i].clownsHonked);
			}
		}
	}
	if(hClownMode.IntValue == 2 && GetURandomFloat() < hClownModeChangeChance.FloatValue) {
		if(GetRandomFloat() > 0.6)
			hPopulationClowns.FloatValue = 0.0;
		else 
			hPopulationClowns.FloatValue = GetRandomFloat();
		PrintToConsoleAll("Honk Mode: New population %.0f%%", hPopulationClowns.FloatValue * 100);
	}
	return Plugin_Continue; 
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
		if(game.finished && uuid[0] && players[client].steamid[0]) {
			IncrementSessionStat(client);
			RecordCampaign(client);
			IncrementStat(client, "finales_won", 1);
			players[client].RecordPoint(PType_FinishCampaign, 200);
		}

		FlushQueuedStats(client, true);
		players[client].ResetFull();

		//ResetSessionStats(client); //Can't reset session stats cause transitions!
	}
}

void Event_PlayerFullDisconnect(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0) {
		players[client].ResetFull();
	}
}

///////////////////////////////////
//DB METHODS
//////////////////////////////////

bool ConnectDB() {
	char error[255];
	g_db = SQL_Connect("stats", true, error, sizeof(error));
	if (g_db == null) {
		LogError("Database error %s", error);
		delete g_db;
		return false;
	} else {
		PrintToServer("Connected to database stats");
		SQL_LockDatabase(g_db);
		SQL_FastQuery(g_db, "SET NAMES \"UTF8mb4\"");  
		SQL_UnlockDatabase(g_db);
		g_db.SetCharset("utf8mb4");
		return true;
	}
}
//Setups a user, this tries to fetch user by steamid
void SetupUserInDB(int client, const char steamid[32]) {
	if(client > 0 && !IsFakeClient(client)) {
		players[client].ResetFull();

		strcopy(players[client].steamid, 32, steamid);
		players[client].startedPlaying = GetTime();
		char query[128];
		

		Format(query, sizeof(query), "SELECT last_alias,points FROM stats_users WHERE steamid='%s'", steamid);
		SQL_TQuery(g_db, DBCT_CheckUserExistance, query, GetClientUserId(client));
	}
}
//Increments a statistic by X amount
void IncrementStat(int client, const char[] name, int amount = 1, bool lowPriority = false) {
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
			SQL_TQuery(g_db, DBCT_Generic, query, _, lowPriority ? DBPrio_Low : DBPrio_Normal);
		}
	}
}

void RecordCampaign(int client) {
	if (client > 0 && IsClientConnected(client) && IsClientInGame(client)) {
		char query[1023];

		if(players[client].m_checkpointZombieKills == 0) {
			PrintToServer("Warn: Client %N for %s | 0 zombie kills", client, uuid);
		}

		char model[64];
		GetClientModel(client, model, sizeof(model));

		char topWeapon[64];
		ComputeTopWeapon(client, topWeapon, sizeof(topWeapon));


		int finaleTimeTotal = (game.finaleStartTime > 0) ? GetTime() - game.finaleStartTime : 0;
		Format(query, sizeof(query), "INSERT INTO stats_games (`steamid`, `map`, `gamemode`,`campaignID`, `finale_time`, `date_start`,`date_end`, `zombieKills`, `survivorDamage`, `MedkitsUsed`, `PillsUsed`, `MolotovsUsed`, `PipebombsUsed`, `BoomerBilesUsed`, `AdrenalinesUsed`, `DefibrillatorsUsed`, `DamageTaken`, `ReviveOtherCount`, `FirstAidShared`, `Incaps`, `Deaths`, `MeleeKills`, `difficulty`, `ping`,`boomer_kills`,`smoker_kills`,`jockey_kills`,`hunter_kills`,`spitter_kills`,`charger_kills`,`server_tags`,`characterType`,`honks`,`top_weapon`, `SurvivorFFCount`, `SurvivorFFTakenCount`, `SurvivorFFDamage`, `SurvivorFFTakenDamage`) VALUES ('%s','%s','%s','%s',%d,%d,UNIX_TIMESTAMP(),%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,'%s',%d,%d,'%s',%d,%d,%d,%d)",
			players[client].steamid,
			game.name,
			gamemode,
			uuid,
			finaleTimeTotal,
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
			GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iPing", _, client), //record user ping
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
			LogError("[l4d2_stats_recorder] RecordCampaign for %d failed. UUID %s | Query: `%s` | Error: %s", uuid, client, query, error);
		}
		#if defined DEBUG
			PrintToServer("[l4d2_stats_recorder] DEBUG: Added finale (%s) to stats_maps for %s ", mapname, players[client].steamid);
		#endif
	}
}

int GetWeaponStatIndex(int client, char[] name, int maxlen) {
	int activeWeaponEnt = GetPlayerWeaponSlot(client, 0);
	if(activeWeaponEnt > 0) {
		GetEntityClassname(activeWeaponEnt, name, maxlen);

		if(StrEqual(name, "weapon_melee")) {
			GetEntPropString(activeWeaponEnt, Prop_Data, "m_strMapSetScriptName", name, maxlen);
		}

		int i = 0;
		if(WeaponIds.GetValue(name, i)) {
			return i;
		}
		return -1;
	}
	return -2;
}
int GetWeaponStatIndexByName(const char[] name) {
	int i = 0;
	if(WeaponIds.GetValue(name, i)) {
		return i;
	}
	return -1;
}

/// FIXME: Updating wrong stats!!!
void UpdateWeaponStats(int client, bool force = false) {
	char name[64];
	// Get the current weapon index
	int weaponIndex = GetWeaponStatIndex(client, name, sizeof(name));
	if(weaponIndex >= 0) {
		if(force || !StrEqual(players[client].lastWeaponName, name)) {
			int lastWeaponIndex = GetWeaponStatIndexByName(players[client].lastWeaponName);
			float time = float(GetTime());
			if(lastWeaponIndex >= 0) {
				WeaponStats[client][weaponIndex].minutesUsed += (time - players[client].lastWeaponPickupTime) / 60.0;
				WeaponStats[client][weaponIndex].totalDamage += players[client].lastWeaponDamage;
			}
 			// PrintToServer("%N: updating stats for %s -> %s", client, players[client].lastWeaponName, name);

			// WeaponStats[client][weaponIndex].minutesUsed += (time - players[client].lastWeaponPickupTime) / 60.0;
			// WeaponStats[client][weaponIndex].totalDamage += players[client].lastWeaponDamage;

			// WeaponStatistics stats;
			// players[client].weaponStats.GetArray(name, stats, sizeof(stats));
			// stats.minutesUsed += (time - players[client].lastWeaponPickupTime) / 60.0;
			// stats.totalDamage += players[client].lastWeaponDamage;
			// #if defined DEBUG
			// PrintServer("%N: Updating %s [minutes: %f] [dmg: %f]", client, name, stats.minutesUsed, stats.totalDamage);			
			// #endif
			// players[client].weaponStats.SetArray(name, stats, sizeof(stats));

			strcopy(players[client].lastWeaponName, 64, name);
			players[client].lastWeaponDamage = 0;
			players[client].lastWeaponPickupTime = time;
		}
	}
}
// Computes the top weapon of player. < 0 if none
int ComputeTopWeapon(int client, char[] output, int maxlen) {
	// if(players[client].weaponStats == null) return -2;
	// StringMapSnapshot snapshot = players[client].weaponStats.Snapshot();
	int index = -1;
	float highestMinutes;
	// float minutes;
	// char buffer[64];
	// Loop all stored weapon stats and find largest:
	for(int i = 0; i < WeaponIdsSnapshot.Length; i++) {
		if(WeaponStats[client][i].minutesUsed > highestMinutes) {
			highestMinutes = WeaponStats[client][i].minutesUsed;
			index = i;
		}

		// snapshot.GetKey(i, buffer, sizeof(buffer));
		// players[client].weaponStats.GetValue(buffer, minutes);
		// PrintToServer("%N: %f | highest %f", client, minutes, highestMinutes);
		// if(minutes > highestMinutes || index == -1) {
		// 	index = i;
		// 	highestMinutes = minutes;
		// }
	}

	int out = -1;
	if(index >= 0) {
		WeaponIdsSnapshot.GetKey(index, output, maxlen);
		PrintToServer("[l4d2_stats_recorder] Debug: Top Weapon for %N is: %s", client, output);
		out = RoundFloat(highestMinutes);
	}
	return out;
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
		Format(query, sizeof(query), "UPDATE stats_users SET survivor_damage_give=survivor_damage_give+%d,survivor_damage_rec=survivor_damage_rec+%d, infected_damage_give=infected_damage_give+%d,infected_damage_rec=infected_damage_rec+%d,survivor_ff=survivor_ff+%d,survivor_ff_rec=survivor_ff_rec+%d,common_kills=common_kills+%d,common_headshots=common_headshots+%d,melee_kills=melee_kills+%d,door_opens=door_opens+%d,damage_to_tank=damage_to_tank+%d, damage_witch=damage_witch+%d,minutes_played=minutes_played+%d, kills_witch=kills_witch+%d, points=%d, packs_used=packs_used+%d, damage_molotov=damage_molotov+%d, kills_molotov=kills_molotov+%d, kills_pipe=kills_pipe+%d, kills_minigun=kills_minigun+%d, clowns_honked=clowns_honked+%d WHERE steamid='%s'",
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
		}
	}
}

void SubmitPoints(int client) {
	if(players[client].pointsQueue.Length > 0) {
		char query[4098];
		Format(query, sizeof(query), "INSERT INTO stats_points (steamid,type,amount,timestamp) VALUES ");
		for(int i = 0; i < players[client].pointsQueue.Length; i++) {
			int type = players[client].pointsQueue.Get(i, 0);
			int amount = players[client].pointsQueue.Get(i, 1);
			int timestamp = players[client].pointsQueue.Get(i, 2);
			Format(query, sizeof(query), "%s('%s',%d,%d,%d)%c",
				query,
				players[client].steamid,
				type,
				amount,
				timestamp,
				i == players[client].pointsQueue.Length - 1 ? ' ' : ',' // No trailing comma on last entry
			);
		}
		SQL_TQuery(g_db, DBCT_Generic, query, _, DBPrio_Low);
		players[client].pointsQueue.Clear();
	}
}

void SubmitWeaponStats(int client) {
	if(players[client].weaponStats != null && players[client].weaponStats.Size > 0) {
		// Force save weapon stats, instead of waiting for player to switch weapon
		UpdateWeaponStats(client, true);
		char query[512], weapon[64];
		
		for(int i = 0; i < WeaponIdsSnapshot.Length; i++) {
			if(WeaponStats[client][i].HasChanged()) {
				WeaponIdsSnapshot.GetKey(i, weapon, sizeof(weapon));
				Format(query, sizeof(query), "INSERT INTO stats_weapons_usage (steamid,weapon,minutesUsed,totalDamage,kills,headshots) VALUES ('%s','%s',%f,%d,%d,%d) ON DUPLICATE KEY UPDATE minutesUsed=minutesUsed+%f,totalDamage=totalDamage+%d,kills=kills+%d,headshots=headshots+%d",
					players[client].steamid,
					weapon,
					WeaponStats[client][i].minutesUsed,
					WeaponStats[client][i].totalDamage,
					WeaponStats[client][i].kills,
					WeaponStats[client][i].headshots,

					WeaponStats[client][i].minutesUsed,
					WeaponStats[client][i].totalDamage,
					WeaponStats[client][i].kills,
					WeaponStats[client][i].headshots
				);
				SQL_TQuery(g_db, DBCT_Generic, query, _, DBPrio_Low);
			}
		}
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
	if(players[client].weaponStats != null)
		players[client].weaponStats.Clear();
	for(int i = 0; i < WeaponIds.Size; i++) {
		WeaponStats[client][i].Reset();
	}
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
public void DBCT_CheckUserExistance(Handle db, Handle queryHandle, const char[] error, any data) {
	if(db == INVALID_HANDLE || queryHandle == INVALID_HANDLE) {
		LogError("DBCT_CheckUserExistance returned error: %s", error);
		return;
	}
	//initialize variables
	int client = GetClientOfUserId(data); 
	if(client == 0) return;
	int alias_length = 2*MAX_NAME_LENGTH+1;
	char alias[MAX_NAME_LENGTH], ip[40], country_name[45];
	char previous_alias[MAX_NAME_LENGTH];
	char[] safe_alias = new char[alias_length];

	//Get a SQL-safe player name, and their counttry and IP
	GetClientName(client, alias, sizeof(alias));
	SQL_EscapeString(g_db, alias, safe_alias, alias_length);
	GetClientIP(client, ip, sizeof(ip));
	GeoipCountry(ip, country_name, sizeof(country_name));

	char query[255]; 
	if(SQL_GetRowCount(queryHandle) == 0) {
		//user does not exist in db, create now

		Format(query, sizeof(query), "INSERT INTO `stats_users` (`steamid`, `last_alias`, `last_join_date`,`created_date`,`country`) VALUES ('%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), '%s')", players[client].steamid, safe_alias, country_name);
		SQL_TQuery(g_db, DBCT_Generic, query);
		AddUserName(players[client].steamid, safe_alias);

		Format(query, sizeof(query), "%N is joining for the first time", client);
		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientConnected(i) && IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID) {
				PrintToChat(i, query);
			}
		}
		PrintToServer("[l4d2_stats_recorder] Created new database entry for %N (%s)", client, players[client].steamid);
	} else {
		//User does exist, check if alias is outdated and update some columns (last_join_date, country, connections, or last_alias)
		while(SQL_FetchRow(queryHandle)) {
			int field_num;
			if(SQL_FieldNameToNum(queryHandle, "points", field_num)) {
				players[client].points = SQL_FetchInt(queryHandle, field_num);
			}
			// Check if their name has changed and add the new one to user_names table:
			if(SQL_FieldNameToNum(queryHandle, "last_alias", field_num)) {
				SQL_FetchString(queryHandle, field_num, previous_alias, sizeof(previous_alias));
				if(!StrEqual(previous_alias, alias)) {
					AddUserName(players[client].steamid, safe_alias);
				}
			}
		}

		int connections_amount = lateLoaded ? 0 : 1;

		Format(query, sizeof(query), "UPDATE `stats_users` SET `last_alias`='%s', `last_join_date`=UNIX_TIMESTAMP(), `country`='%s', connections=connections+%d WHERE `steamid`='%s'", safe_alias, country_name, connections_amount, players[client].steamid);
		SQL_TQuery(g_db, DBCT_Generic, query);
	}
}

void AddUserName(const char[] steamid, const char[] name) {
	char query[128];
	PrintToServer("AddUserName: %s", players[client].steamid[10]);
	Format(query, sizeof(query), "INSERT INTO `user_names` (steamid, timestamp, name) VALUES ('%s', UNIX_TIMESTAMP(), '%s')", players[client].steamid[10], previous_alias);
	g_db.Query(DBCT_Generic, query);
}

//Generic database response that logs error
public void DBCT_Generic(Handle db, Handle child, const char[] error, any data) {
    if(db == null || child == null) {
		if(data) {
			LogError("DBCT_Generic query `%s` returned error: %s", data, error);
		}else {
			LogError("DBCT_Generic returned error: %s", error);
		}
	}
}
public void DBCT_GetUUIDForCampaign(Handle db, Handle results, const char[] error, any data) {
	if(results != INVALID_HANDLE && SQL_GetRowCount(results) > 0) {
		SQL_FetchRow(results);
		SQL_FetchString(results, 0, uuid, sizeof(uuid));
		PrintToServer("UUID for campaign: %s | Difficulty: %d", uuid, game.difficulty);
	}else{
		LogError("RecordCampaign, failed to get UUID: %s", error);
	}
}
//After a user's stats were flushed, reset any statistics needed to zero.
public void DBCT_FlushQueuedStats(Handle db, Handle child, const char[] error, int userid) {
	if(db == INVALID_HANDLE || child == INVALID_HANDLE) {
		LogError("DBCT_FlushQueuedStats returned error: %s", error);
	}else{
		int client = GetClientOfUserId(userid);
		if(client > 0)
			ResetInternal(client, false);
	}
}
////////////////////////////
// COMMANDS
///////////////////////////
#if defined DEBUG
public Action Command_DebugStats(int client, int args) {
	if(client == 0 && !IsDedicatedServer()) {
		ReplyToCommand(client, "This command must be used as a player.");
	}else {
		ReplyToCommand(client, "Statistics for %s", players[client].steamid);
		ReplyToCommand(client, "lastDamage = %f", players[client].lastWeaponDamage);
		ReplyToCommand(client, "points = %d", players[client].points);
		// ReplyToCommand(client, "Total weapons cache %d", game.weaponUsages.Size);
	}
	return Plugin_Handled;
}
#endif

////////////////////////////
// EVENTS 
////////////////////////////
void OnWeaponSwitch(int client, int weapon) {
	// Update weapon when switching to a new one
	UpdateWeaponStats(client);
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

public Action SoundHook(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed) {
	if(numClients > 0 && StrContains(sample, "clown") > -1) {
		float zPos[3], survivorPos[3];
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
public void Event_WeaponReload(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		// static char name[64];
		// GetEntityClassname(activeWeaponEnt, name, sizeof(name));
		// UpdateWeaponStats(client, name[7]);
	}
}
//Records the amount of HP done to infected (zombies)
public void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker > 0 && !IsFakeClient(attacker)) {
		int dmg = event.GetInt("amount");
		players[attacker].damageSurvivorGiven += dmg;
		if(GetClientTeam(attacker) == 2)
			players[attacker].lastWeaponDamage += dmg;
		// static char buffer[64];

		// int i = GetWeaponStatIndex(attacker, buffer, sizeof(buffer));
		// PrintToChat(attacker, "%d %s %f", i, buffer, dmg);
		// if(i >= 0) {
		// 	WeaponStats[attacker][i].totalDamage += dmg;
		// }
	}
}
public void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker > 0 && !IsFakeClient(attacker)) {
		bool blast = event.GetBool("blast");
		bool headshot = event.GetBool("headshot");
		bool using_minigun = event.GetBool("minigun");
		static char wpn_name[64];

		int i = GetWeaponStatIndex(attacker, wpn_name, sizeof(wpn_name));
		if(headshot) {

			players[attacker].RecordPoint(PType_Headshot, 2);
			if(i >= 0) {

				WeaponStats[attacker][i].headshots++;
			}
		}

		players[attacker].RecordPoint(PType_CommonKill, 1);
		if(i >= 0) {
			WeaponStats[attacker][i].kills++;
		}

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
		static char wpn_name[64]; 
		// event.GetString("weapon", wpn_name, sizeof(wpn_name));

		if(attacker_team == 2) {
			players[attacker].damageSurvivorGiven += dmg;
			players[attacker].lastWeaponDamage += dmg;
			if(victim_team == 3 && StrEqual(wpn_name, "inferno", true)) {
				players[attacker].molotovDamage += dmg;
			}
		}else if(attacker_team == 3) {
			players[attacker].damageInfectedGiven += dmg;
		}
		if(attacker_team == 2 && victim_team == 2) {
			players[attacker].RecordPoint(PType_FriendlyFire, -30);
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
			}
		}

		if(attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2) {
			if(victim_team == 3) {
				int victim_class = GetEntProp(victim, Prop_Send, "m_zombieClass");
				char class[8], statname[16], wpn_name[64]; 
				int i = GetWeaponStatIndex(attacker, wpn_name, sizeof(wpn_name));
				if(i >= 0) {
					WeaponStats[attacker][i].kills++;
				}

				if(GetInfectedClassName(victim_class, class, sizeof(class))) {
					IncrementSpecialKill(attacker, victim_class);
					Format(statname, sizeof(statname), "kills_%s", class);
					IncrementStat(attacker, statname, 1);
					players[attacker].RecordPoint(PType_SpecialKill, 6);
				}
				if(StrEqual(wpn_name, "inferno", true) || StrEqual(wpn_name, "entityflame", true)) {
					players[attacker].molotovKills++;
				}
				IncrementStat(victim, "infected_deaths", 1);
			}else if(victim_team == 2) {
				IncrementStat(attacker, "ff_kills", 1);
				//30 point lost for killing teammate
				players[attacker].RecordPoint(PType_FriendlyFire, -500);
			}
		}
	}
	
}
public void Event_MeleeKill(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		players[client].RecordPoint(PType_CommonKill, 1);
	}
}
public void Event_TankKilled(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int solo = event.GetBool("solo") ? 1 : 0;
	int melee_only = event.GetBool("melee_only") ? 1 : 0;

	if(attacker > 0 && !IsFakeClient(attacker)) {
		if(solo) {
			IncrementStat(attacker, "tanks_killed_solo", 1);
			players[attacker].RecordPoint(PType_TankKill_Solo, 20);
		}
		if(melee_only) {
			players[attacker].RecordPoint(PType_TankKill_Melee, 50);
			IncrementStat(attacker, "tanks_killed_melee", 1);
		}
		players[attacker].RecordPoint(PType_TankKill, 100);
		IncrementStat(attacker, "tanks_killed", 1);
	}
}
public void Event_DoorOpened(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && event.GetBool("closed") && !IsFakeClient(client)) {
		players[client].doorOpens++;

	}
}
//Records anytime an item is picked up. Runs for any weapon, only a few have a SQL column. (Throwables)
public void Event_ItemPickup(Event event, const char[] name, bool dontBroadcast) {
	char statname[72], item[64];

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsFakeClient(client)) {
		event.GetString("item", item, sizeof(item));
		ReplaceString(item, sizeof(item), "weapon_", "", true);

		// Update stats when picking up an item
		UpdateWeaponStats(client);

		Format(statname, sizeof(statname), "pickups_%s", item);
		IncrementStat(client, statname, 1);
	}
}
public void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsFakeClient(client) && GetClientTeam(client) == 2) {
		IncrementStat(client, "survivor_incaps", 1);
	}
}
//Track heals, or defibs
public void Event_ItemUsed(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		if(StrEqual(name, "heal_success", true)) {
			int subject = GetClientOfUserId(event.GetInt("subject"));
			if(subject == client) {
				IncrementStat(client, "heal_self", 1);
			}else{
				players[client].RecordPoint(PType_HealOther, 10);
				IncrementStat(client, "heal_others", 1);
			}
		}else if(StrEqual(name, "revive_success", true)) {
			int subject = GetClientOfUserId(event.GetInt("subject"));
			if(subject != client) {
				IncrementStat(client, "revived_others", 1);
				players[client].RecordPoint(PType_ReviveOther, 5);
				IncrementStat(subject, "revived", 1);
			}
		}else if(StrEqual(name, "defibrillator_used", true)) {
			players[client].RecordPoint(PType_ResurrectOther, 7);
			IncrementStat(client, "defibs_used", 1);
		}else{
			IncrementStat(client, name, 1);
		}
	}
}

public void Event_UpgradePackUsed(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		players[client].upgradePacksDeployed++;
		players[client].RecordPoint(PType_DeployAmmo, 2);
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
		players[client].RecordPoint(PType_WitchKill, 50);
	}
}


public void Event_GrenadeDenonate(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !IsFakeClient(client)) {
		char wpn_name[32];
		GetClientWeapon(client, wpn_name, sizeof(wpn_name));
		//PrintToServer("wpn_Name %s", wpn_name);
		//Somehow have to check if molotov or gr
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
		}else if(StrContains(class, "molotov", true) > -1) {
			IncrementStat(entOwner, "throws_molotov", 1);
		}else if(StrContains(class, "pipe_bomb", true) > -1) {
			IncrementStat(entOwner, "throws_pipe", 1);
		}
	}
}
bool isTransition = false;
////MAP EVENTS
public void Event_GameStart(Event event, const char[] name, bool dontBroadcast) {
	game.startTime = GetTime();
	game.clownHonks = 0;
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
}
public void Event_VersusRoundStart(Event event, const char[] name, bool dontBroadcast) {
	if(game.IsVersusMode()) {
		game.isVersusSwitched = !game.isVersusSwitched; 
	}
}
public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast) {
	isTransition = true;
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsFakeClient(i)) {
			IncrementSessionStat(i);
			FlushQueuedStats(i, false);
		}
	}
}
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	PrintToServer("[l4d2_stats_recorder] round_end; flushing");
	game.finished = false;
	
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
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
public void Event_FinaleStart(Event event, const char[] name, bool dontBroadcast) {
	game.finaleStartTime = GetTime();
	game.difficulty = GetDifficultyInt();
	//Use the same UUID for versus
	//FIXME: This was causing UUID to not fire another new one for back-to-back-coop
	//if(game.IsVersusMode && game.isVersusSwitched) return;
	
	SQL_TQuery(g_db, DBCT_GetUUIDForCampaign, "SELECT UUID() AS UUID", _, DBPrio_High);
}
public void Event_FinaleVehicleReady(Event event, const char[] name, bool dontBroadcast) {
	//Get UUID on finale_start
	if(L4D_IsMissionFinalMap()) {
		game.difficulty = GetDifficultyInt();
		game.finished = true;
		game.GetMap();
	}
}

public void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast) {
	if(!L4D_IsMissionFinalMap()) return;
	game.difficulty = event.GetInt("difficulty");
	game.finished = false;
	char shortID[9];
	StrCat(shortID, sizeof(shortID), uuid);

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2) {
			int client = i;
			if(IsFakeClient(i)) {
				if(!HasEntProp(i, Prop_Send, "m_humanSpectatorUserID")) continue;
				client = GetClientOfUserId(GetEntPropEnt(i, Prop_Send, "m_humanSpectatorUserID"));
				//get real client
			}
			if(players[client].steamid[0]) {
				players[client].RecordPoint(PType_FinishCampaign, 200);
				IncrementSessionStat(client);
				RecordCampaign(client);
				IncrementStat(client, "finales_won", 1);
				PrintToChat(client, "View this game's statistics at https://jackz.me/c/%s", shortID);
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
			if(players[j].clownsHonked <= 0 || IsClientConnected(j) && IsClientInGame(j) && IsFakeClient(j)) continue;
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
					if(i == winners.Length - 1) {
						// If this is the last winner, use 'and '
						Format(msg, sizeof(msg), "%s and %N", msg, winners.Get(i));
					} else {
						// In between first and last winner, comma
						Format(msg, sizeof(msg), "%s, %N", msg, winners.Get(i));
					}
				}
				PrintToChatAll("%s tied for the most clown honks with a count of %d", msg, mostHonks);
			} else {
				PrintToChatAll("%N had the most clown honks with a count of %d", winners.Get(0), mostHonks);
			}
		} 
		delete winners;
	}
	for(int i = 1; i <= MaxClients; i++) {
		players[i].clownsHonked = 0;
	}
	game.clownHonks = 0;
}


////////////////////////////
// FORWARD EVENTS
///////////////////////////
public void OnWitchCrown(int survivor, int damage) {
	IncrementStat(survivor, "witches_crowned", 1);
}
public void OnWitchHurt(int survivor, int damage, int chip) {
	IncrementStat(survivor, "witches_crowned_angry", 1);
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
stock int GetSurvivorType(const char[] modelName) {
	if(StrContains(modelName,"biker",false) > -1) {
		return 6;
	}else if(StrContains(modelName,"teenangst",false) > -1) {
		return 5;
	}else if(StrContains(modelName,"namvet",false) > -1) {
		return 4;
	}else if(StrContains(modelName,"manager",false) > -1) {
		return 7;
	}else if(StrContains(modelName,"coach",false) > -1) {
		return 2;
	}else if(StrContains(modelName,"producer",false) > -1) {
		return 1;
	}else if(StrContains(modelName,"gambler",false) > -1) {
		return 0;
	}else if(StrContains(modelName,"mechanic",false) > -1) {
		return 3;
	}else{
		return -1;
	}
}