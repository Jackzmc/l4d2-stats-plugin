enum struct DistanceCalculator {
	float accumulation;
	int recordTime;
	float lastPos[3];

	// TODO: in future, avg speed?
}
enum struct TimeCalculator {
	float seconds;
	int lastTime;
	bool enabled;
	// Starts calculator and marks timestamp, if not already started
	void TryStart() {
		if(!this.enabled) {
			this.enabled = true;
			this.lastTime = GetTime();
		}
	}
	// Record number of seconds, if enabled
	bool TryEnd() {
		if(this.enabled) {
			this.seconds += (GetTime() - this.lastTime);
			this.enabled = false;
			return true;
		}
		return false;
	}
}


enum sessionFlags {
    Session_MVP = 1,
    Session_HonkMaster = 2,
    Session_PresentInfinale = 4
}

// stats used for both stats_games and stats_users
enum struct CommonPlayerStats {
    int points;
    int seconds_alive; // all time* calculated between checkpoints
    int seconds_idle;
    int seconds_dead;
    int kills_common;
    int kills_melee;
    int damage_taken;
    int damage_taken_count;
    int damage_taken_friendly;
    int damage_taken_friendly_count;
    float damage_taken_fall;
    int damage_dealt;
    int damage_dealt_friendly;
    int damage_dealt_friendly_count;
    int damage_dealt_fire;
    int used_kit_self;
    int used_kit_other;
    int used_defib;
    int used_molotov;
    int used_pipebomb;
    int used_bile;
    int used_pills;
    int used_adrenaline;
    int times_revived_other;
    int times_incapped;
    int times_hanging;
    int deaths;
    int kills_boomer;
    int kills_smoker;
    int kills_jockey;
    int kills_hunter;
    int kills_spitter;
    int kills_charger;
    int kills_tank;
    int kills_witch;
    int kills_fire;
    int kills_pipebomb;
    int kills_minigun;
    int honks;
    int witches_crowned;
    int smokers_selfcleared;
    int rocks_hitby;
    int rocks_dodged;
    int hunters_deadstopped;
    int times_pinned;
    int times_cleared_pinned;
    int times_boomed_teammates;
    int times_boomed;
    int damage_dealt_tank;
    int damage_dealt_witch;
    int caralarms_activated;
    int times_shove;
    int times_jumped;
    int bullets_fired;
}

// stats used for stats_users only
// gets flushed
enum struct UserPlayerStats {
    int pickups_molotov;
    int pickups_bile;
    int pickups_pipebomb;
    int pickups_pills;
    int pickups_adrenaline;

    int kills_tank_solo;
    int kills_tank_melee;
    int kills_common_headshots;
    int door_opens;
    int finales_won;
    int kills_friendly;
    int used_ammopack_fire;
    int used_ammopack_explosive;

    int witches_crowned_angry;
    int times_boomed_self;
    int forgot_kit_count;
    int kits_slapped;

    // don't want these in stats_games because it's too much
    int times_incapped_fire;
    int times_incapped_acid; 
    int times_incapped_zombie;
    int times_incapped_special;
    int times_incapped_tank;
    int times_incapped_witch;

}

enum struct SessionPlayerStats {
	float longest_shot_distance;
}

// This is saved until end of game when player disconnects
enum struct SessionData {
    // do not manually edit this
    // 
    // increment user.common and then call MergeUserToSession()
    CommonPlayerStats common;
    // stats_sessions specific columns
    SessionPlayerStats session;

    int flags;
    char steamid[32];
    int lastSurvivorType;
    int join_time;
    int userid;
}

// This holds data that only lasts as long as player
enum struct UserData {
    CommonPlayerStats common;
    // stats_user specific columns
    UserPlayerStats user;

    char steamid[32];
}

enum TimeType {
    Time_Alive,
    Time_Idle,
    Time_Dead
}

// Stores PlayerGame for disconnected users
AnyMap g_sessionDataStorage;

enum struct PlayerDataContainer {
	SessionData session;
    UserData user;

    int userid;
    int timeStart; // used for seconds_* columns
    TimeType timeType;

    DistanceCalculator distance;
	TimeCalculator timeInFire;
	TimeCalculator timeInAcid;

    // Pulled from database, only used for /stats
	int connections;
	int firstJoinedTime; // When user first joined server (first recorded statistics)
	int lastJoinedTime; // When the user last connected
	int joinedGameTime; // When user joined game session (not connected)

	ActiveWeaponData wpn;
    ArrayList pointsQueue;
	ArrayList pendingHeatmaps;

    void Init() {
        this.wpn.Init();
		this.pointsQueue = new ArrayList(4); // [ type, amount, time, multiplier ]
		this.pendingHeatmaps = new ArrayList(sizeof(PendingHeatMapData));
    }

