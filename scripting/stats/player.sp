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
	DistanceCalculator distance;
	TimeCalculator timeInFire;
	TimeCalculator timeInAcid;

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

	// Pulled from database:
	int connections;
	int firstJoinedTime; // When user first joined server (first recorded statistics)
	int lastJoinedTime; // When the user last connected
	int joinedGameTime; // When user joined game session (not connected)

	ActiveWeaponData wpn;

	int idleStartTime;
	int totalIdleTime;

	ArrayList pointsQueue;
	ArrayList pendingHeatmaps;

	void Init() {
		this.wpn.Init();
		this.pointsQueue = new ArrayList(4); // [ type, amount, time, multiplier ]
		this.pendingHeatmaps = new ArrayList(sizeof(PendingHeatMapData));
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

	void ResetFull() {
		this.steamid[0] = '\0';
		this.points = 0;
		this.idleStartTime = 0;
		this.totalIdleTime = 0;
		if(this.pointsQueue != null)
			this.pointsQueue.Clear();
		if(this.pendingHeatmaps != null) {
			this.pendingHeatmaps.Clear();
		}
		this.wpn.Reset(true);
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

		this.points += points;
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
		float distance = GetVectorDistance(this.distance.lastPos, pos) / 2.54;
		this.distance.accumulation += distance;
		this.distance.lastPos = pos;
		this.distance.recordTime = GetTime();
	}
}