    void Load(int client, const char[] steamid) {
        this.userid = GetClientUserId(client);
        this.session.userid = this.userid;
        LogTrace("Lood %d %d", this.userid, client);
        this.LoadSession(); //writes over this.session
        strcopy(this.session.steamid, sizeof(this.session.steamid), steamid);
        strcopy(this.user.steamid, sizeof(this.user.steamid), steamid);
        if(this.session.join_time == 0) this.session.join_time = 0; // keep original join time

        this.Calculate(); // we call this to initalize time stuff
    }

    void CalculateTime(int client) {
        // calculate time since for marker
        if(this.timeStart > 0) {
            int time = GetTime() - this.timeStart;
            switch(this.timeType) {
                case Time_Alive: this.user.common.seconds_alive += time;
                case Time_Idle: this.user.common.seconds_idle += time;
                case Time_Dead: this.user.common.seconds_dead += time;
            }
        }

        // start new marker with it's type
        this.timeStart = GetTime();
        if(IsPlayerAlive(client)) {
            this.timeType = L4D_IsPlayerIdle(client) ? Time_Idle : Time_Alive;
        } else {
            this.timeType = Time_Dead;
        }
    }

    void LoadSession() {
        g_sessionDataStorage.GetArray(this.userid, this.session, sizeof(this.session));
    }

    // Calculates any values
    void Calculate() {
        int client = GetClientOfUserId(this.userid);
        LogTrace("Calculate %d %d", this.userid, client);
        if(client > 0 ){ 
		    this.session.lastSurvivorType = GetEntProp(client, Prop_Send, "m_survivorCharacter");
            this.CalculateTime(client);
            this.MeasureDistance(client);
        }
    }


    // Calculates values and saves
    void SaveSession() {
        this.Calculate();

        g_sessionDataStorage.SetArray(this.userid, this.session, sizeof(this.session));
    }

    // Clears user data
    void ClearUser() {
        UserData newUser;
        this.user = newUser;
    }

    // Clears user + session data + any other data
    void Reset() {
        this.ClearUser();
        SessionData newSess;
        this.session = newSess;
        this.userid = 0;
    }

    void RecordHeatMap(HeatMapType type, const float pos[3]) {
		if(!hHeatmapActive.BoolValue || this.pendingHeatmaps == null) return;
		PendingHeatMapData hmd;
		hmd.timestamp = GetTime();
		hmd.type = type;
		int intPos[3];
		intPos[0] = RoundFloat(pos[0] / float(HEATMAP_POINT_SIZE)) * HEATMAP_POINT_SIZE;
		intPos[1] = RoundFloat(pos[1] / float(HEATMAP_POINT_SIZE)) * HEATMAP_POINT_SIZE;
		intPos[2] = RoundFloat(pos[2] / float(HEATMAP_POINT_SIZE)) * HEATMAP_POINT_SIZE;
		hmd.pos = intPos;
		this.pendingHeatmaps.PushArray(hmd);
	}

    /// Returns the index of the latest queued entry of a point record, or -1
	int getPointRecord(PointRecordType type) {
		for(int i = this.pointsQueue.Length - 1; i >= 0; i--) {
			int pType = this.pointsQueue.Get(i, 0);
			if(pType == view_as<int>(type)) {
				return i;
			}
		}
		return -1;
	}

    	/**	
	 * Records a point change.
	 * @param type the point type being recorded
	 * @param points the amount of points to add/remove. if 0, the default value from PointValueDefaults used
	 * @param allowMerging should recording be merged into previous record if there is one
	 * @param mergeWindow maximum age of previous record to merge to
	 */
	void RecordPoint(PointRecordType type, int points = 0, bool allowMerging = false, int mergeWindow = 0) {
		// Use default if point is using default value
		if(points == 0) points = PointValueDefaults[type];

		this.user.common.points += points;
		if(allowMerging) {
			// Merge point record (if there is a previous record) by increasing 'multiplier' field by one
			int prevIndex = this.getPointRecord(type);
			if(prevIndex != -1) {
				int mult = this.pointsQueue.Get(prevIndex, 3);
				// Multiplier is unsigned tiny int, don't merge if it's over capacity
				if(mult <= 255) {
					int timestamp = GetTime();
					int prevTimestamp = this.pointsQueue.Get(prevIndex, 2);
					// If merge window is unlimited, or record in timespan then merge
					if(mergeWindow == 0 || timestamp - prevTimestamp <= mergeWindow) {
						this.pointsQueue.Set(prevIndex, timestamp, 2); // update timestamp
						this.pointsQueue.Set(prevIndex, mult + 1, 3); // increment multiplier
						return;
					}
				}

				// It's unlikely that there is a record even earlier in list that will younger than this record, so we don't try to find another one
			}
		}

		// Add new record entry to queue
		int index = this.pointsQueue.Push(type);
		this.pointsQueue.Set(index, points, 1);
		this.pointsQueue.Set(index, GetTime(), 2);
		this.pointsQueue.Set(index, 1, 3);
	}

    void MeasureDistance(int client) {
		// TODO: add guards (no noclip, must touch ground, survivor)
		// int timeDiff = GetTime() - this.distance.recordTime;
		if(!(GetEntityFlags(client) & FL_ONGROUND )) { return; }
		if(!IsPlayerAlive(client) || GetClientTeam(client) < 2) return;

		float pos[3];
		GetClientAbsOrigin(client, pos);
		// Convert hammer units to meters to get _slightly_ smaller numbers
		float distance = GetVectorDistance(this.distance.lastPos, pos, false) / 2.54;
		this.distance.accumulation += distance;
		this.distance.lastPos = pos;
		this.distance.recordTime = GetTime();
	}
}

// This is moved out of enum struct because it's ugly and messy
// 
// MAKE SURE TO UPDATE THIS FOR NEW COLUMNS
void MergeUserToSession(PlayerDataContainer data) {
    LogDebug("MergeUserToSession userid=%d", data.userid);

    data.session.common.points += data.user.common.points;
    data.session.common.seconds_alive += data.user.common.seconds_alive;
    data.session.common.seconds_idle += data.user.common.seconds_idle;
    data.session.common.seconds_dead += data.user.common.seconds_dead;
    data.session.common.kills_common += data.user.common.kills_common;
    data.session.common.kills_melee += data.user.common.kills_melee;
    data.session.common.damage_taken += data.user.common.damage_taken;
    data.session.common.damage_taken_count += data.user.common.damage_taken_count;
    data.session.common.damage_taken_friendly += data.user.common.damage_taken_friendly;
    data.session.common.damage_taken_friendly_count += data.user.common.damage_taken_friendly_count;
    data.session.common.damage_dealt += data.user.common.damage_dealt;
    data.session.common.damage_dealt_friendly += data.user.common.damage_dealt_friendly;
    data.session.common.damage_dealt_friendly_count += data.user.common.damage_dealt_friendly_count;
    data.session.common.damage_dealt_fire += data.user.common.damage_dealt_fire;
    data.session.common.used_kit_self += data.user.common.used_kit_self;
    data.session.common.used_kit_other += data.user.common.used_kit_other;
    data.session.common.used_defib += data.user.common.used_defib;
    data.session.common.used_molotov += data.user.common.used_molotov;
    data.session.common.used_pipebomb += data.user.common.used_pipebomb;
    data.session.common.used_bile += data.user.common.used_bile;
    data.session.common.used_pills += data.user.common.used_pills;
    data.session.common.used_adrenaline += data.user.common.used_adrenaline;
    data.session.common.times_revived_other += data.user.common.times_revived_other;
    data.session.common.times_incapped += data.user.common.times_incapped;
    data.session.common.times_hanging += data.user.common.times_hanging;
    data.session.common.deaths += data.user.common.deaths;
    data.session.common.kills_boomer += data.user.common.kills_boomer;
    data.session.common.kills_smoker += data.user.common.kills_smoker;
    data.session.common.kills_jockey += data.user.common.kills_jockey;
    data.session.common.kills_hunter += data.user.common.kills_hunter;
    data.session.common.kills_spitter += data.user.common.kills_spitter;
    data.session.common.kills_charger += data.user.common.kills_charger;
    data.session.common.kills_tank += data.user.common.kills_tank;
    data.session.common.kills_witch += data.user.common.kills_witch;
    data.session.common.kills_fire += data.user.common.kills_fire;
    data.session.common.kills_pipebomb += data.user.common.kills_pipebomb;
    data.session.common.kills_minigun += data.user.common.kills_minigun;
    data.session.common.honks += data.user.common.honks;
    data.session.common.witches_crowned += data.user.common.witches_crowned;
    data.session.common.smokers_selfcleared += data.user.common.smokers_selfcleared;
    data.session.common.rocks_hitby += data.user.common.rocks_hitby;
    data.session.common.rocks_dodged += data.user.common.rocks_dodged;
    data.session.common.hunters_deadstopped += data.user.common.hunters_deadstopped;
    data.session.common.times_pinned += data.user.common.times_pinned;
    data.session.common.times_cleared_pinned += data.user.common.times_cleared_pinned;
    data.session.common.times_boomed_teammates += data.user.common.times_boomed_teammates;
    data.session.common.times_boomed += data.user.common.times_boomed;
    data.session.common.damage_dealt_tank += data.user.common.damage_dealt_tank;
    data.session.common.damage_dealt_witch += data.user.common.damage_dealt_witch;
    data.session.common.caralarms_activated += data.user.common.caralarms_activated;
    data.session.common.damage_taken_fall += data.user.common.damage_taken_fall;
    data.session.common.times_shove += data.user.common.times_shove;
    data.session.common.times_jumped += data.user.common.times_jumped;
    data.session.common.bullets_fired += data.user.common.bullets_fired;
}

//Record a special kill to local variable
void IncrementSpecialKill(UserData user, int special) {
	switch(special) {
		case 1: user.common.kills_smoker++;
		case 2: user.common.kills_boomer++;
		case 3: user.common.kills_hunter++;
		case 4: user.common.kills_spitter++;
		case 5: user.common.kills_jockey++;
		case 6: user.common.kills_charger++;
	}
}